// lib/screens/main_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/NavigationProvider.dart';
import '../providers/notificationsProvider.dart';
import '../providers/billing_providers.dart';
import '../core/theme.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const _sidebarTabs = [
    _NavTab(
      '/dashboard',
      Icons.dashboard_rounded,
      'Dashboard',
      AppScreen.dashboard,
    ),
    _NavTab(
      '/customers',
      Icons.people_rounded,
      'Customers',
      AppScreen.customers,
    ),
    _NavTab('/jobs', Icons.assignment_rounded, 'Jobs', AppScreen.jobs),
    _NavTab(
      '/inventory',
      Icons.inventory_2_rounded,
      'Inventory',
      AppScreen.inventory,
    ),
    _NavTab(
      '/secondhand-inventory',
      Icons.recycling_rounded,
      'Second Hand',
      AppScreen.secondHandInventory,
    ),
    _NavTab('/reports', Icons.bar_chart_rounded, 'Reports', AppScreen.reports),
    _NavTab('/profile', Icons.person_rounded, 'Profile', AppScreen.profile),
  ];

  static const _mobileTabs = [
    _NavTab(
      '/dashboard',
      Icons.dashboard_rounded,
      'Dashboard',
      AppScreen.dashboard,
    ),
    _NavTab(
      '/customers',
      Icons.people_rounded,
      'Customers',
      AppScreen.customers,
    ),
    _NavTab('/jobs', Icons.assignment_rounded, 'Jobs', AppScreen.jobs),
    _NavTab(
      '/inventory',
      Icons.inventory_2_rounded,
      'Inventory',
      AppScreen.inventory,
    ),
    _NavTab(
      '/secondhand-inventory',
      Icons.recycling_rounded,
      'Second Hand',
      AppScreen.secondHandInventory,
    ),
    _NavTab('/profile', Icons.person_rounded, 'Profile', AppScreen.profile),
  ];

  int _currentIndex(String location, List<_NavTab> tabs) {
    for (int i = 0; i < tabs.length; i++) {
      if (location.startsWith(tabs[i].path)) return i;
    }
    return 0;
  }

  AppScreen _locationToScreen(String location) {
    if (location == '/') return AppScreen.splash;
    if (location == '/login') return AppScreen.login;
    if (location.startsWith('/dashboard')) return AppScreen.dashboard;
    if (location.startsWith('/customer-detail'))
      return AppScreen.customerDetail;
    if (location.startsWith('/customers')) return AppScreen.customers;
    if (location.startsWith('/job-detail')) return AppScreen.jobDetail;
    if (location.startsWith('/new-job')) return AppScreen.newJob;
    if (location.startsWith('/jobs')) return AppScreen.jobs;
    if (location.startsWith('/inventory')) return AppScreen.inventory;
    if (location.startsWith('/secondhand-inventory')) return AppScreen.secondHandInventory;
    if (location.startsWith('/billing')) return AppScreen.billing;
    if (location.startsWith('/InvoiceHistory')) return AppScreen.reports;
    if (location.startsWith('/invoice')) return AppScreen.invoice;
    if (location.startsWith('/reports')) return AppScreen.reports;
    if (location.startsWith('/notifications')) return AppScreen.notifications;
    if (location.startsWith('/profile')) return AppScreen.profile;
    return AppScreen.dashboard;
  }

  bool _isMainTabRoute(String location) {
    return location == '/dashboard' ||
        location == '/customers' ||
        location == '/jobs' ||
        location == '/inventory' ||
        location == '/secondhand-inventory' ||
        location == '/profile';
  }

  String _getPageTitle(AppScreen screen) {
    switch (screen) {
      case AppScreen.dashboard:
        return 'Dashboard';
      case AppScreen.customers:
        return 'Customers';
      case AppScreen.customerDetail:
        return 'Customer Details';
      case AppScreen.jobs:
        return 'Jobs';
      case AppScreen.jobDetail:
        return 'Job Details';
      case AppScreen.newJob:
        return 'Create Job Card';
      case AppScreen.inventory:
        return 'Inventory';
      case AppScreen.secondHandInventory:
        return 'Second Hand Inventory';
      case AppScreen.billing:
        return 'Billing / New Invoice';
      case AppScreen.invoice:
        return 'Invoice';
      case AppScreen.reports:
        return 'Reports';
      case AppScreen.notifications:
        return 'Notifications';
      case AppScreen.profile:
        return 'Profile / Settings';
      default:
        return 'XLRat';
    }
  }

  Future<bool?> _showExitConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCard,
        title: Text(
          'Exit App',
          style: TextStyle(fontWeight: FontWeight.w800, color: kForeground),
        ),
        content: Text(
          'Are you sure you want to exit?',
          style: TextStyle(color: kForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: kMutedForeground)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: kPrimaryDark,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final screen = _locationToScreen(location);
    final themeMode = ref.watch(themeModeProvider);

    // Sync GoRouter location with riverpod state provider post frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(currentScreenProvider) != screen) {
        ref.read(currentScreenProvider.notifier).state = screen;
      }
    });

    final unreadNotifications = ref.watch(unreadCountProvider);

    return PopScope(
      canPop: !_isMainTabRoute(location),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _showExitConfirmationDialog(context);
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isPC = constraints.maxWidth > 1100;
              final isTablet =
                  constraints.maxWidth >= 768 && constraints.maxWidth <= 1100;

              if (isPC || isTablet) {
                final sidebarWidth = isPC ? 240.0 : 64.0;
                final activeIndex = _currentIndex(location, _sidebarTabs);

                return Row(
                  children: [
                    // ── Sidebar ──

                    Container(

                      width: sidebarWidth,
                      height: double.infinity,
                      color: kPrimary,
                      child: Column(
                        children: [
                          // Header
                          Container(
                              height: 80,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.white10,
                                    width: 0.8,
                                  ),
                                ),
                              ),
                              child: isPC
                                  ? Column(
                                children: [
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children:  [
                                      SizedBox(width: 10),
                                      ClipOval(
                                        child: Image.asset(
                                          "assets/images/l.png",
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          "Asian Fabrication\n& Engineers",
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              )
                                  : ClipOval(
                                child: Image.asset(
                                  "assets/images/afslogo.jpeg",
                                  width: 30,
                                  height: 30,
                                  fit: BoxFit.cover,
                                ),
                              )
                          ),
                          const SizedBox(height: 16),
                          // Navigation List
                          Expanded(
                            child: ListView.builder(
                              itemCount: _sidebarTabs.length,
                              itemBuilder: (context, i) {
                                final tab = _sidebarTabs[i];
                                final isActive = activeIndex == i;

                                if (isPC) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    child: InkWell(
                                      onTap: () => context.go(tab.path),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? Colors.white.withOpacity(0.15)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              tab.icon,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              tab.label,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  return Tooltip(
                                    message: tab.label,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: InkWell(
                                        onTap: () => context.go(tab.path),
                                        child: Container(
                                          height: 48,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            border: Border(
                                              left: BorderSide(
                                                color: isActive
                                                    ? Colors.white
                                                    : Colors.transparent,
                                                width: 4,
                                              ),
                                            ),
                                          ),
                                          child: Icon(
                                            tab.icon,
                                            color: isActive
                                                ? Colors.white
                                                : Colors.white70,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          // Footer info
                          if (isPC)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.white10,
                                    width: 0.8,
                                  ),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.white24,
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Asian Fabrication & Engineers',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Owner / Admin',
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // ── Content Area ──
                    Expanded(
                      child: Column(
                        children: [
                          // Top Bar
                          Container(
                            height: 60,
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: kCard,
                              border: Border(
                                bottom: BorderSide(color: kBorder, width: 0.8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _getPageTitle(screen),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: kForeground,
                                  ),
                                ),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => context.go('/billing'),
                                      icon: const Icon(
                                        Icons.add_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      label: const Text(
                                        'New Invoice',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        backgroundColor: kPrimary,
                                      ),
                                    ),
                                    // const SizedBox(width: 16),
                                    // IconButton(
                                    //   icon: Icon(
                                    //     themeMode == ThemeMode.dark
                                    //         ? Icons.light_mode_rounded
                                    //         : Icons.dark_mode_rounded,
                                    //     color: kForeground,
                                    //   ),
                                    //   onPressed: () {
                                    //     ref
                                    //         .read(themeModeProvider.notifier)
                                    //         .toggleTheme();
                                    //   },
                                    //   tooltip: 'Toggle theme mode',
                                    // ),
                                    const SizedBox(width: 8),
                                    Stack(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.notifications_rounded,
                                            color: kForeground,
                                          ),
                                          onPressed: () =>
                                              context.go('/notifications'),
                                        ),
                                        if (unreadNotifications > 0)
                                          Positioned(
                                            top: 6,
                                            right: 6,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: kRed,
                                                shape: BoxShape.circle,
                                              ),
                                              constraints: const BoxConstraints(
                                                minWidth: 16,
                                                minHeight: 16,
                                              ),
                                              child: Text(
                                                '$unreadNotifications',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => context.go('/profile'),
                                      child: const CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Color(0xFFE8F0FE),
                                        child: Icon(
                                          Icons.person_rounded,
                                          color: kPrimary,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // screen Child
                          Expanded(child: widget.child),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                // Mobile Mode
                final idx = _currentIndex(location, _mobileTabs);
                final showBottomNav = _isMainTabRoute(location);

                return Scaffold(
                  body: widget.child,
                  bottomNavigationBar: showBottomNav
                      ? _GarageBottomNav(
                    currentIndex: idx,
                    onTap: (i) => context.go(_mobileTabs[i].path),
                  )
                      : null,
                );
              }
            },
          ),
          const _ConnectionErrorOverlay(),
        ],
      ),
    ),
    );
  }
}

class _ConnectionErrorOverlay extends ConsumerWidget {
  const _ConnectionErrorOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(connectionErrorProvider);
    if (error == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.red.shade900,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_off_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  error,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  ref.read(connectionErrorProvider.notifier).state = null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  final String path;
  final IconData icon;
  final String label;
  final AppScreen screen;
  const _NavTab(this.path, this.icon, this.label, this.screen);
}

class _GarageBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _GarageBottomNav({required this.currentIndex, required this.onTap});

  static const _tabs = [
    _NavTab(
      '/dashboard',
      Icons.dashboard_rounded,
      'Dashboard',
      AppScreen.dashboard,
    ),
    _NavTab(
      '/customers',
      Icons.people_rounded,
      'Customers',
      AppScreen.customers,
    ),
    _NavTab('/jobs', Icons.assignment_rounded, 'Jobs', AppScreen.jobs),
    _NavTab(
      '/inventory',
      Icons.inventory_2_rounded,
      'Inventory',
      AppScreen.inventory,
    ),
    _NavTab(
      '/secondhand-inventory',
      Icons.recycling_rounded,
      'Second Hand',
      AppScreen.secondHandInventory,
    ),
    _NavTab('/profile', Icons.person_rounded, 'Profile', AppScreen.profile),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        border: Border(top: BorderSide(color: kBorder, width: 0.8)),
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
                      // Fixed-height label box: keeps every tab's icon +
                      // underline at the same vertical position, even if
                      // a label like "Second Hand" would otherwise wrap.
                      SizedBox(
                        height: 12,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            tab.label,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isActive ? kPrimary : kMutedForeground,
                            ),
                          ),
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