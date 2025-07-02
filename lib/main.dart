import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/forms_screen.dart';
import 'widgets/lenient_app_bar.dart';
import 'widgets/lenient_nav_bar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/form_entry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(FormStatusAdapter());
  Hive.registerAdapter(FormEntryAdapter());
  // await Hive.deleteBoxFromDisk('forms');
  await Hive.openBox<FormEntry>('forms');
  runApp(const LenientTechnologiesApp());
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
