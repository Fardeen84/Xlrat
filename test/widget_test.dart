import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import 'package:xlrat/main.dart';
import 'package:xlrat/providers/profile_provider.dart';
import 'package:xlrat/core/app_router.dart';

void main() {
  testWidgets('App launch smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final mockRouter = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Splash Screen Mock')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appRouterProvider.overrideWithValue(mockRouter),
        ],
        child: const MyApp(),
      ),
    );

    // Allow frames to build
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

