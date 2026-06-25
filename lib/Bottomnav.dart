// lib/widgets/bottom_nav.dart
import 'package:flutter/material.dart';

import 'Providers/NavigationProvider.dart';
import 'core/Theme.dart';

class GarageBottomNav extends StatelessWidget {
  final AppScreen current;
  final ValueChanged<AppScreen> onTap;

  const GarageBottomNav({super.key, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (AppScreen.dashboard, Icons.dashboard_rounded, 'Dashboard'),
      (AppScreen.customers, Icons.people_rounded, 'Customers'),
      (AppScreen.jobs, Icons.assignment_rounded, 'Jobs'),
      (AppScreen.inventory, Icons.inventory_2_rounded, 'Inventory'),
      (AppScreen.profile, Icons.person_rounded, 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: kCard,
        border: const Border(top: BorderSide(color: kBorder, width: 0.8)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: tabs.map((tab) {
              final (screen, icon, label) = tab;
              final isActive = current == screen;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(screen),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 22,
                        color: isActive ? kPrimary : kMutedForeground,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
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
            }).toList(),
          ),
        ),
      ),
    );
  }
}