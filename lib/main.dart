import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/forms_screen.dart';
import 'widgets/lenient_app_bar.dart';
import 'widgets/lenient_nav_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants/supabase_keys.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'utils/permission_manager.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
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
    return const LenientTechnologiesApp();
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

  final List<Widget> _screens = const [
    HomeScreen(),
    FormsScreen(),
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
