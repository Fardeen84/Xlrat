// lib/screens/main_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    _NavTab('/dashboard', Icons.dashboard_rounded, 'Dashboard'),
    _NavTab('/customers', Icons.people_rounded, 'Customers'),
    _NavTab('/jobs', Icons.assignment_rounded, 'Jobs'),
    _NavTab('/inventory', Icons.inventory_2_rounded, 'Inventory'),
    _NavTab('/profile', Icons.person_rounded, 'Profile'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: _GarageBottomNav(
        currentIndex: idx,
        onTap: (i) => context.go(_tabs[i].path),
      ),
    );
  }
}

class _NavTab {
  final String path;
  final IconData icon;
  final String label;
  const _NavTab(this.path, this.icon, this.label);
}

class _GarageBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _GarageBottomNav({required this.currentIndex, required this.onTap});

  static const _tabs = [
    _NavTab('/dashboard', Icons.dashboard_rounded, 'Dashboard'),
    _NavTab('/customers', Icons.people_rounded, 'Customers'),
    _NavTab('/jobs', Icons.assignment_rounded, 'Jobs'),
    _NavTab('/inventory', Icons.inventory_2_rounded, 'Inventory'),
    _NavTab('/profile', Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        border: const Border(top: BorderSide(color: kBorder, width: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final tab = _tabs[i];
              final isActive = currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tab.icon,
                        size: 22,
                        color: isActive ? kPrimary : kMutedForeground,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isActive ? kPrimary : kMutedForeground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 3,
                        width: isActive ? 24 : 0,
                        decoration: BoxDecoration(
                          color: kPrimary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}