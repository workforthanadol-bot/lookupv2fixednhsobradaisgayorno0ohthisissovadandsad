import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/pdf_create_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/id_checker_screen.dart';
import 'screens/nhso_search_screen.dart';
import 'screens/combined_search_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Force portrait orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppTheme.primaryColor,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ProviderScope(child: ScoreLookupApp()));
}

class ScoreLookupApp extends StatelessWidget {
  const ScoreLookupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ระบบค้นหาข้อมูลผู้สมัครสอบ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _navItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'หน้าหลัก',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.search_outlined),
      activeIcon: Icon(Icons.search),
      label: 'ค้นหา',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.join_full_outlined),
      activeIcon: Icon(Icons.join_full),
      label: 'ค้นรวม',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.picture_as_pdf_outlined),
      activeIcon: Icon(Icons.picture_as_pdf),
      label: 'สร้าง PDF',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.credit_card_outlined),
      activeIcon: Icon(Icons.credit_card),
      label: 'ตรวจบัตร/โทร',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.local_hospital_outlined),
      activeIcon: Icon(Icons.local_hospital),
      label: 'สปสช',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings_outlined),
      activeIcon: Icon(Icons.settings),
      label: 'ตั้งค่า',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            onSearchTap: () => setState(() => _currentIndex = 1),
            onPdfTap: () => setState(() => _currentIndex = 3),
          ),
          const SearchScreen(),
          const CombinedSearchScreen(),
          const PdfCreateScreen(),
          const IdCheckerScreen(),
          const NhsoSearchScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: _navItems,
        ),
      ),
    );
  }
}
