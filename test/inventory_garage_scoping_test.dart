import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xlrat/local_database/billing_database.dart';
import 'package:xlrat/models/InventoryItem.dart';
import 'package:xlrat/models/SecondHandItem.dart';
import 'package:xlrat/repository/InventoryRepository.dart';
import 'package:xlrat/repository/SecondHandInventoryRepository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Garage Scoping and Orphan Check Sync Tests', () {
    late FakeFirebaseFirestore firestore;
    late InventoryRepository repoA;
    late InventoryRepository repoB;
    late SecondHandInventoryRepository shRepoA;
    late SecondHandInventoryRepository shRepoB;
    late SharedPreferences prefs;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      repoA = InventoryRepository(garageId: 'garage-A', firestore: firestore);
      repoB = InventoryRepository(garageId: 'garage-B', firestore: firestore);
      shRepoA = SecondHandInventoryRepository(garageId: 'garage-A', firestore: firestore);
      shRepoB = SecondHandInventoryRepository(garageId: 'garage-B', firestore: firestore);

      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      final db = await BillingDatabase.instance.database;
      await db.delete('inventory');
      await db.delete('secondhand_inventory');
    });

    test('Inventory and SecondHand items created in Garage A do not leak to Garage B queries', () async {
      final itemA = InventoryItem(
        name: 'Spark Plug A',
        category: 'Engine',
        stock: 10,
        unit: 'pcs',
        purchase: 100,
        selling: 150,
        minStock: 2,
        sku: 'SPK-A',
        createdAt: DateTime.now(),
      );

      final shItemA = SecondHandItem(
        name: 'Used Alternator A',
        category: 'Electrical',
        stock: 1,
        unit: 'pcs',
        purchase: 500,
        selling: 900,
        minStock: 0,
        sku: 'ALT-A',
        createdAt: DateTime.now(),
      );

      // Save in Garage A
      await repoA.createItem(itemA);
      await shRepoA.createItem(shItemA);

      // Verify local fetch for Garage A returns the items
      final localA = await repoA.getLocalItems();
      expect(localA.any((item) => item.name == 'Spark Plug A'), isTrue);

      final shLocalA = await shRepoA.getLocalItems();
      expect(shLocalA.any((item) => item.name == 'Used Alternator A'), isTrue);

      // Verify local fetch for Garage B does NOT return the items
      final localB = await repoB.getLocalItems();
      expect(localB.any((item) => item.name == 'Spark Plug A'), isFalse);

      final shLocalB = await shRepoB.getLocalItems();
      expect(shLocalB.any((item) => item.name == 'Used Alternator A'), isFalse);

      // Verify search scoping
      final searchA = await repoA.searchItems('Spark');
      expect(searchA.any((item) => item.name == 'Spark Plug A'), isTrue);

      final searchB = await repoB.searchItems('Spark');
      expect(searchB.any((item) => item.name == 'Spark Plug A'), isFalse);
    });

    test('Orphan check logic identifies and backfills documents missing updatedAt in Firestore and SQLite', () async {
      // 1. Initial Sync setup
      // Set repair flag to true so one-time repair scan is bypassed
      await prefs.setBool('inventory_updatedAt_repaired_garage-A', true);
      // Set last sync timestamp to bypass initial sync
      await prefs.setInt('inventory_last_sync_garage-A', DateTime.now().millisecondsSinceEpoch - 10000);

      // Insert an orphan document directly to Firestore (without updatedAt)
      await firestore
          .collection('garages')
          .doc('garage-A')
          .collection('inventory')
          .doc('orphan-doc-id')
          .set({
        'name': 'Orphan Part',
        'category': 'Body',
        'stock': 5,
        'unit': 'pcs',
        'purchase': 50,
        'selling': 80,
        'minStock': 1,
        'sku': 'ORP-1',
        'createdAt': DateTime.now().toIso8601String(),
        // No updatedAt/isLowStock fields
      });

      // 2. Perform first sync. The delta sync itself will fetch nothing from range query, but should trigger orphan check.
      // Set last orphan check to 25 hours ago to trigger the check.
      final dayAgo = DateTime.now().subtract(const Duration(hours: 25));
      await prefs.setInt('inventory_last_orphan_check_garage-A', dayAgo.millisecondsSinceEpoch);

      final syncedCount = await repoA.syncFromFirestore(prefs);
      // It should have scanned the orphan document, updated Firestore, and written to SQLite
      expect(syncedCount, greaterThanOrEqualTo(1));

      // Verify Firestore document was updated with updatedAt
      final docSnap = await firestore
          .collection('garages')
          .doc('garage-A')
          .collection('inventory')
          .doc('orphan-doc-id')
          .get();
      expect(docSnap.data()!.containsKey('updatedAt'), isTrue);

      // Verify SQLite has the row scoped to garage-A
      final localItems = await repoA.getLocalItems();
      expect(localItems.any((i) => i.id == 'orphan-doc-id'), isTrue);
      
      final db = await BillingDatabase.instance.database;
      final rawRows = await db.query('inventory', where: 'id = ?', whereArgs: ['orphan-doc-id']);
      expect(rawRows.first['garage_id'], 'garage-A');
    });

    test('Orphan check continues paginating cursor across multiple syncFromFirestore calls, regardless of 24h gate (Clarification C)', () async {
      await prefs.setBool('inventory_updatedAt_repaired_garage-A', true);
      await prefs.setInt('inventory_last_sync_garage-A', DateTime.now().millisecondsSinceEpoch - 10000);

      // Create 1500 documents in Firestore in batches of 500
      for (int b = 0; b < 3; b++) {
        final batch = firestore.batch();
        for (int i = b * 500; i < (b + 1) * 500; i++) {
          final ref = firestore
              .collection('garages')
              .doc('garage-A')
              .collection('inventory')
              .doc('doc-$i');
          batch.set(ref, {
            'name': 'Part $i',
            'category': 'Engine',
            'stock': 5,
            'unit': 'pcs',
            'purchase': 50,
            'selling': 80,
            'minStock': 1,
            'sku': 'SKU-$i',
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
        await batch.commit();
      }

      // Trigger first scan (no lastDocId in prefs yet)
      final dayAgo = DateTime.now().subtract(const Duration(hours: 25));
      await prefs.setInt('inventory_last_orphan_check_garage-A', dayAgo.millisecondsSinceEpoch);

      // First sync call should fetch 1000 items (since batch limit is 1000)
      final count1 = await repoA.syncFromFirestore(prefs);
      expect(count1, equals(1000));

      // Verify cursor is saved in SharedPreferences
      final cursorDocId = prefs.getString('inventory_orphan_check_last_doc_id_garage-A');
      expect(cursorDocId, isNotEmpty);

      // Reset the last orphan check to now (within 24 hours).
      // A subsequent scan should STILL proceed because a resume cursor exists (Clarification C).
      await prefs.setInt('inventory_last_orphan_check_garage-A', DateTime.now().millisecondsSinceEpoch);
      // Update last sync time to now to prevent delta sync from fetching the first batch's updated documents
      await prefs.setInt('inventory_last_sync_garage-A', DateTime.now().millisecondsSinceEpoch);

      // Second sync call should fetch the remaining 500 items and clear cursor
      final count2 = await repoA.syncFromFirestore(prefs);
      expect(count2, equals(500));

      final cursorDocIdAfter = prefs.getString('inventory_orphan_check_last_doc_id_garage-A');
      expect(cursorDocIdAfter, isNull); // cleared since scan finished
    });
  });
}
