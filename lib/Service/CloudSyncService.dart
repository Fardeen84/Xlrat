// lib/providers/CloudSyncService.dart
import 'package:sqflite/sqflite.dart';
import '../core/FirestoreRestService.dart';
import '../local_database/billing_database.dart';

/// Service to handle remote sync of billing invoices to/from Firestore.
/// Paths are namespaced by the unique [garageId] (e.g. `garages/{garageId}/invoices/...`).
/// NOTE: Existing local dev data previously pushed under the hardcoded 'default_garage' namespace
/// will NOT be migrated to the new scoped paths.
class CloudSyncService {
  CloudSyncService(this._db, this._firestore, this._garageId);

  final BillingDatabase _db;
  final FirestoreRestService _firestore;
  final String _garageId;

  Future<void> pushPendingInvoices() async {
    final db = await _db.database;
    final rows = await db.query('billing_invoices', where: "sync_status = 'pending'");
    for (final row in rows) {
      try {
        await _firestore.setDocument('garages/$_garageId/invoices/${row['id']}', row);
        await db.update('billing_invoices', {'sync_status': 'synced'},
            where: 'id = ?', whereArgs: [row['id']]);
      } catch (e) {
        print('Sync failed for invoice ${row['id']}: $e'); // internet nahi hoga to yahi fail hoga, chalta rahega
      }
    }
  }

  Future<void> pullRemoteInvoices() async {
    try {
      final remote = await _firestore.listCollection('garages/$_garageId/invoices');
      final db = await _db.database;
      for (final doc in remote) {
        doc.remove('_id');
        await db.insert('billing_invoices', doc, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e) {
      print('Pull failed: $e');
    }
  }
}