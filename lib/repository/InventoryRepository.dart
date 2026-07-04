import '../local_database/billing_database.dart';
import '../models/InventoryItem.dart';

class InventoryRepository {
  InventoryRepository(this._db);

  final BillingDatabase _db;

  static const _table = 'inventory';

  // ─── Create ───────────────────────────────────────────────────────────────

  Future<InventoryItem> createItem(InventoryItem item) async {
    final db = await _db.database;
    final map = item.toMap()..remove('id');
    final id = await db.insert(_table, map);
    return item.copyWith(id: id);
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  Future<InventoryItem?> getItem(int id) async {
    final db = await _db.database;
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return InventoryItem.fromMap(rows.first);
  }

  Future<List<InventoryItem>> getAllItems() async {
    final db = await _db.database;
    final rows = await db.query(_table, orderBy: 'name ASC');
    return rows.map(InventoryItem.fromMap).toList();
  }

  Future<List<InventoryItem>> searchItems(String query) async {
    if (query.trim().isEmpty) return getAllItems();
    final db = await _db.database;
    final q = '%${query.trim()}%';
    final rows = await db.query(
      _table,
      where: 'name LIKE ? OR sku LIKE ? OR category LIKE ?',
      whereArgs: [q, q, q],
      orderBy: 'name ASC',
    );
    return rows.map(InventoryItem.fromMap).toList();
  }

  // ─── Update ───────────────────────────────────────────────────────────────

  Future<InventoryItem> updateItem(InventoryItem item) async {
    assert(item.id != null, 'Cannot update an item without an id');
    final db = await _db.database;
    await db.update(
      _table,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
    return item;
  }

  Future<void> updateStock(int id, int newStock) async {
    final db = await _db.database;
    await db.update(
      _table,
      {'stock': newStock},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<void> deleteItem(int id) async {
    final db = await _db.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
