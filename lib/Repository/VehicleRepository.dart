// lib/billing/repositories/vehicle_repository.dart

import '../Local Database/billing_database.dart';
import '../Models/Billing model/BillingVehicle.dart';

/// All database access for billing vehicles goes through this class.
class VehicleRepository {
  VehicleRepository(this._db);

  final BillingDatabase _db;

  static const _table = 'billing_vehicles';

  // ─── Create ───────────────────────────────────────────────────────────────

  Future<BillingVehicle> createVehicle(BillingVehicle vehicle) async {
    final db = await _db.database;
    final map = vehicle.toMap()..remove('id');
    final id = await db.insert(_table, map);
    return vehicle.copyWith(id: id);
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  Future<BillingVehicle?> getVehicle(int id) async {
    final db = await _db.database;
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return BillingVehicle.fromMap(rows.first);
  }

  /// All vehicles belonging to a customer.
  Future<List<BillingVehicle>> getVehiclesForCustomer(int customerId) async {
    final db = await _db.database;
    final rows = await db.query(
      _table,
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'vehicle_number ASC',
    );
    return rows.map(BillingVehicle.fromMap).toList();
  }

  Future<List<BillingVehicle>> getAllVehicles() async {
    final db = await _db.database;
    final rows = await db.query(_table, orderBy: 'vehicle_number ASC');
    return rows.map(BillingVehicle.fromMap).toList();
  }

  Future<List<BillingVehicle>> searchVehicles(String query) async {
    if (query.trim().isEmpty) return getAllVehicles();
    final db = await _db.database;
    final q = '%${query.trim()}%';
    final rows = await db.query(
      _table,
      where:
      'vehicle_number LIKE ? OR vehicle_brand LIKE ? OR vehicle_model LIKE ?',
      whereArgs: [q, q, q],
      orderBy: 'vehicle_number ASC',
    );
    return rows.map(BillingVehicle.fromMap).toList();
  }

  // ─── Update ───────────────────────────────────────────────────────────────

  Future<BillingVehicle> updateVehicle(BillingVehicle vehicle) async {
    assert(vehicle.id != null, 'Cannot update a vehicle without an id');
    final db = await _db.database;
    await db.update(
      _table,
      vehicle.toMap(),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
    return vehicle;
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<void> deleteVehicle(int id) async {
    final db = await _db.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
