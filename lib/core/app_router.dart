// lib/core/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../Screen/SplashScreen.dart';
import '../Screen/auth/LoginScreen.dart';
import '../Screen/auth/OtpScreen.dart';
import '../Screen/navigationscreen/Billing/BillingScreen.dart';
import '../Screen/navigationscreen/Billing/InvoiceHistoryScreen.dart';
import '../Screen/navigationscreen/Billing/InvoiceScreen.dart';
import '../Screen/navigationscreen/Customers/CustomersScreen.dart';
import '../Screen/navigationscreen/DashboardScreen.dart';
import '../Screen/navigationscreen/Inventory/InventoryScreen.dart';
import '../Screen/navigationscreen/Job/JobsScreen.dart';
import '../Screen/repot/ReportsScreen.dart';
import 'MainShell.dart';



final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // ── Auth / Splash (no bottom nav) ──────────────────────────────────────
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) => const OtpScreen(),
    ),

    // ── Detail screens (no bottom nav) ─────────────────────────────────────
    GoRoute(
      path: '/customer-detail',
      builder: (context, state) => const CustomerDetailScreen(),
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

        return InvoiceScreen(
          invoiceId: invoiceId,
        );
      },
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),

    // ── Main Shell (with bottom nav) ───────────────────────────────────────
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
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);