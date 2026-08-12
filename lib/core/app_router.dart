import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screen/SplashScreen.dart';
import '../screen/auth/SetupGarageScreen.dart';
import '../screen/navigation_screen/billing/BillingScreen.dart';
import '../screen/navigation_screen/billing/InvoiceHistoryScreen.dart';
import '../screen/navigation_screen/billing/InvoiceScreen.dart';
import '../screen/navigation_screen/customers/CustomersScreen.dart';
import '../screen/navigation_screen/DashboardScreen.dart';
import '../screen/navigation_screen/inventory/InventoryScreen.dart';
import '../screen/navigation_screen/secondhand/SecondHandInventoryScreen.dart';
import '../screen/navigation_screen/services/ServicesScreen.dart';
import '../screen/navigation_screen/job/JobsScreen.dart';
import '../screen/report/ReportsScreen.dart';
import '../screen/navigation_screen/customers/CustomerDetailScreen.dart';
import '../screen/navigation_screen/job/JobDetailScreen.dart';
import '../screen/navigation_screen/job/NewJobScreen.dart';
import '../screen/navigation_screen/NotificationsScreen.dart';
import '../screen/navigation_screen/ProfileScreen.dart';
import '../screen/navigation_screen/mechanics/MechanicsScreen.dart';
import '../providers/profile_provider.dart';
import 'MainShell.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    ref.listen(profileProvider, (previous, next) {
      notifyListeners();
    });
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(ref),
    redirect: (context, state) {
      final profileLoading = ref.watch(profileLoadingProvider);
      if (profileLoading) {
        return null;
      }

      final profile = ref.watch(profileProvider);
      final hasGarageId = profile.garageId.isNotEmpty;
      final isGoingToSplash = state.matchedLocation == '/';
      final isGoingToSetup = state.matchedLocation == '/setup-garage';

      if (!hasGarageId) {
        if (!isGoingToSetup) {
          return '/setup-garage';
        }
      } else {
        if (isGoingToSplash || isGoingToSetup) {
          return '/dashboard';
        }
      }
      return null;
    },
    routes: [
      // ── Auth / Splash (no bottom nav) ──────────────────────────────────────
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/setup-garage',
        builder: (context, state) => const SetupGarageScreen(),
      ),

      // ── Main Shell ───────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomersScreen(),
          ),
          GoRoute(
            path: '/jobs',
            builder: (context, state) => const JobsScreen(),
          ),
          GoRoute(
            path: '/inventory',
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: '/secondhand-inventory',
            builder: (context, state) => const SecondHandInventoryScreen(),
          ),
          GoRoute(
            path: '/services',
            builder: (context, state) => const ServicesScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/mechanics',
            builder: (context, state) => const MechanicsScreen(),
          ),
          GoRoute(
            path: '/customer-detail/:id',
            builder: (context, state) {
              final customerId = state.pathParameters['id']!;
              return CustomerDetailScreen(customerId: customerId);
            },
          ),
          GoRoute(
            path: '/job-detail/:id',
            builder: (context, state) {
              final jobId = state.pathParameters['id']!;
              return JobDetailScreen(jobId: jobId);
            },
          ),
          GoRoute(
            path: '/new-job',
            builder: (context, state) => const NewJobScreen(),
          ),
          GoRoute(
            path: '/billing',
            builder: (context, state) => const BillingScreen(),
          ),
          GoRoute(
            path: '/InvoiceHistory',
            builder: (context, state) => const InvoiceHistoryScreen(),
          ),
          GoRoute(
            path: '/invoice/:id',
            builder: (context, state) {
              final invoiceId = state.pathParameters['id']!;
              return InvoiceScreen(invoiceId: invoiceId);
            },
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
        ],
      ),
    ],
  );
});
