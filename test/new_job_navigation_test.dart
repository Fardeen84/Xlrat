import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:xlrat/local_database/billing_database.dart';
import 'package:xlrat/models/billing_model/BillingCustomer.dart';
import 'package:xlrat/models/NewJobFormState.dart';
import 'package:xlrat/providers/newJobFormProvider.dart';
import 'package:xlrat/screen/navigation_screen/job/NewJobScreen.dart';
import 'package:xlrat/providers/profile_provider.dart';
import 'package:xlrat/screen/navigation_screen/customers/CustomersScreen.dart';
import 'package:xlrat/providers/billing_providers.dart';
import 'package:xlrat/l10n/app_localizations.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xlrat/repository/CustomerRepository.dart';
import 'package:xlrat/repository/VehicleRepository.dart';
import 'package:xlrat/repository/BillingRepository.dart';
import 'package:xlrat/repository/JobRepository.dart';
import 'package:xlrat/repository/InventoryRepository.dart';
import 'package:xlrat/repository/SecondHandInventoryRepository.dart';
import 'package:xlrat/repository/MechanicRepository.dart';
import 'package:xlrat/providers/jobsProvider.dart';
import 'package:xlrat/providers/inventoryProvider.dart';
import 'package:xlrat/providers/secondHandInventoryProvider.dart';
import 'package:xlrat/providers/mechanicsProvider.dart';

List<Override> getMockOverrides({required SharedPreferences prefs, FirebaseFirestore? firestore}) {
  final fs = firestore ?? FakeFirebaseFirestore();
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
    customerRepositoryProvider.overrideWithValue(CustomerRepository(garageId: 'test-garage', firestore: fs)),
    vehicleRepositoryProvider.overrideWithValue(VehicleRepository(garageId: 'test-garage', firestore: fs)),
    billingRepositoryProvider.overrideWithValue(BillingRepository(garageId: 'test-garage', firestore: fs)),
    jobRepositoryProvider.overrideWithValue(JobRepository(garageId: 'test-garage', firestore: fs)),
    inventoryRepositoryProvider.overrideWithValue(InventoryRepository(garageId: 'test-garage', firestore: fs)),
    secondHandInventoryRepositoryProvider.overrideWithValue(SecondHandInventoryRepository(garageId: 'test-garage', firestore: fs)),
    mechanicRepositoryProvider.overrideWithValue(MechanicRepository(garageId: 'test-garage', firestore: fs)),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('NewJobScreen handles state updates when reused', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: getMockOverrides(prefs: prefs),
    );

    // 1. Initial render with default state (step 1)
    container.read(newJobFormProvider.notifier).state = const NewJobFormState(
      step: 1,
      customer: null,
    );

    // We use a GlobalKey to ensure the exact same state object is reused
    final key = GlobalKey();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NewJobScreen(key: key),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Search Customer'), findsOneWidget);

    // 2. Simulate user navigating away, setting new state externally, and navigating back
    final testCustomer = BillingCustomer(
      id: '99',
      name: 'Preselected Customer',
      mobile: '9876543210',
      createdAt: DateTime.now(),
    );

    container.read(newJobFormProvider.notifier).state = NewJobFormState(
      step: 2,
      customer: testCustomer,
    );

    // Re-pump the same widget tree (simulating GoRouter returning to reused screen state)
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NewJobScreen(key: key),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify it correctly updated to step 2 and shows the preselected customer name
    expect(find.text('Select Vehicle'), findsOneWidget);
    expect(find.text('Preselected Customer'), findsOneWidget);
  });

  testWidgets('CustomersScreen PC layout sets provider correctly when tapping New Job Card', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final testCustomer = BillingCustomer(
      id: '99',
      name: 'PC Test Customer',
      mobile: '9876543210',
      createdAt: DateTime.now(),
    );

    final container = ProviderContainer(
      overrides: [
        ...getMockOverrides(prefs: prefs),
        // Override filteredBillingCustomersProvider to return our list
        filteredBillingCustomersProvider.overrideWith((ref) => Future.value([testCustomer])),
        // Select the customer
        selectedCustomerProvider.overrideWith((ref) => testCustomer),
      ],
    );

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const CustomersScreen(),
        ),
        GoRoute(
          path: '/new-job',
          builder: (context, state) => const Scaffold(body: Text('New Job Page')),
        ),
      ],
    );

    // Set screen size to PC width (e.g., 1200) to force the PC layout
    await tester.binding.setSurfaceSize(const Size(1200, 800));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(Duration.zero);
    await tester.pumpAndSettle();



    // Verify detail panel shows the selected customer
    expect(find.text('PC Test Customer'), findsAtLeastNWidgets(1));

    // Tap "New Job Card" button
    final newJobButton = find.text('New Job Card');
    expect(newJobButton, findsOneWidget);
    await tester.tap(newJobButton);
    await tester.pump();

    // Check that newJobFormProvider has been updated
    final jobFormState = container.read(newJobFormProvider);
    expect(jobFormState.step, 2);
    expect(jobFormState.customer, testCustomer);

    // Reset surface size
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('NewJobScreen step 2 toggle switches between Vehicle Job and Item Job', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final testCustomer = BillingCustomer(
      id: '99',
      name: 'Test Customer',
      mobile: '9876543210',
      createdAt: DateTime.now(),
    );

    final container = ProviderContainer(
      overrides: [
        ...getMockOverrides(prefs: prefs),
        customerListProvider.overrideWith((ref) => Stream.value([])),
        vehiclesForCustomerProvider('99').overrideWith((ref) => Future.value([])),
      ],
    );

    // Initial state: Step 2 with customer selected
    container.read(newJobFormProvider.notifier).state = NewJobFormState(
      step: 2,
      customer: testCustomer,
      jobType: 'vehicle',
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: NewJobScreen()),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Initially should show "Vehicle Job" text and "Select Vehicle" header
    expect(find.text('Vehicle Job'), findsOneWidget);
    expect(find.text('Item Job'), findsOneWidget);
    expect(find.text('Select Vehicle'), findsOneWidget);
    expect(find.text('Item Details'), findsNothing);

    // Tap on "Item Job" toggle
    await tester.tap(find.text('Item Job'));
    await tester.pumpAndSettle();

    // Now it should show "Item Details" and text form fields instead of vehicle selector
    expect(find.text('Select Vehicle'), findsNothing);
    expect(find.text('Item Details'), findsOneWidget);
    expect(find.text('Item Name *'), findsOneWidget);
    expect(find.text('Item Description / Notes (Optional)'), findsOneWidget);
  });
}
