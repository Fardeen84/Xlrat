// lib/core/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screen/SplashScreen.dart';
import '../screen/auth/LoginScreen.dart';
import '../screen/auth/OtpScreen.dart';
import '../screen/navigation_screen/billing/BillingScreen.dart';
import '../screen/navigation_screen/billing/InvoiceHistoryScreen.dart';
import '../screen/navigation_screen/billing/InvoiceScreen.dart';
import '../screen/navigation_screen/customers/CustomersScreen.dart';
import '../screen/navigation_screen/DashboardScreen.dart';
import '../screen/navigation_screen/inventory/InventoryScreen.dart';
import '../screen/navigation_screen/job/JobsScreen.dart';
import '../screen/report/ReportsScreen.dart';
import '../screen/navigation_screen/customers/CustomerDetailScreen.dart';
import '../screen/navigation_screen/job/JobDetailScreen.dart';
import '../screen/navigation_screen/job/NewJobScreen.dart';
import '../screen/navigation_screen/NotificationsScreen.dart';
import '../screen/navigation_screen/ProfileScreen.dart';
import 'MainShell.dart';
import 'auth_state.dart';

final appRouter = GoRouter(
  initialLocation: '/dashboard',
  redirect: (context, state) {
    final isLoggedIn = AuthState.isLoggedIn;
    final isGoingToLogin = state.matchedLocation == '/login';
    final isGoingToSplash = state.matchedLocation == '/';

    if (!isLoggedIn && !isGoingToLogin && !isGoingToSplash) {
      return '/login';
    }
    if (isLoggedIn && isGoingToLogin) {
      return '/dashboard';
    }
    return null;
  },
  routes: [
    // ── Auth / Splash (no bottom nav) ──────────────────────────────────────
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/otp', builder: (context, state) => const OtpScreen()),

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
        GoRoute(path: '/jobs', builder: (context, state) => const JobsScreen()),
        GoRoute(
          path: '/inventory',
          builder: (context, state) => const InventoryScreen(),
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
          path: '/customer-detail/:id',
          builder: (context, state) {
            final customerId = int.parse(state.pathParameters['id']!);
            return CustomerDetailScreen(customerId: customerId);
          },
        ),
        GoRoute(
          path: '/job-detail',
          builder: (context, state) => const JobDetailScreen(),
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
            final invoiceId = int.parse(state.pathParameters['id']!);
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
