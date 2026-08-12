import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/ServiceItem.dart';
import '../local_database/billing_database.dart';
import '../utils/fts_query.dart';

/// Direct Firestore repository for service items, backed by local SQLite cache.
class ServiceRepository {
  ServiceRepository({required this.garageId, this.onWriteError, FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final String garageId;
  final Function(String)? onWriteError;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('garages').doc(garageId).collection('services');

  // ─── Create ───────────────────────────────────────────────────────────────

  Future<ServiceItem> createService(ServiceItem service) async {
    try {
      final docRef = _collection.doc();
      final toSave = ServiceItem(
        id: docRef.id,
        name: service.name,
        category: service.category,
        price: service.price,
        description: service.description,
        createdAt: service.createdAt,
        syncStatus: service.syncStatus,
        updatedAt: null,
        isDeleted: service.isDeleted,
      );

      // Write to Firestore
      await docRef.set(toSave.toMap());

      // Write to SQLite
      final db = await BillingDatabase.instance.database;
      await db.insert(
        'services',
        {
          'id': toSave.id,
          'name': toSave.name,
          'category': toSave.category,
          'price': toSave.price,
          'description': toSave.description,
          'created_at': toSave.createdAt.toIso8601String(),
          'sync_status': 'pending',
          'updated_at': DateTime.now().millisecondsSinceEpoch,
          'is_deleted': 0,
          'name_lower': toSave.name.toLowerCase(),
          'category_lower': toSave.category.toLowerCase(),
          'garage_id': garageId,
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

  Future<ServiceItem?> getItem(String id) async {
    // Read from SQLite first
    final db = await BillingDatabase.instance.database;
    final rows = await db.query('services', where: 'id = ? AND garage_id = ?', whereArgs: [id, garageId]);
    if (rows.isNotEmpty) {
      return ServiceItem.fromMap(rows.first);
    }

    // Fallback to Firestore
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return ServiceItem.fromMap(doc.data()!..['id'] = doc.id);
  }

  Future<ServiceItem?> findByName(String name) async {
    final db = await BillingDatabase.instance.database;
    final rows = await db.query(
      'services',
      where: 'name_lower = ? AND garage_id = ? AND is_deleted = 0',
      whereArgs: [name.trim().toLowerCase(), garageId],
    );
    if (rows.isNotEmpty) {
      return ServiceItem.fromMap(rows.first);
    }
    return null;
  }

  Future<List<ServiceItem>> getLocalItems() async {
    final db = await BillingDatabase.instance.database;
    final rows = await db.query('services', where: 'is_deleted = 0 AND garage_id = ?', whereArgs: [garageId], orderBy: 'name ASC');
    return rows.map((row) => ServiceItem.fromMap(row)).toList();
  }

  Future<List<ServiceItem>> searchItems(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return getLocalItems();

    // 1. Local SQLite search (FTS with LIKE fallback)
    List<ServiceItem> localResults = [];
    final ftsQuery = buildFtsPrefixQuery(query);

    if (BillingDatabase.ftsAvailable && ftsQuery != null) {
      try {
        final db = await BillingDatabase.instance.database;
        final rows = await db.rawQuery('''
          SELECT s.* FROM services s
          JOIN services_fts f ON s.id = f.id
          WHERE services_fts MATCH ? AND f.garage_id = ? AND s.is_deleted = 0
          ORDER BY s.name ASC
          LIMIT 15
        ''', [ftsQuery, garageId]);
        localResults = rows.map((row) => ServiceItem.fromMap(row)).toList();
      } catch (e) {
        print('Local FTS services search failed, falling back to LIKE: $e');
      }
    }

    if (localResults.isEmpty) {
      try {
        final db = await BillingDatabase.instance.database;
        final searchQ = trimmed.toLowerCase();
        final q = '%$searchQ%';
        final rows = await db.query(
          'services',
          where: 'is_deleted = 0 AND garage_id = ? AND (name_lower LIKE ? OR category_lower LIKE ?)',
          whereArgs: [garageId, q, q],
          orderBy: 'name ASC',
          limit: 15,
        );
        localResults = rows.map((row) => ServiceItem.fromMap(row)).toList();
      } catch (e) {
        print('Local LIKE services search failed: $e');
      }
    }

    // Return immediately if local search returned results
    if (localResults.isNotEmpty) {
      return localResults;
    }

    // 2. Remote Firestore search (only if local search returned 0 results)
    try {
      final searchQ = trimmed.toLowerCase();
      final snap = await _collection
          .orderBy('name_lower')
          .startAt([searchQ])
          .endAt([searchQ + '\uf8ff'])
          .limit(15)
          .get();
      return snap.docs
          .map((doc) => ServiceItem.fromMap(doc.data()..['id'] = doc.id))
          .toList();
    } catch (e) {
      print('Firestore services search failed: $e');
      return const [];
    }
  }

  // ─── Update ───────────────────────────────────────────────────────────────

  Future<ServiceItem> updateService(ServiceItem service) async {
    assert(service.id != null, 'Cannot update a service without an id');
    try {
      final toSave = ServiceItem(
        id: service.id,
        name: service.name,
        category: service.category,
        price: service.price,
        description: service.description,
        createdAt: service.createdAt,
        syncStatus: service.syncStatus,
        updatedAt: null,
        isDeleted: service.isDeleted,
      );

      // Write to Firestore
      await _collection.doc(service.id).set(toSave.toMap());

      // Write to local SQLite
      final db = await BillingDatabase.instance.database;
      final existing = await db.query(
        'services',
        columns: ['garage_id'],
        where: 'id = ?',
        whereArgs: [toSave.id],
      );
      if (existing.isNotEmpty) {
        final existingGarageId = existing.first['garage_id'] as String? ?? '';
        if (existingGarageId.isNotEmpty && existingGarageId != garageId) {
          // Do not overwrite other garage's item.
          return toSave;
        }
      }
      await db.insert(
        'services',
        {
          'id': toSave.id,
          'name': toSave.name,
          'category': toSave.category,
          'price': toSave.price,
          'description': toSave.description,
          'created_at': toSave.createdAt.toIso8601String(),
          'sync_status': 'pending',
          'updated_at': DateTime.now().millisecondsSinceEpoch,
          'is_deleted': 0,
          'name_lower': toSave.name.toLowerCase(),
          'category_lower': toSave.category.toLowerCase(),
          'garage_id': garageId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return toSave;
    } catch (e) {
      onWriteError?.call(e.toString());
      rethrow;
    }
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<void> deleteService(String id) async {
    try {
      // Delete from Firestore
      await _collection.doc(id).delete();

      // Delete from SQLite
      final db = await BillingDatabase.instance.database;
      await db.delete('services', where: 'id = ? AND garage_id = ?', whereArgs: [id, garageId]);
    } catch (e) {
      onWriteError?.call(e.toString());
      rethrow;
    }
  }

  // ─── Sync Logic ──────────────────────────────────────────────────────────

  Future<int> syncFromFirestore(
      SharedPreferences prefs, {
        void Function(int syncedCount)? onProgress,
      }) async {
    final lastSyncKey = 'services_last_sync_$garageId';
    final lastSyncMs = prefs.getInt(lastSyncKey) ?? 0;
    final lastSyncDateTime = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);

    final db = await BillingDatabase.instance.database;
    final isInitialSync = lastSyncMs == 0;

    if (isInitialSync) {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final syncDateKey = 'services_sync_date_$garageId';
      final dailyCountKey = 'services_sync_daily_count_$garageId';
      final lastDocIdKey = 'services_sync_last_doc_id_$garageId';
      final totalSyncedKey = 'services_sync_total_synced_$garageId';

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

        final ids = snap.docs.map((d) => d.id).toList();
        final placeholders = List.filled(ids.length, '?').join(',');
        final existingRows = await db.query(
          'services',
          columns: ['id', 'garage_id'],
          where: 'id IN ($placeholders)',
          whereArgs: ids,
        );
        final existingMap = {
          for (final row in existingRows)
            row['id'] as String: row['garage_id'] as String? ?? ''
        };

        final batch = db.batch();
        for (final doc in snap.docs) {
          final existingGarageId = existingMap[doc.id];
          if (existingGarageId != null && existingGarageId.isNotEmpty && existingGarageId != garageId) {
            continue;
          }
          final item = ServiceItem.fromMap(doc.data()..['id'] = doc.id);
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
        final maxRow = await db.rawQuery('SELECT MAX(updated_at) as maxVal FROM services WHERE garage_id = ?', [garageId]);
        final maxVal = maxRow.first['maxVal'] as int? ?? 0;
        await prefs.setInt(lastSyncKey, maxVal > 0 ? maxVal : DateTime.now().millisecondsSinceEpoch);

        await prefs.remove(lastDocIdKey);
        await prefs.remove(totalSyncedKey);
        await prefs.remove(dailyCountKey);
        await prefs.remove(syncDateKey);
      }

      return totalSynced;
    } else {
      final repairFlagKey = 'services_updatedAt_repaired_$garageId';
      final alreadyRepaired = prefs.getBool(repairFlagKey) ?? false;
      int repairedCount = 0;

      if (!alreadyRepaired) {
        final allSnap = await _collection.get();

        if (allSnap.docs.isNotEmpty) {
          final ids = allSnap.docs.map((d) => d.id).toList();
          final placeholders = List.filled(ids.length, '?').join(',');
          final existingRows = await db.query(
            'services',
            columns: ['id', 'garage_id'],
            where: 'id IN ($placeholders)',
            whereArgs: ids,
          );
          final existingMap = {
            for (final row in existingRows)
              row['id'] as String: row['garage_id'] as String? ?? ''
          };

          final repairDbBatch = db.batch();
          WriteBatch? fsBatch;
          int fsWrites = 0;

          for (final doc in allSnap.docs) {
            final existingGarageId = existingMap[doc.id];
            if (existingGarageId != null && existingGarageId.isNotEmpty && existingGarageId != garageId) {
              continue;
            }

            final data = doc.data();

            if (!data.containsKey('updatedAt')) {
              fsBatch ??= _firestore.batch();
              fsBatch.update(doc.reference, {'updatedAt': FieldValue.serverTimestamp()});
              fsWrites++;
            }

            final item = ServiceItem.fromMap({...data, 'id': doc.id});
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

      Query<Map<String, dynamic>> query = _collection.where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSyncDateTime));
      final snap = await query.get();
      int deltaCount = 0;
      if (snap.docs.isNotEmpty) {
        final ids = snap.docs.map((d) => d.id).toList();
        final placeholders = List.filled(ids.length, '?').join(',');
        final existingRows = await db.query(
          'services',
          columns: ['id', 'garage_id'],
          where: 'id IN ($placeholders)',
          whereArgs: ids,
        );
        final existingMap = {
          for (final row in existingRows)
            row['id'] as String: row['garage_id'] as String? ?? ''
        };

        final batch = db.batch();
        DateTime maxUpdatedAt = lastSyncDateTime;

        for (final doc in snap.docs) {
          final existingGarageId = existingMap[doc.id];
          if (existingGarageId != null && existingGarageId.isNotEmpty && existingGarageId != garageId) {
            continue;
          }
          final item = ServiceItem.fromMap(doc.data()..['id'] = doc.id);
          _insertItemToBatch(batch, item);
          deltaCount++;

          if (item.updatedAt != null && item.updatedAt!.isAfter(maxUpdatedAt)) {
            maxUpdatedAt = item.updatedAt!;
          }
        }

        await batch.commit(noResult: true);
        await prefs.setInt(lastSyncKey, maxUpdatedAt.millisecondsSinceEpoch);
      }

      // Periodic orphan check for services
      int orphanSyncedCount = 0;
      final now = DateTime.now();
      final lastOrphanCheckKey = 'services_last_orphan_check_$garageId';
      final lastOrphanCheckMs = prefs.getInt(lastOrphanCheckKey) ?? 0;

      if (now.millisecondsSinceEpoch - lastOrphanCheckMs >= 24 * 60 * 60 * 1000) {
        final orphanSnap = await _collection.get();
        if (orphanSnap.docs.isNotEmpty) {
          final ids = orphanSnap.docs.map((d) => d.id).toList();
          final placeholders = List.filled(ids.length, '?').join(',');
          final existingRows = await db.query(
            'services',
            columns: ['id', 'garage_id'],
            where: 'id IN ($placeholders)',
            whereArgs: ids,
          );
          final existingMap = {
            for (final row in existingRows)
              row['id'] as String: row['garage_id'] as String? ?? ''
          };

          final dbBatch = db.batch();
          WriteBatch? fsBatch;
          int fsWrites = 0;

          for (final doc in orphanSnap.docs) {
            final existingGarageId = existingMap[doc.id];
            if (existingGarageId != null && existingGarageId.isNotEmpty && existingGarageId != garageId) {
              continue;
            }

            final data = doc.data();
            if (!data.containsKey('updatedAt')) {
              fsBatch ??= _firestore.batch();
              fsBatch.update(doc.reference, {'updatedAt': FieldValue.serverTimestamp()});
              fsWrites++;
              if (fsWrites >= 500) {
                await fsBatch.commit();
                fsBatch = _firestore.batch();
                fsWrites = 0;
              }
            }

            final item = ServiceItem.fromMap({...data, 'id': doc.id});
            _insertItemToBatch(dbBatch, item);
            orphanSyncedCount++;
          }

          if (fsBatch != null && fsWrites > 0) {
            await fsBatch.commit();
          }
          await dbBatch.commit(noResult: true);
        }
        await prefs.setInt(lastOrphanCheckKey, now.millisecondsSinceEpoch);
      }

      return repairedCount + deltaCount + orphanSyncedCount;
    }
  }

  void _insertItemToBatch(Batch batch, ServiceItem item) {
    batch.insert(
      'services',
      {
        'id': item.id,
        'name': item.name,
        'category': item.category,
        'price': item.price,
        'description': item.description,
        'created_at': item.createdAt.toIso8601String(),
        'sync_status': 'synced',
        'updated_at': item.updatedAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
        'is_deleted': 0,
        'name_lower': item.name.toLowerCase(),
        'category_lower': item.category.toLowerCase(),
        'garage_id': garageId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
