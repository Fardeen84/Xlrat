import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BillingDatabase {
  BillingDatabase._();
  static final BillingDatabase instance = BillingDatabase._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    await _runOneTimeStaleSyncCleanup();
    return _db!;
  }

  Future<void> _runOneTimeStaleSyncCleanup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const doneFlagKey = 'stale_inventory_sync_cleanup_v1_done';
      if (prefs.getBool(doneFlagKey) == true) return;

      final staleSyncKeys = prefs.getKeys().where((k) =>
          k.startsWith('inventory_last_sync_') ||
          k.startsWith('inventory_sync_date_') ||
          k.startsWith('inventory_sync_daily_count_') ||
          k.startsWith('inventory_sync_last_doc_id_') ||
          k.startsWith('inventory_sync_total_synced_') ||
          k.startsWith('secondhand_last_sync_') ||
          k.startsWith('secondhand_sync_date_') ||
          k.startsWith('secondhand_sync_daily_count_') ||
          k.startsWith('secondhand_sync_last_doc_id_') ||
          k.startsWith('secondhand_sync_total_synced_'));
      for (final key in staleSyncKeys.toList()) {
        await prefs.remove(key);
      }
      await prefs.setBool(doneFlagKey, true);
    } catch (_) {
      // Non-fatal.
    }
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
      version:
          11, // 10 -> 11: Added garage_id column, indexes & scoping for inventory and secondhand_inventory
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE billing_invoices ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'pending'",
          );
        }
        if (oldVersion < 3) {
          await db.execute(_sqlJobs);
          //await _seedMockJobs(db);
        }
        if (oldVersion < 4) {
          await db.execute(_sqlInventory);
        }
        if (oldVersion < 5) {
          await db.execute("ALTER TABLE jobs ADD COLUMN customer_id INTEGER");
          await db.execute("ALTER TABLE jobs ADD COLUMN vehicle_id INTEGER");
        }
        if (oldVersion < 6) {
          // Add columns to billing_customers
          await db.execute(
            "ALTER TABLE billing_customers ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'pending'",
          );
          await db.execute(
            "ALTER TABLE billing_customers ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0",
          );
          await db.execute(
            "ALTER TABLE billing_customers ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0",
          );

          // Add columns to billing_vehicles
          await db.execute(
            "ALTER TABLE billing_vehicles ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'pending'",
          );
          await db.execute(
            "ALTER TABLE billing_vehicles ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0",
          );
          await db.execute(
            "ALTER TABLE billing_vehicles ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0",
          );

          // Add columns to jobs
          await db.execute(
            "ALTER TABLE jobs ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'pending'",
          );
          await db.execute(
            "ALTER TABLE jobs ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0",
          );
          await db.execute(
            "ALTER TABLE jobs ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0",
          );

          // Add columns to inventory
          await db.execute(
            "ALTER TABLE inventory ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'pending'",
          );
          await db.execute(
            "ALTER TABLE inventory ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0",
          );
          await db.execute(
            "ALTER TABLE inventory ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0",
          );

          // Add columns to billing_invoices (which already has sync_status, just add updated_at and is_deleted)
          await db.execute(
            "ALTER TABLE billing_invoices ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0",
          );
          await db.execute(
            "ALTER TABLE billing_invoices ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0",
          );
        }
        if (oldVersion < 7) {
          await db.execute(
            "ALTER TABLE jobs ADD COLUMN job_type TEXT NOT NULL DEFAULT 'vehicle'",
          );
          await db.execute(
            "ALTER TABLE jobs ADD COLUMN item_name TEXT NOT NULL DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE jobs ADD COLUMN item_description TEXT NOT NULL DEFAULT ''",
          );
        }
        if (oldVersion < 8) {
          await db.execute(_sqlMechanics);
        }
        if (oldVersion < 9) {
          await db.execute(_sqlSecondHandInventory);
          await db.execute(
            "ALTER TABLE billing_invoice_items ADD COLUMN product_source TEXT NOT NULL DEFAULT 'inventory'",
          );
        }
        if (oldVersion < 10) {
          await db.execute("DROP TABLE IF EXISTS inventory");
          await db.execute("DROP TABLE IF EXISTS secondhand_inventory");
          await db.execute(_sqlInventory);
          await db.execute(_sqlSecondHandInventory);
          await db.execute("CREATE INDEX IF NOT EXISTS idx_inventory_search ON inventory(name_lower, sku_lower, category_lower)");
          await db.execute("CREATE INDEX IF NOT EXISTS idx_secondhand_search ON secondhand_inventory(name_lower, sku_lower, category_lower)");

          try {
            final prefs = await SharedPreferences.getInstance();
            final staleSyncKeys = prefs.getKeys().where((k) =>
                k.startsWith('inventory_last_sync_') ||
                k.startsWith('inventory_sync_date_') ||
                k.startsWith('inventory_sync_daily_count_') ||
                k.startsWith('inventory_sync_last_doc_id_') ||
                k.startsWith('inventory_sync_total_synced_') ||
                k.startsWith('secondhand_last_sync_') ||
                k.startsWith('secondhand_sync_date_') ||
                k.startsWith('secondhand_sync_daily_count_') ||
                k.startsWith('secondhand_sync_last_doc_id_') ||
                k.startsWith('secondhand_sync_total_synced_'));
            for (final key in staleSyncKeys.toList()) {
              await prefs.remove(key);
            }
          } catch (_) {
            // Non-fatal — don't block the DB migration if prefs aren't reachable.
          }
        }
        if (oldVersion < 11) {
          await db.execute(
            "ALTER TABLE inventory ADD COLUMN garage_id TEXT NOT NULL DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE secondhand_inventory ADD COLUMN garage_id TEXT NOT NULL DEFAULT ''",
          );
          await db.execute(
            "CREATE INDEX IF NOT EXISTS idx_inventory_garage ON inventory(garage_id)",
          );
          await db.execute(
            "CREATE INDEX IF NOT EXISTS idx_secondhand_garage ON secondhand_inventory(garage_id)",
          );

          try {
            final prefs = await SharedPreferences.getInstance();
            final garageId = prefs.getString('garage_id') ?? '';
            if (garageId.isNotEmpty) {
              await db.update('inventory', {'garage_id': garageId});
              await db.update('secondhand_inventory', {'garage_id': garageId});
            }
          } catch (_) {
            // Non-fatal
          }
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
    await db.execute(_sqlMechanics);
    await db.execute(_sqlSecondHandInventory);
    await db.execute("CREATE INDEX IF NOT EXISTS idx_inventory_search ON inventory(name_lower, sku_lower, category_lower)");
    await db.execute("CREATE INDEX IF NOT EXISTS idx_secondhand_search ON secondhand_inventory(name_lower, sku_lower, category_lower)");
    await db.execute("CREATE INDEX IF NOT EXISTS idx_inventory_garage ON inventory(garage_id)");
    await db.execute("CREATE INDEX IF NOT EXISTS idx_secondhand_garage ON secondhand_inventory(garage_id)");
    // Seed invoice counter
    await db.insert('invoice_counter', {'id': 1, 'last_number': 0});
    // Seed mock jobs
    //await _seedMockJobs(db);
  }

  // ─── DDL ──────────────────────────────────────────────────────────────────

  // NOTE (Clarification A): The primary key remains id-only (not composite with garage_id)
  // because SQLite does not support changing primary key constraints via ALTER TABLE.
  // Consequently, colliding IDs across different garages would overwrite each other in the DB
  // if ConflictAlgorithm.replace is triggered. However, since Firestore document IDs are
  // globally unique random 20-character strings, this risk is negligible.
  // Application-level scoping (WHERE garage_id = ?) prevents reading across garages.
  static const _sqlInventory = '''
    CREATE TABLE inventory (
      id          TEXT    PRIMARY KEY,
      name        TEXT    NOT NULL,
      category    TEXT    NOT NULL DEFAULT '',
      stock       INTEGER NOT NULL DEFAULT 0,
      unit        TEXT    NOT NULL DEFAULT 'pcs',
      purchase    INTEGER NOT NULL DEFAULT 0,
      selling     INTEGER NOT NULL DEFAULT 0,
      min_stock   INTEGER NOT NULL DEFAULT 0,
      sku         TEXT    NOT NULL DEFAULT '',
      created_at  TEXT    NOT NULL,
      sync_status TEXT    NOT NULL DEFAULT 'pending',
      updated_at  INTEGER NOT NULL DEFAULT 0,
      is_deleted  INTEGER NOT NULL DEFAULT 0,
      name_lower  TEXT,
      sku_lower   TEXT,
      category_lower TEXT,
      garage_id   TEXT    NOT NULL DEFAULT ''
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
      created_at  TEXT    NOT NULL,
      sync_status TEXT    NOT NULL DEFAULT 'pending',
      updated_at  INTEGER NOT NULL DEFAULT 0,
      is_deleted  INTEGER NOT NULL DEFAULT 0
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
      created_at      TEXT    NOT NULL,
      sync_status     TEXT    NOT NULL DEFAULT 'pending',
      updated_at      INTEGER NOT NULL DEFAULT 0,
      is_deleted      INTEGER NOT NULL DEFAULT 0
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
      created_at      TEXT    NOT NULL,
      updated_at      INTEGER NOT NULL DEFAULT 0,
      is_deleted      INTEGER NOT NULL DEFAULT 0
    )
  ''';

  // productId is nullable — allows future Inventory linkage without migration.
  static const _sqlInvoiceItems = '''
    CREATE TABLE billing_invoice_items (
      id              INTEGER PRIMARY KEY AUTOINCREMENT,
      invoice_id      INTEGER NOT NULL REFERENCES billing_invoices(id) ON DELETE CASCADE,
      product_id      INTEGER,
      item_name       TEXT    NOT NULL,
      quantity        REAL    NOT NULL DEFAULT 1,
      unit            TEXT    NOT NULL DEFAULT 'pcs',
      price           REAL    NOT NULL DEFAULT 0,
      total           REAL    NOT NULL DEFAULT 0,
      created_at      TEXT    NOT NULL,
      product_source  TEXT    NOT NULL DEFAULT 'inventory'
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
      amount        INTEGER NOT NULL DEFAULT 0,
      customer_id   INTEGER,
      vehicle_id    INTEGER,
      sync_status   TEXT    NOT NULL DEFAULT 'pending',
      updated_at    INTEGER NOT NULL DEFAULT 0,
      is_deleted    INTEGER NOT NULL DEFAULT 0,
      job_type      TEXT    NOT NULL DEFAULT 'vehicle',
      item_name     TEXT    NOT NULL DEFAULT '',
      item_description TEXT NOT NULL DEFAULT ''
    )
  ''';

  static const _sqlMechanics = '''
    CREATE TABLE mechanics (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      name          TEXT    NOT NULL,
      initials      TEXT    NOT NULL DEFAULT '',
      phone         TEXT    NOT NULL DEFAULT '',
      specialization TEXT   NOT NULL DEFAULT '',
      is_active     INTEGER NOT NULL DEFAULT 1,
      created_at    TEXT    NOT NULL,
      sync_status   TEXT    NOT NULL DEFAULT 'pending',
      updated_at    INTEGER NOT NULL DEFAULT 0,
      is_deleted    INTEGER NOT NULL DEFAULT 0
    )
  ''';

  // NOTE (Clarification A): The primary key remains id-only (not composite with garage_id)
  // because SQLite does not support changing primary key constraints via ALTER TABLE.
  // Consequently, colliding IDs across different garages would overwrite each other in the DB
  // if ConflictAlgorithm.replace is triggered. However, since Firestore document IDs are
  // globally unique random 20-character strings, this risk is negligible.
  // Application-level scoping (WHERE garage_id = ?) prevents reading across garages.
  static const _sqlSecondHandInventory = '''
    CREATE TABLE secondhand_inventory (
      id              TEXT    PRIMARY KEY,
      name            TEXT    NOT NULL,
      category        TEXT    NOT NULL DEFAULT '',
      stock           INTEGER NOT NULL DEFAULT 0,
      unit            TEXT    NOT NULL DEFAULT 'pcs',
      purchase        INTEGER NOT NULL DEFAULT 0,
      selling         INTEGER NOT NULL DEFAULT 0,
      min_stock       INTEGER NOT NULL DEFAULT 0,
      sku             TEXT    NOT NULL DEFAULT '',
      source_notes    TEXT    NOT NULL DEFAULT '',
      condition_notes TEXT    NOT NULL DEFAULT '',
      created_at      TEXT    NOT NULL,
      sync_status     TEXT    NOT NULL DEFAULT 'pending',
      updated_at      INTEGER NOT NULL DEFAULT 0,
      is_deleted      INTEGER NOT NULL DEFAULT 0,
      name_lower      TEXT,
      sku_lower       TEXT,
      category_lower  TEXT,
      garage_id       TEXT    NOT NULL DEFAULT ''
    )
  ''';

  // Future<void> _seedMockJobs(Database db) async {
  //   final mockJobs = [
  //     {
  //       'job_number': 'JC-2024-0156',
  //       'customer': 'Rajesh Kumar',
  //       'vehicle': 'MH12 AB 1234',
  //       'vehicleType': 'car',
  //       'brand': 'Maruti Swift',
  //       'complaint': 'Engine noise, oil leak',
  //       'mechanic': 'Suresh K.',
  //       'status': 'in-progress',
  //       'date': '23 Jun 2024',
  //       'amount': 8500
  //     },
  //     {
  //       'job_number': 'JC-2024-0155',
  //       'customer': 'Priya Sharma',
  //       'vehicle': 'MH12 CD 5678',
  //       'vehicleType': 'bike',
  //       'brand': 'Honda Activa',
  //       'complaint': 'Brake service, tyre change',
  //       'mechanic': 'Ramesh V.',
  //       'status': 'pending',
  //       'date': '23 Jun 2024',
  //       'amount': 3200
  //     },
  //     {
  //       'job_number': 'JC-2024-0154',
  //       'customer': 'Mohammed Irfan',
  //       'vehicle': 'MH14 EF 9012',
  //       'vehicleType': 'car',
  //       'brand': 'Toyota Innova',
  //       'complaint': 'AC not working, full service',
  //       'mechanic': 'Suresh K.',
  //       'status': 'completed',
  //       'date': '22 Jun 2024',
  //       'amount': 14200
  //     },
  //     {
  //       'job_number': 'JC-2024-0153',
  //       'customer': 'Sunita Patel',
  //       'vehicle': 'MH12 GH 3456',
  //       'vehicleType': 'bike',
  //       'brand': 'Bajaj Pulsar',
  //       'complaint': 'Starting problem',
  //       'mechanic': 'Kiran M.',
  //       'status': 'completed',
  //       'date': '22 Jun 2024',
  //       'amount': 1800
  //     },
  //     {
  //       'job_number': 'JC-2024-0152',
  //       'customer': 'Arun Nair',
  //       'vehicle': 'MH14 IJ 7890',
  //       'vehicleType': 'car',
  //       'brand': 'Hyundai i20',
  //       'complaint': 'Clutch replacement, wheel alignment',
  //       'mechanic': 'Ramesh V.',
  //       'status': 'in-progress',
  //       'date': '21 Jun 2024',
  //       'amount': 9800
  //     },
  //   ];
  //
  //   for (final job in mockJobs) {
  //     await db.insert('jobs', job);
  //   }
  // }

  // ─── Invoice Number Generator ──────────────────────────────────────────────

  /// Atomically increments the counter and returns the next INV-XXXXXX string.
  Future<String> nextInvoiceNumber() async {
    final db = await database;
    return db.transaction<String>((txn) async {
      final counterRows = await txn.query('invoice_counter', where: 'id = 1');
      final counterLast = (counterRows.first['last_number'] as int?) ?? 0;

      // Guard against the counter lagging behind actual data (e.g. invoices
      // that arrived via Firestore sync rather than being generated locally).
      final maxRow = await txn.rawQuery(
        "SELECT MAX(CAST(SUBSTR(invoice_number, 5) AS INTEGER)) as maxNum "
        "FROM billing_invoices WHERE invoice_number LIKE 'INV-%'",
      );
      final actualMax = (maxRow.first['maxNum'] as int?) ?? 0;

      final next = (counterLast > actualMax ? counterLast : actualMax) + 1;
      await txn.update('invoice_counter', {
        'last_number': next,
      }, where: 'id = 1');
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
