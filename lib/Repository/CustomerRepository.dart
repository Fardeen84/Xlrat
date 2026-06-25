
import '../Local Database/billing_database.dart';
import '../Models/Billing model/BillingCustomer.dart';

/// All database access for billing customers goes through this class.
/// UI and Providers never touch the DB directly.
class CustomerRepository {
  CustomerRepository(this._db);

  final BillingDatabase _db;

  static const _table = 'billing_customers';

  // ─── Create ───────────────────────────────────────────────────────────────

  Future<BillingCustomer> createCustomer(BillingCustomer customer) async {
    final db = await _db.database;
    final map = customer.toMap()
      ..remove('id'); // let SQLite assign id
    final id = await db.insert(_table, map);
    return customer.copyWith(id: id);
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  Future<BillingCustomer?> getCustomer(int id) async {
    final db = await _db.database;
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return BillingCustomer.fromMap(rows.first);
  }

  Future<List<BillingCustomer>> getCustomers() async {
    final db = await _db.database;
    final rows = await db.query(_table, orderBy: 'name ASC');
    return rows.map(BillingCustomer.fromMap).toList();
  }

  Future<List<BillingCustomer>> searchCustomers(String query) async {
    if (query.trim().isEmpty) return getCustomers();
    final db = await _db.database;
    final q = '%${query.trim()}%';
    final rows = await db.query(
      _table,
      where: 'name LIKE ? OR mobile LIKE ? OR email LIKE ?',
      whereArgs: [q, q, q],
      orderBy: 'name ASC',
    );
    return rows.map(BillingCustomer.fromMap).toList();
  }

  // ─── Update ───────────────────────────────────────────────────────────────

  Future<BillingCustomer> updateCustomer(BillingCustomer customer) async {
    assert(customer.id != null, 'Cannot update a customer without an id');
    final db = await _db.database;
    await db.update(
      _table,
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
    return customer;
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<void> deleteCustomer(int id) async {
    final db = await _db.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
