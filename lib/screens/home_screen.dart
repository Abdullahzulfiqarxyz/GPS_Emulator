// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gps_provider.dart';
import 'map_screen.dart';
import 'route_screen.dart';
import 'saved_screen.dart';
import 'settings_screen.dart';
import '../widgets/status_bar_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MapScreen(),
    RouteScreen(),
    SavedScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const StatusBarWidget(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      child: NavigationBar(
        backgroundColor: Colors.transparent,
        indicatorColor: theme.colorScheme.primary.withOpacity(0.15),
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          _navItem(Icons.map_rounded, Icons.map_outlined, 'Map'),
          _navItem(Icons.route_rounded, Icons.route_outlined, 'Route'),
          _navItem(Icons.bookmark_rounded, Icons.bookmark_outline, 'Saved'),
          _navItem(Icons.settings_rounded, Icons.settings_outlined, 'Settings'),
        ],
      ),
    );
  }

  NavigationDestination _navItem(IconData active, IconData inactive, String label) {
    final isSelected = _screens.indexOf(_screens[_currentIndex]) == _screens.indexOf(
      [const MapScreen(), const RouteScreen(), const SavedScreen(), const SettingsScreen()]
          .firstWhere((s) => s.runtimeType == _screens[_currentIndex].runtimeType, orElse: () => _screens[0]),
    );

    return NavigationDestination(
      icon: Icon(inactive, color: Colors.white38),
      selectedIcon: Icon(active, color: Theme.of(context).colorScheme.primary),
      label: label,
    );
  }
}
