
import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class BillingDatabase {
  BillingDatabase._();
  static final BillingDatabase instance = BillingDatabase._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  // ─── Init ──────────────────────────────────────────────────────────────────

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'xlrat_billing.db');

    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(_sqlCustomers);
    await db.execute(_sqlVehicles);
    await db.execute(_sqlInvoices);
    await db.execute(_sqlInvoiceItems);
    await db.execute(_sqlInvoiceCounter);
    // Seed invoice counter
    await db.insert('invoice_counter', {'id': 1, 'last_number': 0});
  }

  // ─── DDL ──────────────────────────────────────────────────────────────────

  static const _sqlCustomers = '''
    CREATE TABLE billing_customers (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      name        TEXT    NOT NULL,
      mobile      TEXT    NOT NULL,
      email       TEXT    NOT NULL DEFAULT '',
      address     TEXT    NOT NULL DEFAULT '',
      gst_number  TEXT    NOT NULL DEFAULT '',
      created_at  TEXT    NOT NULL
    )
  ''';

  static const _sqlVehicles = '''
    CREATE TABLE billing_vehicles (
      id              INTEGER PRIMARY KEY AUTOINCREMENT,
      customer_id     INTEGER NOT NULL REFERENCES billing_customers(id) ON DELETE CASCADE,
      vehicle_number  TEXT    NOT NULL,
      vehicle_brand   TEXT    NOT NULL DEFAULT '',
      vehicle_model   TEXT    NOT NULL DEFAULT '',
      fuel_type       TEXT    NOT NULL DEFAULT '',
      engine_number   TEXT    NOT NULL DEFAULT '',
      chassis_number  TEXT    NOT NULL DEFAULT '',
      created_at      TEXT    NOT NULL
    )
  ''';

  static const _sqlInvoices = '''
    CREATE TABLE billing_invoices (
      id              INTEGER PRIMARY KEY AUTOINCREMENT,
      invoice_number  TEXT    NOT NULL UNIQUE,
      customer_id     INTEGER NOT NULL REFERENCES billing_customers(id),
      vehicle_id      INTEGER REFERENCES billing_vehicles(id),
      invoice_date    TEXT    NOT NULL,
      sub_total       REAL    NOT NULL DEFAULT 0,
      discount        REAL    NOT NULL DEFAULT 0,
      gst             REAL    NOT NULL DEFAULT 0,
      grand_total     REAL    NOT NULL DEFAULT 0,
      payment_status  TEXT    NOT NULL DEFAULT 'pending',
      payment_method  TEXT    NOT NULL DEFAULT 'cash',
      notes           TEXT    NOT NULL DEFAULT '',
      created_at      TEXT    NOT NULL
    )
  ''';

  // productId is nullable — allows future Inventory linkage without migration.
  static const _sqlInvoiceItems = '''
    CREATE TABLE billing_invoice_items (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      invoice_id  INTEGER NOT NULL REFERENCES billing_invoices(id) ON DELETE CASCADE,
      product_id  INTEGER,
      item_name   TEXT    NOT NULL,
      quantity    REAL    NOT NULL DEFAULT 1,
      unit        TEXT    NOT NULL DEFAULT 'pcs',
      price       REAL    NOT NULL DEFAULT 0,
      total       REAL    NOT NULL DEFAULT 0,
      created_at  TEXT    NOT NULL
    )
  ''';

  // Single-row table to track auto-increment invoice number (INV-000001 …)
  static const _sqlInvoiceCounter = '''
    CREATE TABLE invoice_counter (
      id           INTEGER PRIMARY KEY,
      last_number  INTEGER NOT NULL DEFAULT 0
    )
  ''';

  // ─── Invoice Number Generator ──────────────────────────────────────────────

  /// Atomically increments the counter and returns the next INV-XXXXXX string.
  Future<String> nextInvoiceNumber() async {
    final db = await database;
    return db.transaction<String>((txn) async {
      final rows = await txn.query('invoice_counter', where: 'id = 1');
      final last = (rows.first['last_number'] as int?) ?? 0;
      final next = last + 1;
      await txn.update(
        'invoice_counter',
        {'last_number': next},
        where: 'id = 1',
      );
      return 'INV-${next.toString().padLeft(6, '0')}';
    });
  }

  // ─── Close ────────────────────────────────────────────────────────────────

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
