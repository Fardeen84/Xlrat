import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/InventoryItem.dart';
import '../local_database/billing_database.dart';

/// Direct Firestore repository for inventory items, backed by local SQLite cache.
class InventoryRepository {
  InventoryRepository({required this.garageId, this.onWriteError, FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final String garageId;
  final Function(String)? onWriteError;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('garages').doc(garageId).collection('inventory');

  // ─── Create ───────────────────────────────────────────────────────────────

  Future<InventoryItem> createItem(InventoryItem item) async {
    try {
      final docRef = _collection.doc();
      final toSave = InventoryItem(
        id: docRef.id,
        name: item.name,
        category: item.category,
        stock: item.stock,
        unit: item.unit,
        purchase: item.purchase,
        selling: item.selling,
        minStock: item.minStock,
        sku: item.sku,
        createdAt: item.createdAt,
        updatedAt: null,
      );

      // Write to Firestore (will automatically compute isLowStock on Firestore via toMap)
      await docRef.set(toSave.toMap());

      // Write to local SQLite
      final db = await BillingDatabase.instance.database;
      await db.insert(
        'inventory',
        {
          'id': toSave.id,
          'name': toSave.name,
          'category': toSave.category,
          'stock': toSave.stock,
          'unit': toSave.unit,
          'purchase': toSave.purchase,
          'selling': toSave.selling,
          'min_stock': toSave.minStock,
          'sku': toSave.sku,
          'created_at': toSave.createdAt.toIso8601String(),
          'sync_status': 'pending',
          'updated_at': DateTime.now().millisecondsSinceEpoch,
          'is_deleted': 0,
          'name_lower': toSave.name.toLowerCase(),
          'sku_lower': toSave.sku.toLowerCase(),
          'category_lower': toSave.category.toLowerCase(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return toSave;
    } catch (e) {
      onWriteError?.call(e.toString());
      rethrow;
    }
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  Future<InventoryItem?> getItem(String id) async {
    // Read from SQLite first
    final db = await BillingDatabase.instance.database;
    final rows = await db.query('inventory', where: 'id = ?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      return InventoryItem.fromMap(rows.first);
    }

    // Fallback to Firestore if not found locally
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return InventoryItem.fromMap(doc.data()!..['id'] = doc.id);
  }

  Future<List<InventoryItem>> getLocalItems() async {
    final db = await BillingDatabase.instance.database;
    final rows = await db.query('inventory', where: 'is_deleted = 0', orderBy: 'name ASC');
    return rows.map((row) => InventoryItem.fromMap(row)).toList();
  }

  Future<List<InventoryItem>> searchItems(String query) async {
    if (query.trim().isEmpty) return getLocalItems();

    final db = await BillingDatabase.instance.database;
    final q = '%${query.trim().toLowerCase()}%';
    final rows = await db.query(
      'inventory',
      where: 'is_deleted = 0 AND (name_lower LIKE ? OR sku_lower LIKE ? OR category_lower LIKE ?)',
      whereArgs: [q, q, q],
      orderBy: 'name ASC',
    );
    return rows.map((row) => InventoryItem.fromMap(row)).toList();
  }

  // ─── Update ───────────────────────────────────────────────────────────────

  Future<InventoryItem> updateItem(InventoryItem item) async {
    assert(item.id != null, 'Cannot update an item without an id');
    try {
      final toSave = InventoryItem(
        id: item.id,
        name: item.name,
        category: item.category,
        stock: item.stock,
        unit: item.unit,
        purchase: item.purchase,
        selling: item.selling,
        minStock: item.minStock,
        sku: item.sku,
        createdAt: item.createdAt,
        updatedAt: null,
      );

      // Write to Firestore
      await _collection.doc(item.id).set(toSave.toMap());

      // Write to local SQLite
      final db = await BillingDatabase.instance.database;
      await db.insert(
        'inventory',
        {
          'id': toSave.id,
          'name': toSave.name,
          'category': toSave.category,
          'stock': toSave.stock,
          'unit': toSave.unit,
          'purchase': toSave.purchase,
          'selling': toSave.selling,
          'min_stock': toSave.minStock,
          'sku': toSave.sku,
          'created_at': toSave.createdAt.toIso8601String(),
          'sync_status': 'pending',
          'updated_at': DateTime.now().millisecondsSinceEpoch,
          'is_deleted': 0,
          'name_lower': toSave.name.toLowerCase(),
          'sku_lower': toSave.sku.toLowerCase(),
          'category_lower': toSave.category.toLowerCase(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return toSave;
    } catch (e) {
      onWriteError?.call(e.toString());
      rethrow;
    }
  }

  Future<void> updateStock(String id, int newStock) async {
    try {
      final now = DateTime.now();
      // Read item first to compute isLowStock (Fix 1)
      final item = await getItem(id);
      final isLow = item != null ? (newStock <= item.minStock) : false;

      // Update Firestore
      await _collection.doc(id).update({
        'stock': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
        'isLowStock': isLow,
      });

      // Update local SQLite
      final db = await BillingDatabase.instance.database;
      await db.update(
        'inventory',
        {
          'stock': newStock,
          'updated_at': now.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      onWriteError?.call(e.toString());
      rethrow;
    }
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<void> deleteItem(String id) async {
    try {
      // Delete from Firestore
      await _collection.doc(id).delete();

      // Delete from SQLite
      final db = await BillingDatabase.instance.database;
      await db.delete('inventory', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      onWriteError?.call(e.toString());
      rethrow;
    }
  }

  // ─── Sync Logic (Fix 2 & Fix 4) ──────────────────────────────────────────

  Future<int> syncFromFirestore(
      SharedPreferences prefs, {
        void Function(int syncedCount)? onProgress,
      }) async {
    final lastSyncKey = 'inventory_last_sync_$garageId';
    final lastSyncMs = prefs.getInt(lastSyncKey) ?? 0;
    final lastSyncDateTime = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);

    final db = await BillingDatabase.instance.database;
    final isInitialSync = lastSyncMs == 0;

    if (isInitialSync) {
      // Resumable initial sync configuration (Fix 2)
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final syncDateKey = 'inventory_sync_date_$garageId';
      final dailyCountKey = 'inventory_sync_daily_count_$garageId';
      final lastDocIdKey = 'inventory_sync_last_doc_id_$garageId';
      final totalSyncedKey = 'inventory_sync_total_synced_$garageId';

      final savedSyncDate = prefs.getString(syncDateKey) ?? '';
      int dailyCount = 0;
      if (savedSyncDate == todayStr) {
        dailyCount = prefs.getInt(dailyCountKey) ?? 0;
      } else {
        await prefs.setString(syncDateKey, todayStr);
        await prefs.setInt(dailyCountKey, 0);
      }

      int totalSynced = prefs.getInt(totalSyncedKey) ?? 0;
      String lastDocId = prefs.getString(lastDocIdKey) ?? '';

      // Limit per day to prevent Spark ceiling hit (Fix 2)
      const dailyLimit = 40000;
      bool hasMore = true;

      while (hasMore && dailyCount < dailyLimit) {
        Query<Map<String, dynamic>> query = _collection.orderBy(FieldPath.documentId);
        if (lastDocId.isNotEmpty) {
          final lastDocSnap = await _collection.doc(lastDocId).get();
          if (lastDocSnap.exists) {
            query = query.startAfterDocument(lastDocSnap);
          }
        }

        final pageSize = (dailyLimit - dailyCount).clamp(0, 1000);
        if (pageSize <= 0) break;

        final snap = await query.limit(pageSize).get();
        if (snap.docs.isEmpty) {
          hasMore = false;
          break;
        }

        final batch = db.batch();
        for (final doc in snap.docs) {
          final item = InventoryItem.fromMap(doc.data()..['id'] = doc.id);
          _insertItemToBatch(batch, item);
        }

        await batch.commit(noResult: true);

        totalSynced += snap.docs.length;
        dailyCount += snap.docs.length;
        lastDocId = snap.docs.last.id;

        await prefs.setInt(totalSyncedKey, totalSynced);
        await prefs.setInt(dailyCountKey, dailyCount);
        await prefs.setString(lastDocIdKey, lastDocId);

        onProgress?.call(totalSynced);

        if (snap.docs.length < pageSize) {
          hasMore = false;
          break;
        }
      }

      if (!hasMore) {
        // Find maximum updatedAt from local database (Fix 4)
        final maxRow = await db.rawQuery('SELECT MAX(updated_at) as maxVal FROM inventory');
        final maxVal = maxRow.first['maxVal'] as int? ?? 0;
        await prefs.setInt(lastSyncKey, maxVal > 0 ? maxVal : DateTime.now().millisecondsSinceEpoch);

        await prefs.remove(lastDocIdKey);
        await prefs.remove(totalSyncedKey);
        await prefs.remove(dailyCountKey);
        await prefs.remove(syncDateKey);
      }

      return totalSynced;
    } else {
      // Fix 6: One-time repair scan for legacy docs that are missing the
      // 'updatedAt' field entirely. Firestore query filters (isGreaterThan,
      // isEqualTo, isNull, orderBy, etc.) ALL silently exclude documents where
      // the filtered field doesn't exist on the document at all — there is no
      // query that can find them. The only way is a full, unfiltered scan,
      // which we do exactly once (tracked via a prefs flag) and use to
      // backfill 'updatedAt' on Firestore so future delta syncs pick these
      // docs up naturally.
      final repairFlagKey = 'inventory_updatedAt_repaired_$garageId';
      final alreadyRepaired = prefs.getBool(repairFlagKey) ?? false;
      int repairedCount = 0;

      if (!alreadyRepaired) {
        final allSnap = await _collection.get();

        if (allSnap.docs.isNotEmpty) {
          final repairDbBatch = db.batch();
          WriteBatch? fsBatch;
          int fsWrites = 0;

          for (final doc in allSnap.docs) {
            final data = doc.data();

            if (!data.containsKey('updatedAt')) {
              fsBatch ??= _firestore.batch();
              fsBatch.update(doc.reference, {'updatedAt': FieldValue.serverTimestamp()});
              fsWrites++;
            }

            final item = InventoryItem.fromMap({...data, 'id': doc.id});
            _insertItemToBatch(repairDbBatch, item);
            repairedCount++;
          }

          await repairDbBatch.commit(noResult: true);
          if (fsBatch != null && fsWrites > 0) {
            await fsBatch.commit();
          }
        }

        await prefs.setBool(repairFlagKey, true);
      }

      // Subsequent delta sync (Fix 4)
      Query<Map<String, dynamic>> query = _collection.where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSyncDateTime));
      final snap = await query.get();
      if (snap.docs.isEmpty) {
        return repairedCount;
      }

      final batch = db.batch();
      DateTime maxUpdatedAt = lastSyncDateTime;

      for (final doc in snap.docs) {
        final item = InventoryItem.fromMap(doc.data()..['id'] = doc.id);
        _insertItemToBatch(batch, item);

        if (item.updatedAt != null && item.updatedAt!.isAfter(maxUpdatedAt)) {
          maxUpdatedAt = item.updatedAt!;
        }
      }

      await batch.commit(noResult: true);

      // Persist maximum batch-derived updatedAt timestamp (Fix 4)
      await prefs.setInt(lastSyncKey, maxUpdatedAt.millisecondsSinceEpoch);
      return repairedCount + snap.docs.length;
    }
  }

  void _insertItemToBatch(Batch batch, InventoryItem item) {
    batch.insert(
      'inventory',
      {
        'id': item.id,
        'name': item.name,
        'category': item.category,
        'stock': item.stock,
        'unit': item.unit,
        'purchase': item.purchase,
        'selling': item.selling,
        'min_stock': item.minStock,
        'sku': item.sku,
        'created_at': item.createdAt.toIso8601String(),
        'sync_status': 'synced',
        'updated_at': item.updatedAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
        'is_deleted': 0,
        'name_lower': item.name.toLowerCase(),
        'sku_lower': item.sku.toLowerCase(),
        'category_lower': item.category.toLowerCase(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}