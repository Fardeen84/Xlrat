import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'core/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screen/SplashScreen.dart';
import 'core/app_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:xlrat/l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/billing_providers.dart';
import 'providers/firestoreServiceProvider.dart';
import 'core/Theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  Map<String, String> envConfig = const {};
  try {
    final raw = await rootBundle.loadString('env.json');
    final parsed = jsonDecode(raw) as Map<String, dynamic>;
    envConfig = parsed.map((key, value) => MapEntry(key, value.toString()));
  } catch (_) {
    // env.json not bundled/found — fine if --dart-define was used instead.
  }

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1024, 600),
      minimumSize: Size(1024, 600),
      center: true,
      title: "Asian Fabrication & Engineers",
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      envConfigProvider.overrideWithValue(envConfig),
    ],
  );

  bool initialized = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform(envConfig),
    );
    initialized = true;

    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
      );
    } catch (e) {
      print('Firestore offline persistence configuration failed: $e');
    }

    try {
      await AuthService.ensureSignedIn();
    } catch (e) {
      print('AuthService.ensureSignedIn failed: $e');
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      container.read(profileLoadingProvider.notifier).state = true;
      try {
        final uid = currentUser.uid;
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (userDoc.exists) {
          final data = userDoc.data();
          final garageId = data?['garageId'] as String?;
          if (garageId != null && garageId.isNotEmpty) {
            final garageDoc = await FirebaseFirestore.instance.collection('garages').doc(garageId).get();
            final garageData = garageDoc.data();
            final garageName = garageData?['name'] as String? ?? '';
            final gstNumber = garageData?['gstNumber'] as String? ?? '';
            final address = garageData?['address'] as String? ?? '';

            container.read(profileProvider.notifier).updateProfile(
              garageId: garageId,
              garageName: garageName,
              gstNumber: gstNumber,
              address: address,
            );
          }
        }
      } catch (authError) {
        print('Firestore profile load failed: $authError');
      } finally {
        container.read(profileLoadingProvider.notifier).state = false;
      }
    }
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  if (!initialized) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'No Internet Connection',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Could not connect to the database. Please check your internet connection and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      main();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  // Initialize reminder service asynchronously in background
  container.read(reminderServiceProvider).init();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      windowManager.addListener(this);
      _initPreventClose();
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _initPreventClose() async {
    await windowManager.setPreventClose(true);
  }

  @override
  void onWindowClose() async {
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      final shouldExit = await showDialog<bool>(
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
      if (shouldExit == true) {
        await windowManager.destroy();
      }
    } else {
      await windowManager.destroy();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: locale,
      theme: buildTheme(),
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}