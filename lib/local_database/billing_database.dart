
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

  // Future<Database> _initDb() async {
  //   final dbPath = await getDatabasesPath();
  //   final path = join(dbPath, 'xlrat_billing.db');
  //
  //   return openDatabase(
  //     path,
  //     version: 1,
  //     onConfigure: (db) async {
  //       await db.execute('PRAGMA foreign_keys = ON');
  //     },
  //     onCreate: _onCreate,
  //   );
  // }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'xlrat_billing.db');

    return openDatabase(
      path,
      version: 4,   // 3 se 4 kiya for inventory
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              "ALTER TABLE billing_invoices ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'pending'"
          );
        }
        if (oldVersion < 3) {
          await db.execute(_sqlJobs);
          await _seedMockJobs(db);
        }
        if (oldVersion < 4) {
          await db.execute(_sqlInventory);
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(_sqlCustomers);
    await db.execute(_sqlVehicles);
    await db.execute(_sqlInvoices);
    await db.execute(_sqlInvoiceItems);
    await db.execute(_sqlInvoiceCounter);
    await db.execute(_sqlJobs);
    await db.execute(_sqlInventory);
    // Seed invoice counter
    await db.insert('invoice_counter', {'id': 1, 'last_number': 0});
    // Seed mock jobs
    await _seedMockJobs(db);
  }

  // ─── DDL ──────────────────────────────────────────────────────────────────

  static const _sqlInventory = '''
    CREATE TABLE inventory (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      name        TEXT    NOT NULL,
      category    TEXT    NOT NULL DEFAULT '',
      stock       INTEGER NOT NULL DEFAULT 0,
      unit        TEXT    NOT NULL DEFAULT 'pcs',
      purchase    INTEGER NOT NULL DEFAULT 0,
      selling     INTEGER NOT NULL DEFAULT 0,
      min_stock   INTEGER NOT NULL DEFAULT 0,
      sku         TEXT    NOT NULL DEFAULT '',
      created_at  TEXT    NOT NULL
    )
  ''';

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
      sync_status     TEXT    NOT NULL DEFAULT 'pending',
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

  static const _sqlInvoiceCounter = '''
    CREATE TABLE invoice_counter (
      id           INTEGER PRIMARY KEY,
      last_number  INTEGER NOT NULL DEFAULT 0
    )
  ''';

  static const _sqlJobs = '''
    CREATE TABLE jobs (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      job_number    TEXT    NOT NULL,
      customer      TEXT    NOT NULL,
      vehicle       TEXT    NOT NULL,
      vehicleType   TEXT    NOT NULL,
      brand         TEXT    NOT NULL DEFAULT '',
      complaint     TEXT    NOT NULL DEFAULT '',
      mechanic      TEXT    NOT NULL DEFAULT '',
      status        TEXT    NOT NULL DEFAULT 'pending',
      date          TEXT    NOT NULL,
      amount        INTEGER NOT NULL DEFAULT 0
    )
  ''';

  Future<void> _seedMockJobs(Database db) async {
    final mockJobs = [
      {
        'job_number': 'JC-2024-0156',
        'customer': 'Rajesh Kumar',
        'vehicle': 'MH12 AB 1234',
        'vehicleType': 'car',
        'brand': 'Maruti Swift',
        'complaint': 'Engine noise, oil leak',
        'mechanic': 'Suresh K.',
        'status': 'in-progress',
        'date': '23 Jun 2024',
        'amount': 8500
      },
      {
        'job_number': 'JC-2024-0155',
        'customer': 'Priya Sharma',
        'vehicle': 'MH12 CD 5678',
        'vehicleType': 'bike',
        'brand': 'Honda Activa',
        'complaint': 'Brake service, tyre change',
        'mechanic': 'Ramesh V.',
        'status': 'pending',
        'date': '23 Jun 2024',
        'amount': 3200
      },
      {
        'job_number': 'JC-2024-0154',
        'customer': 'Mohammed Irfan',
        'vehicle': 'MH14 EF 9012',
        'vehicleType': 'car',
        'brand': 'Toyota Innova',
        'complaint': 'AC not working, full service',
        'mechanic': 'Suresh K.',
        'status': 'completed',
        'date': '22 Jun 2024',
        'amount': 14200
      },
      {
        'job_number': 'JC-2024-0153',
        'customer': 'Sunita Patel',
        'vehicle': 'MH12 GH 3456',
        'vehicleType': 'bike',
        'brand': 'Bajaj Pulsar',
        'complaint': 'Starting problem',
        'mechanic': 'Kiran M.',
        'status': 'completed',
        'date': '22 Jun 2024',
        'amount': 1800
      },
      {
        'job_number': 'JC-2024-0152',
        'customer': 'Arun Nair',
        'vehicle': 'MH14 IJ 7890',
        'vehicleType': 'car',
        'brand': 'Hyundai i20',
        'complaint': 'Clutch replacement, wheel alignment',
        'mechanic': 'Ramesh V.',
        'status': 'in-progress',
        'date': '21 Jun 2024',
        'amount': 9800
      },
    ];

    for (final job in mockJobs) {
      await db.insert('jobs', job);
    }
  }

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
