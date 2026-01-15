import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';
import '../providers/localization_provider.dart';

import 'auto_run_screen.dart';
import 'control_screen.dart';
import 'dashboard_screen.dart';

import 'settings_screen.dart';
import 'teaching_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ControlScreen(),
    const TeachingScreen(),
    const AutoRunScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final localization = context.watch<LocalizationProvider>();
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0D47A1),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.outfit(),
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: localization.t('dashboard'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.gamepad_rounded),
              label: localization.t('control'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.model_training),
              label: localization.t('teaching'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.autorenew),
              label: localization.t('autoRun'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: localization.t('settings'),
            ),
          ],
        ),
      ),
    );
  }
}
