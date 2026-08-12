// This test verifies that the autocomplete search layer works correctly:
// - FTS5 tables are created and populated via triggers on insert
// - searchItems() returns matching items from the local SQLite FTS index
// - Matching is case-insensitive and works with partial words
//
// We intentionally avoid widget-level testing of BillingItemsSection because
// the bottom sheet requires complex provider setup and platform channels that
// are better verified via manual testing on a device.

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xlrat/local_database/billing_database.dart';
import 'package:xlrat/models/InventoryItem.dart';
import 'package:xlrat/models/SecondHandItem.dart';
import 'package:xlrat/models/ServiceItem.dart';
import 'package:xlrat/repository/InventoryRepository.dart';
import 'package:xlrat/repository/SecondHandInventoryRepository.dart';
import 'package:xlrat/repository/ServiceRepository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Autocomplete searchItems() — repository layer', () {
    late InventoryRepository invRepo;
    late SecondHandInventoryRepository shRepo;
    late ServiceRepository svcRepo;

    setUp(() async {
      // Fresh in-memory database for each test — no platform channels.
      BillingDatabase.customPath = inMemoryDatabasePath;
      final firestore = FakeFirebaseFirestore();
      invRepo = InventoryRepository(garageId: 'test-garage', firestore: firestore);
      shRepo = SecondHandInventoryRepository(garageId: 'test-garage', firestore: firestore);
      svcRepo = ServiceRepository(garageId: 'test-garage', firestore: firestore);
    });

    tearDown(() async {
      // Close the in-memory DB so each test gets a fresh one, but only when
      // customPath is set. This avoids closing the shared file-based singleton
      // that other test files depend on.
      if (BillingDatabase.customPath != null) {
        await BillingDatabase.instance.close();
      }
      BillingDatabase.customPath = null;
    });

    test('Inventory: insert triggers FTS and search returns matching item', () async {
      final db = await BillingDatabase.instance.database;

      // Insert via raw DB to trigger the inventory_after_insert FTS trigger.
      await db.insert('inventory', {
        'id': 'item-1',
        'name': 'Brake Pad Premium',
        'category': 'Brakes',
        'stock': 10,
        'unit': 'pcs',
        'purchase': 500,
        'selling': 800,
        'min_stock': 2,
        'sku': 'BP-PREM',
        'created_at': DateTime.now().toIso8601String(),
        'sync_status': 'synced',
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'is_deleted': 0,
        'name_lower': 'brake pad premium',
        'sku_lower': 'bp-prem',
        'category_lower': 'brakes',
        'garage_id': 'test-garage',
      });

      final results = await invRepo.searchItems('brake');
      expect(results, isNotEmpty);
      expect(results.first.name, 'Brake Pad Premium');
    });

    test('Inventory: partial word mid-token match works', () async {
      final db = await BillingDatabase.instance.database;
      await db.insert('inventory', {
        'id': 'item-2',
        'name': 'Oil Filter Standard',
        'category': 'Engine',
        'stock': 5,
        'unit': 'pcs',
        'purchase': 200,
        'selling': 350,
        'min_stock': 1,
        'sku': 'OIL-F-STD',
        'created_at': DateTime.now().toIso8601String(),
        'sync_status': 'synced',
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'is_deleted': 0,
        'name_lower': 'oil filter standard',
        'sku_lower': 'oil-f-std',
        'category_lower': 'engine',
        'garage_id': 'test-garage',
      });

      // FTS prefix match: "filt" should match "Filter"
      final results = await invRepo.searchItems('filt');
      expect(results, isNotEmpty);
      expect(results.first.name, 'Oil Filter Standard');
    });

    test('Inventory: case-insensitive search works', () async {
      final db = await BillingDatabase.instance.database;
      await db.insert('inventory', {
        'id': 'item-3',
        'name': 'Spark Plug NGK',
        'category': 'Ignition',
        'stock': 20,
        'unit': 'pcs',
        'purchase': 80,
        'selling': 150,
        'min_stock': 5,
        'sku': 'SP-NGK',
        'created_at': DateTime.now().toIso8601String(),
        'sync_status': 'synced',
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'is_deleted': 0,
        'name_lower': 'spark plug ngk',
        'sku_lower': 'sp-ngk',
        'category_lower': 'ignition',
        'garage_id': 'test-garage',
      });

      final results = await invRepo.searchItems('SPARK');
      expect(results, isNotEmpty);
      expect(results.first.name, 'Spark Plug NGK');
    });

    test('Inventory: empty query returns all items', () async {
      final db = await BillingDatabase.instance.database;
      for (int i = 1; i <= 3; i++) {
        await db.insert('inventory', {
          'id': 'item-$i',
          'name': 'Item $i',
          'category': 'Cat',
          'stock': 1,
          'unit': 'pcs',
          'purchase': 100,
          'selling': 200,
          'min_stock': 1,
          'sku': 'SKU-$i',
          'created_at': DateTime.now().toIso8601String(),
          'sync_status': 'synced',
          'updated_at': DateTime.now().millisecondsSinceEpoch,
          'is_deleted': 0,
          'name_lower': 'item $i',
          'sku_lower': 'sku-$i',
          'category_lower': 'cat',
          'garage_id': 'test-garage',
        });
      }
      final results = await invRepo.searchItems('');
      expect(results.length, 3);
    });

    test('SecondHand: search finds secondhand items', () async {
      final db = await BillingDatabase.instance.database;
      await db.insert('secondhand_inventory', {
        'id': 'sh-1',
        'name': 'Used Alternator',
        'category': 'Electrical',
        'stock': 2,
        'unit': 'pcs',
        'purchase': 800,
        'selling': 1500,
        'min_stock': 0,
        'sku': 'UA-001',
        'created_at': DateTime.now().toIso8601String(),
        'sync_status': 'synced',
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'is_deleted': 0,
        'name_lower': 'used alternator',
        'sku_lower': 'ua-001',
        'category_lower': 'electrical',
        'garage_id': 'test-garage',
      });

      final results = await shRepo.searchItems('alternator');
      expect(results, isNotEmpty);
      expect(results.first.name, 'Used Alternator');
    });

    test('Service: search finds service items', () async {
      final db = await BillingDatabase.instance.database;
      await db.insert('services', {
        'id': 'svc-1',
        'name': 'Full Service A/C',
        'category': 'AC',
        'price': 1200.0,
        'created_at': DateTime.now().toIso8601String(),
        'sync_status': 'synced',
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'is_deleted': 0,
        'name_lower': 'full service a/c',
        'category_lower': 'ac',
        'garage_id': 'test-garage',
      });

      final results = await svcRepo.searchItems('service');
      expect(results, isNotEmpty);
      expect((results.first as dynamic).name, 'Full Service A/C');
    });
  });
}
