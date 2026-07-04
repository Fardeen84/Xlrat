
import '../local_database/billing_database.dart';
import '../models/billing_model/BillingCustomer.dart';
import '../models/billing_model/BillingVehicle.dart';
import '../models/billing_model/InvoiceItem.dart';
import '../models/billing_model/invoice.dart';

/// Central repository for invoice operations.
/// Handles atomic invoice + items saves, eager-loading of related entities,
/// search, and deletion.
class BillingRepository {
  BillingRepository(this._db, {this.onInvoiceCreated});

  final BillingDatabase _db;
  final Function(Invoice)? onInvoiceCreated;

  static const _invoicesTable = 'billing_invoices';
  static const _itemsTable = 'billing_invoice_items';
  static const _customersTable = 'billing_customers';
  static const _vehiclesTable = 'billing_vehicles';

  // ─── Create ───────────────────────────────────────────────────────────────

  /// Saves the invoice header and all its items in a single transaction.
  /// Returns the saved [Invoice] with id and item ids populated.
  Future<Invoice> createInvoice(Invoice invoice, List<InvoiceItem> items) async {
    final db = await _db.database;
    final invoiceNumber = invoice.invoiceNumber.isEmpty
        ? await _db.nextInvoiceNumber()
        : invoice.invoiceNumber;

    final savedInvoice = await db.transaction((txn) async {
      final invoiceMap = invoice
          .copyWith(invoiceNumber: invoiceNumber)
          .toMap()
        ..remove('id');

      final invoiceId = await txn.insert(_invoicesTable, invoiceMap);

      final savedItems = <InvoiceItem>[];
      for (final item in items) {
        final itemMap = item
            .copyWith(invoiceId: invoiceId)
            .toMap()
          ..remove('id');
        final itemId = await txn.insert(_itemsTable, itemMap);
        savedItems.add(item.copyWith(id: itemId, invoiceId: invoiceId));
      }

      return invoice.copyWith(
        id: invoiceId,
        invoiceNumber: invoiceNumber,
        items: savedItems,
      );
    });

    onInvoiceCreated?.call(savedInvoice);

    return savedInvoice;
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  /// Fetches a single invoice with customer, vehicle, and items joined.
  Future<Invoice?> getInvoice(int id) async {
    final db = await _db.database;
    final rows =
    await db.query(_invoicesTable, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _hydrateInvoice(rows.first);
  }

  /// Returns all invoices ordered newest-first, with items joined.
  Future<List<Invoice>> getInvoices({int? limit}) async {
    final db = await _db.database;
    final rows = await db.query(
      _invoicesTable,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return Future.wait(rows.map(_hydrateInvoice));
  }

  /// Returns all invoices for a customer, ordered newest-first, with items joined.
  Future<List<Invoice>> getInvoicesByCustomer(int customerId) async {
    final db = await _db.database;
    final rows = await db.query(
      _invoicesTable,
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'invoice_date DESC',
    );
    return Future.wait(rows.map(_hydrateInvoice));
  }

  /// Full-text search across invoice number, customer name, vehicle number.
  Future<List<Invoice>> searchInvoices(String query) async {
    if (query.trim().isEmpty) return getInvoices();
    final db = await _db.database;
    final q = '%${query.trim()}%';

    // Join customers to allow search on name
    final rows = await db.rawQuery('''
      SELECT i.*
      FROM $_invoicesTable i
      LEFT JOIN $_customersTable c ON c.id = i.customer_id
      LEFT JOIN $_vehiclesTable  v ON v.id = i.vehicle_id
      WHERE i.invoice_number LIKE ?
         OR c.name           LIKE ?
         OR c.mobile         LIKE ?
         OR v.vehicle_number LIKE ?
      ORDER BY i.created_at DESC
    ''', [q, q, q, q]);

    return Future.wait(rows.map(_hydrateInvoice));
  }

  /// Returns invoices filtered by [PaymentStatus].
  Future<List<Invoice>> getInvoicesByStatus(PaymentStatus status) async {
    final db = await _db.database;
    final rows = await db.query(
      _invoicesTable,
      where: 'payment_status = ?',
      whereArgs: [status.name],
      orderBy: 'created_at DESC',
    );
    return Future.wait(rows.map(_hydrateInvoice));
  }

  /// Today's total sales amount and invoice count.
  Future<({double total, int count})> getTodaySummary() async {
    final db = await _db.database;
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final rows = await db.rawQuery('''
      SELECT COUNT(*) as cnt, COALESCE(SUM(grand_total), 0) as total
      FROM $_invoicesTable
      WHERE DATE(invoice_date) = ?
    ''', [dateStr]);

    final row = rows.first;
    return (
    total: (row['total'] as num?)?.toDouble() ?? 0,
    count: (row['cnt'] as int?) ?? 0,
    );
  }

  // ─── Update ───────────────────────────────────────────────────────────────

  /// Replaces invoice header and all items atomically.
  Future<Invoice> updateInvoice(Invoice invoice, List<InvoiceItem> items) async {
    assert(invoice.id != null, 'Cannot update an invoice without an id');
    final db = await _db.database;

    return db.transaction((txn) async {
      await txn.update(
        _invoicesTable,
        invoice.toMap(),
        where: 'id = ?',
        whereArgs: [invoice.id],
      );

      // Replace all existing items
      await txn.delete(
        _itemsTable,
        where: 'invoice_id = ?',
        whereArgs: [invoice.id],
      );

      final savedItems = <InvoiceItem>[];
      for (final item in items) {
        final itemMap = item
            .copyWith(invoiceId: invoice.id)
            .toMap()
          ..remove('id');
        final itemId = await txn.insert(_itemsTable, itemMap);
        savedItems.add(item.copyWith(id: itemId, invoiceId: invoice.id));
      }

      return invoice.copyWith(items: savedItems);
    });
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  /// Deletes the invoice; items are cascade-deleted by the schema.
  Future<void> deleteInvoice(int id) async {
    final db = await _db.database;
    await db.delete(_invoicesTable, where: 'id = ?', whereArgs: [id]);
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  /// Eager-loads customer, vehicle, and items for a raw invoice row.
  Future<Invoice> _hydrateInvoice(Map<String, dynamic> row) async {
    final db = await _db.database;
    final invoice = Invoice.fromMap(row);

    // Customer
    BillingCustomer? customer;
    final custRows = await db.query(
      _customersTable,
      where: 'id = ?',
      whereArgs: [invoice.customerId],
    );
    if (custRows.isNotEmpty) {
      customer = BillingCustomer.fromMap(custRows.first);
    }

    // Vehicle (optional)
    BillingVehicle? vehicle;
    if (invoice.vehicleId != null) {
      final vehRows = await db.query(
        _vehiclesTable,
        where: 'id = ?',
        whereArgs: [invoice.vehicleId],
      );
      if (vehRows.isNotEmpty) {
        vehicle = BillingVehicle.fromMap(vehRows.first);
      }
    }

    // Items
    final itemRows = await db.query(
      _itemsTable,
      where: 'invoice_id = ?',
      whereArgs: [invoice.id],
      orderBy: 'id ASC',
    );
    final items = itemRows.map(InvoiceItem.fromMap).toList();

    return invoice.copyWith(
      customer: customer,
      vehicle: vehicle,
      items: items,
    );
  }
}
