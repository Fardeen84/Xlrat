
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Service/CloudSyncService.dart';
import '../core/FirestoreRestService.dart';
import '../local_database/billing_database.dart';
import 'profile_provider.dart';


final firestoreServiceProvider = Provider<FirestoreRestService>((ref) {
  const apiKey = String.fromEnvironment('FIREBASE_API_KEY', defaultValue: '');
  const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'xlrat-garage');

  if (apiKey.isEmpty) {
    final isTesting = WidgetsBinding.instance?.runtimeType.toString().contains('Test') ?? false;
    if (!isTesting) {
      throw StateError(
        'FIREBASE_API_KEY is not set. Run with --dart-define=FIREBASE_API_KEY=... or --dart-define-from-file=env.json'
      );
    }
  }

  return FirestoreRestService(
    projectId: projectId,
    apiKey: apiKey,
  );
});


final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  final garageId = ref.watch(profileProvider).garageId;
  return CloudSyncService(BillingDatabase.instance, firestore, garageId);
});