import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xlrat/local_database/billing_database.dart';
import 'package:xlrat/models/InventoryItem.dart';
import 'package:xlrat/models/SecondHandItem.dart';
import 'package:xlrat/repository/InventoryRepository.dart';
import 'package:xlrat/repository/SecondHandInventoryRepository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('InventoryRepository and SecondHandInventoryRepository Clock Skew Fix Tests', () {
    late FakeFirebaseFirestore firestore;
    late InventoryRepository inventoryRepo;
    late SecondHandInventoryRepository secondHandRepo;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      inventoryRepo = InventoryRepository(garageId: 'test-garage', firestore: firestore);
      secondHandRepo = SecondHandInventoryRepository(garageId: 'test-garage', firestore: firestore);

      final db = await BillingDatabase.instance.database;
      await db.delete('inventory');
      await db.delete('secondhand_inventory');
    });

    test('InventoryRepository createItem and updateItem write FieldValue.serverTimestamp to Firestore and local timestamp to SQLite', () async {
      final item = InventoryItem(
        name: 'Oil Filter',
        category: 'Engine',
        stock: 10,
        unit: 'pcs',
        purchase: 200,
        selling: 350,
        minStock: 5,
        sku: 'OIL-123',
        createdAt: DateTime.now(),
      );

      // 1. Create Item
      final created = await inventoryRepo.createItem(item);
      expect(created.id, isNotNull);
      expect(created.updatedAt, isNull);

      // Verify Firestore write
      final doc = await firestore
          .collection('garages')
          .doc('test-garage')
          .collection('inventory')
          .doc(created.id)
          .get();
      expect(doc.exists, isTrue);
      // FakeFirebaseFirestore automatically resolves FieldValue.serverTimestamp() to a Timestamp
      expect(doc.data()?['updatedAt'], isNotNull);

      // Verify SQLite write
      final db = await BillingDatabase.instance.database;
      final sqliteRows = await db.query('inventory', where: 'id = ?', whereArgs: [created.id]);
      expect(sqliteRows, hasLength(1));
      expect(sqliteRows.first['updated_at'], isNotNull);
      expect(sqliteRows.first['updated_at'] as int, isPositive);

      // 2. Update Item
      final toUpdate = created.copyWith(stock: 12);
      final updated = await inventoryRepo.updateItem(toUpdate);
      expect(updated.id, created.id);
      expect(updated.updatedAt, isNull);

      // Verify Firestore write for update
      final updatedDoc = await firestore
          .collection('garages')
          .doc('test-garage')
          .collection('inventory')
          .doc(created.id)
          .get();
      expect(updatedDoc.data()?['stock'], equals(12));
      expect(updatedDoc.data()?['updatedAt'], isNotNull);

      // Verify SQLite write for update
      final updatedSqliteRows = await db.query('inventory', where: 'id = ?', whereArgs: [created.id]);
      expect(updatedSqliteRows.first['stock'], equals(12));
      expect(updatedSqliteRows.first['updated_at'] as int, isPositive);
    });

    test('SecondHandInventoryRepository createItem and updateItem write FieldValue.serverTimestamp to Firestore and local timestamp to SQLite', () async {
      final item = SecondHandItem(
        name: 'Used Carburetor',
        category: 'Fuel System',
        stock: 1,
        unit: 'pcs',
        purchase: 1000,
        selling: 1800,
        minStock: 0,
        sku: 'CARB-99',
        createdAt: DateTime.now(),
      );

      // 1. Create Item
      final created = await secondHandRepo.createItem(item);
      expect(created.id, isNotNull);
      expect(created.updatedAt, isNull);

      // Verify Firestore write
      final doc = await firestore
          .collection('garages')
          .doc('test-garage')
          .collection('secondhand_inventory')
          .doc(created.id)
          .get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['updatedAt'], isNotNull);

      // Verify SQLite write
      final db = await BillingDatabase.instance.database;
      final sqliteRows = await db.query('secondhand_inventory', where: 'id = ?', whereArgs: [created.id]);
      expect(sqliteRows, hasLength(1));
      expect(sqliteRows.first['updated_at'] as int, isPositive);

      // 2. Update Item
      final toUpdate = created.copyWith(stock: 2);
      final updated = await secondHandRepo.updateItem(toUpdate);
      expect(updated.id, created.id);
      expect(updated.updatedAt, isNull);

      // Verify Firestore write for update
      final updatedDoc = await firestore
          .collection('garages')
          .doc('test-garage')
          .collection('secondhand_inventory')
          .doc(created.id)
          .get();
      expect(updatedDoc.data()?['stock'], equals(2));
      expect(updatedDoc.data()?['updatedAt'], isNotNull);

      // Verify SQLite write for update
      final updatedSqliteRows = await db.query('secondhand_inventory', where: 'id = ?', whereArgs: [created.id]);
      expect(updatedSqliteRows.first['stock'], equals(2));
      expect(updatedSqliteRows.first['updated_at'] as int, isPositive);
    });
  });
}
