import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/forms_screen.dart';
import 'screens/change_password_screen.dart';
import 'widgets/lenient_app_bar.dart';
import 'widgets/lenient_nav_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'utils/permission_manager.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'config/build_flags.dart';
import 'services/database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await clearAppCache();
  runApp(const PermissionGateApp());
}

class PermissionGateApp extends StatelessWidget {
  const PermissionGateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lenient Technologies',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const PermissionGate(),
    );
  }
}

class PermissionGate extends StatefulWidget {
  const PermissionGate({super.key});
  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  bool _permissionsGranted = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _loading = true);
    final granted = await PermissionManager.ensureAllPermissions(context);
    setState(() {
      _permissionsGranted = granted;
      _loading = false;
    });
    if (granted) {
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL']!,
        anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_permissionsGranted) {
      // Optionally show a minimal error or exit
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            'Permissions are required to use this app.',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 18, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return const AppStartGuard(child: LenientTechnologiesApp());
  }
}

// --- AppStartGuard for password version enforcement ---
class AppStartGuard extends StatefulWidget {
  final Widget child;
  const AppStartGuard({required this.child, Key? key}) : super(key: key);

  @override
  State<AppStartGuard> createState() => _AppStartGuardState();
}

class _AppStartGuardState extends State<AppStartGuard> {
  bool? _authenticated;

  @override
  void initState() {
    super.initState();
    _checkPasswordVersion();
  }

  Future<void> _checkPasswordVersion() async {
    try {
      // Check if local password/version exists
      final local = await getLocalPasswordAndVersion();
      if (local == null) {
        // No local password, require Supabase validation
        setState(() {
          _authenticated = false;
        });
        return;
      }
      final localVersion = int.tryParse(local['password_version'] ?? '');
      final supaVersion = await getSupabasePasswordVersion();
      final prefs = await SharedPreferences.getInstance();
      final storedVersion = prefs.getInt('stored_password_version');
      if (supaVersion != null && localVersion != null && localVersion == supaVersion && storedVersion == localVersion) {
        setState(() {
          _authenticated = true;
        });
      } else {
        setState(() {
          _authenticated = false;
        });
      }
    } catch (e) {
      setState(() {
        _authenticated = false;
      });
    }
  }

  void _onAuthenticated() async {
    final local = await getLocalPasswordAndVersion();
    final currentVersion = int.tryParse(local?['password_version'] ?? '');
    if (currentVersion != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('stored_password_version', currentVersion);
    }
    setState(() {
      _authenticated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_authenticated == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_authenticated == true) {
      return widget.child;
    }
    return AppLockScreen(onAuthenticated: _onAuthenticated);
  }
}

class AppLockScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;
  const AppLockScreen({required this.onAuthenticated, Key? key}) : super(key: key);

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _controller = TextEditingController();
  String? _error;

  Future<bool> validatePassword(String input) async {
    final local = await getLocalPasswordAndVersion();
    if (local == null) {
      // No local password, validate against Supabase
      final isValid = await validatePasswordWithSupabase(input);
      if (isValid) {
        // If correct, store hash and version locally
        final supa = await fetchPasswordFromSupabase();
        if (supa != null) {
          await storePasswordLocally(supa['password_hash'], supa['password_version']);
        }
        return true;
      } else {
        setState(() {
          _error = "Incorrect password (Supabase check)";
        });
        return false;
      }
    }
    // Local password exists, check version sync
    final localVersion = int.tryParse(local['password_version'] ?? '');
    final supaVersion = await getSupabasePasswordVersion();
    if (supaVersion != null && localVersion != null && localVersion != supaVersion) {
      // Version mismatch, require Supabase validation
      final isValid = await validatePasswordWithSupabase(input);
      if (isValid) {
        final supa = await fetchPasswordFromSupabase();
        if (supa != null) {
          await storePasswordLocally(supa['password_hash'], supa['password_version']);
        }
        return true;
      } else {
        setState(() {
          _error = "Incorrect password (Supabase check)";
        });
        return false;
      }
    }
    // Local password and version are valid, check locally
    final storedHash = local['password_hash'];
    final inputHash = sha256.convert(utf8.encode(input)).toString();
    if (inputHash == storedHash) {
      return true;
    } else {
      setState(() {
        _error = "Incorrect password";
      });
      return false;
    }
  }

  void _submit() async {
    bool isValid = await validatePassword(_controller.text);
    if (isValid) {
      setState(() => _error = null);
      widget.onAuthenticated();
    } else {
      setState(() => _error = "Incorrect password");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "App Locked",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: Color(0xFF22B14C),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Enter App Password",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Color(0xFF222222),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  obscureText: true,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 18),
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: const TextStyle(fontFamily: 'Poppins'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onSubmitted: (_) => _submit(),
                  textInputAction: TextInputAction.done,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22B14C),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 18),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _submit,
                    child: const Text("Unlock"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PermissionDialog extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onSettings;
  final VoidCallback onExit;
  const PermissionDialog({
    super.key,
    required this.onRetry,
    required this.onSettings,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      title: Text(
        'Permissions Required',
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          color: Color(0xFF22B14C), // Your green
        ),
      ),
      content: const Text(
        'This app needs storage and camera permissions to function properly.',
        style: TextStyle(
          fontFamily: 'Poppins',
          color: Color(0xFF222222),
        ),
      ),
      actions: [
        TextButton(
          onPressed: onSettings,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF22B14C),
            textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
          ),
          child: const Text('Open Settings'),
        ),
        TextButton(
          onPressed: onRetry,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF22B14C),
            textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
          ),
          child: const Text('Retry'),
        ),
        TextButton(
          onPressed: onExit,
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
            textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
          ),
          child: const Text('Exit'),
        ),
      ],
    );
  }
}

class PermissionManager {
  static Future<bool> ensureAllPermissions(BuildContext context) async {
    while (true) {
      final storage = await Permission.storage.request();
      final manageStorage = await Permission.manageExternalStorage.request();
      final camera = await Permission.camera.request();
      if ((storage.isGranted || manageStorage.isGranted) && camera.isGranted) {
        return true;
      }
      final result = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PermissionDialog(
          onRetry: () => Navigator.of(context).pop('retry'),
          onSettings: () async {
            await openAppSettings();
            Navigator.of(context).pop('settings');
          },
          onExit: () => Navigator.of(context).pop('exit'),
        ),
      );
      if (result == 'retry') {
        continue;
      }
      return false;
    }
  }
  static Future<bool> ensureCameraAndGalleryPermissions(BuildContext context) async {
    final storage = await Permission.storage.request();
    final manageStorage = await Permission.manageExternalStorage.request();
    final camera = await Permission.camera.request();
    if ((storage.isGranted || manageStorage.isGranted) && camera.isGranted) {
      return true;
    }
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PermissionDialog(
        onRetry: () => Navigator.of(context).pop('retry'),
        onSettings: () async {
          await openAppSettings();
          Navigator.of(context).pop('settings');
        },
        onExit: () => Navigator.of(context).pop('exit'),
      ),
    );
    if (result == 'retry') {
      return await ensureCameraAndGalleryPermissions(context);
    }
    return false;
  }
  static Future<bool> ensureStoragePermission(BuildContext context) async {
    final storage = await Permission.storage.request();
    final manageStorage = await Permission.manageExternalStorage.request();
    if (storage.isGranted || manageStorage.isGranted) {
      return true;
    }
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PermissionDialog(
        onRetry: () => Navigator.of(context).pop('retry'),
        onSettings: () async {
          await openAppSettings();
          Navigator.of(context).pop('settings');
        },
        onExit: () => Navigator.of(context).pop('exit'),
      ),
    );
    if (result == 'retry') {
      return await ensureStoragePermission(context);
    }
    return false;
  }
}

class LenientTechnologiesApp extends StatelessWidget {
  const LenientTechnologiesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lenient Technologies',
      theme: AppTheme.theme,
      home: const MainScaffold(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

Future<void> clearAppCache() async {
  try {
    final cacheDir = await getTemporaryDirectory();
    if (cacheDir.existsSync()) {
      cacheDir.deleteSync(recursive: true);
    }
  } catch (e) {
    debugPrint('Failed to clear cache: $e');
  }
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  List<Widget> get _screens => [
        const HomeScreen(),
        const FormsScreen(),
        if (isAdminBuild) const ChangePasswordScreen(),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LenientAppBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: LenientNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        isAdmin: isAdminBuild,
      ),
    );
  }
}



class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('$title Screen', style: Theme.of(context).textTheme.headlineMedium));
  }
}
