import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

/// Database service for managing SQLite database
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'invoice_app.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Clients table
    await db.execute('''
      CREATE TABLE clients (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        address TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Items table
    await db.execute('''
      CREATE TABLE items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        unit TEXT DEFAULT 'unit',
        taxRate REAL DEFAULT 0.0,
        createdAt TEXT NOT NULL
      )
    ''');

    // Invoices table
    await db.execute('''
      CREATE TABLE invoices (
        id TEXT PRIMARY KEY,
        invoiceNumber TEXT NOT NULL UNIQUE,
        clientId TEXT NOT NULL,
        clientName TEXT,
        status TEXT DEFAULT 'unpaid',
        issueDate TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        notes TEXT,
        paidAmount REAL DEFAULT 0.0,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (clientId) REFERENCES clients (id)
      )
    ''');

    // Invoice items table
    await db.execute('''
      CREATE TABLE invoice_items (
        id TEXT PRIMARY KEY,
        invoiceId TEXT NOT NULL,
        itemId TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        quantity REAL NOT NULL,
        taxRate REAL DEFAULT 0.0,
        FOREIGN KEY (invoiceId) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    // Estimates table
    await db.execute('''
      CREATE TABLE estimates (
        id TEXT PRIMARY KEY,
        estimateNumber TEXT NOT NULL UNIQUE,
        clientId TEXT NOT NULL,
        clientName TEXT,
        status TEXT DEFAULT 'draft',
        issueDate TEXT NOT NULL,
        validUntil TEXT NOT NULL,
        notes TEXT,
        convertedInvoiceId TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (clientId) REFERENCES clients (id)
      )
    ''');

    // Estimate items table
    await db.execute('''
      CREATE TABLE estimate_items (
        id TEXT PRIMARY KEY,
        estimateId TEXT NOT NULL,
        itemId TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        quantity REAL NOT NULL,
        taxRate REAL DEFAULT 0.0,
        FOREIGN KEY (estimateId) REFERENCES estimates (id) ON DELETE CASCADE
      )
    ''');

    // Payments table
    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        invoiceId TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        method TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (invoiceId) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    // Settings table (key-value store)
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Insert default settings
    await db.insert('settings', {'key': 'currency', 'value': 'USD'});
    await db.insert('settings', {'key': 'invoicePrefix', 'value': 'INV-'});
    await db.insert('settings', {'key': 'estimatePrefix', 'value': 'EST-'});
    await db.insert('settings', {'key': 'nextInvoiceNumber', 'value': '1'});
    await db.insert('settings', {'key': 'nextEstimateNumber', 'value': '1'});
    await db.insert('settings', {'key': 'defaultDueDays', 'value': '30'});
    await db.insert('settings', {'key': 'defaultValidDays', 'value': '30'});
  }

  // ========== CLIENT OPERATIONS ==========

  Future<void> insertClient(Client client) async {
    final db = await database;
    await db.insert('clients', client.toMap());
  }

  Future<List<Client>> getAllClients() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clients',
      orderBy: 'name ASC',
    );
    return maps.map((map) => Client.fromMap(map)).toList();
  }

  Future<Client?> getClient(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Client.fromMap(maps.first);
  }

  Future<void> updateClient(Client client) async {
    final db = await database;
    await db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<void> deleteClient(String id) async {
    final db = await database;
    await db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  // ========== ITEM OPERATIONS ==========

  Future<void> insertItem(Item item) async {
    final db = await database;
    await db.insert('items', item.toMap());
  }

  Future<List<Item>> getAllItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      orderBy: 'name ASC',
    );
    return maps.map((map) => Item.fromMap(map)).toList();
  }

  Future<Item?> getItem(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Item.fromMap(maps.first);
  }

  Future<void> updateItem(Item item) async {
    final db = await database;
    await db.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteItem(String id) async {
    final db = await database;
    await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  // ========== INVOICE OPERATIONS ==========

  Future<void> insertInvoice(Invoice invoice) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('invoices', invoice.toMap());
      for (final item in invoice.items) {
        await txn.insert('invoice_items', {
          ...item.toMap(),
          'invoiceId': invoice.id,
        });
      }
    });
  }

  Future<List<Invoice>> getAllInvoices({PaymentStatus? status}) async {
    final db = await database;

    String? whereClause;
    List<String>? whereArgs;

    if (status != null) {
      whereClause = 'status = ?';
      whereArgs = [status.name];
    }

    final List<Map<String, dynamic>> invoiceMaps = await db.query(
      'invoices',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'createdAt DESC',
    );

    List<Invoice> invoices = [];
    for (final invoiceMap in invoiceMaps) {
      final itemMaps = await db.query(
        'invoice_items',
        where: 'invoiceId = ?',
        whereArgs: [invoiceMap['id']],
      );
      final items = itemMaps.map((m) => InvoiceItem.fromMap(m)).toList();
      invoices.add(Invoice.fromMap(invoiceMap, items));
    }
    return invoices;
  }

  Future<Invoice?> getInvoice(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;

    final itemMaps = await db.query(
      'invoice_items',
      where: 'invoiceId = ?',
      whereArgs: [id],
    );
    final items = itemMaps.map((m) => InvoiceItem.fromMap(m)).toList();
    return Invoice.fromMap(maps.first, items);
  }

  Future<void> updateInvoice(Invoice invoice) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'invoices',
        invoice.toMap(),
        where: 'id = ?',
        whereArgs: [invoice.id],
      );
      // Delete old items and insert new ones
      await txn.delete(
        'invoice_items',
        where: 'invoiceId = ?',
        whereArgs: [invoice.id],
      );
      for (final item in invoice.items) {
        await txn.insert('invoice_items', {
          ...item.toMap(),
          'invoiceId': invoice.id,
        });
      }
    });
  }

  Future<void> deleteInvoice(String id) async {
    final db = await database;
    await db.delete('invoices', where: 'id = ?', whereArgs: [id]);
  }

  // ========== ESTIMATE OPERATIONS ==========

  Future<void> insertEstimate(Estimate estimate) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('estimates', estimate.toMap());
      for (final item in estimate.items) {
        await txn.insert('estimate_items', {
          ...item.toMap(),
          'estimateId': estimate.id,
        });
      }
    });
  }

  Future<List<Estimate>> getAllEstimates({EstimateStatus? status}) async {
    final db = await database;

    String? whereClause;
    List<String>? whereArgs;

    if (status != null) {
      whereClause = 'status = ?';
      whereArgs = [status.name];
    }

    final List<Map<String, dynamic>> estimateMaps = await db.query(
      'estimates',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'createdAt DESC',
    );

    List<Estimate> estimates = [];
    for (final estimateMap in estimateMaps) {
      final itemMaps = await db.query(
        'estimate_items',
        where: 'estimateId = ?',
        whereArgs: [estimateMap['id']],
      );
      final items = itemMaps.map((m) => InvoiceItem.fromMap(m)).toList();
      estimates.add(Estimate.fromMap(estimateMap, items));
    }
    return estimates;
  }

  Future<Estimate?> getEstimate(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'estimates',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;

    final itemMaps = await db.query(
      'estimate_items',
      where: 'estimateId = ?',
      whereArgs: [id],
    );
    final items = itemMaps.map((m) => InvoiceItem.fromMap(m)).toList();
    return Estimate.fromMap(maps.first, items);
  }

  Future<void> updateEstimate(Estimate estimate) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'estimates',
        estimate.toMap(),
        where: 'id = ?',
        whereArgs: [estimate.id],
      );
      await txn.delete(
        'estimate_items',
        where: 'estimateId = ?',
        whereArgs: [estimate.id],
      );
      for (final item in estimate.items) {
        await txn.insert('estimate_items', {
          ...item.toMap(),
          'estimateId': estimate.id,
        });
      }
    });
  }

  Future<void> deleteEstimate(String id) async {
    final db = await database;
    await db.delete('estimates', where: 'id = ?', whereArgs: [id]);
  }

  // ========== PAYMENT OPERATIONS ==========

  Future<void> insertPayment(Payment payment) async {
    final db = await database;
    await db.insert('payments', payment.toMap());
  }

  Future<List<Payment>> getPaymentsForInvoice(String invoiceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      where: 'invoiceId = ?',
      whereArgs: [invoiceId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Payment.fromMap(map)).toList();
  }

  Future<void> deletePayment(String id) async {
    final db = await database;
    await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  // ========== SETTINGS OPERATIONS ==========

  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<BusinessSettings> getBusinessSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('settings');

    final settingsMap = <String, dynamic>{};
    for (final map in maps) {
      final key = map['key'] as String;
      final value = map['value'] as String?;

      // Convert numeric values
      if (key == 'nextInvoiceNumber' ||
          key == 'nextEstimateNumber' ||
          key == 'defaultDueDays' ||
          key == 'defaultValidDays') {
        settingsMap[key] = int.tryParse(value ?? '') ?? 1;
      } else {
        settingsMap[key] = value;
      }
    }

    return BusinessSettings.fromMap(settingsMap);
  }

  Future<void> saveBusinessSettings(BusinessSettings settings) async {
    final map = settings.toMap();
    for (final entry in map.entries) {
      await setSetting(entry.key, entry.value?.toString() ?? '');
    }
  }

  // ========== REPORTING QUERIES ==========

  Future<Map<String, double>> getInvoiceSummary() async {
    final db = await database;

    // Total invoiced amount
    final totalResult = await db.rawQuery('''
      SELECT 
        SUM(
          (SELECT COALESCE(SUM(price * quantity * (1 + taxRate/100)), 0) 
           FROM invoice_items WHERE invoiceId = invoices.id)
        ) as total
      FROM invoices
    ''');

    // Paid amount
    final paidResult = await db.rawQuery('''
      SELECT COALESCE(SUM(paidAmount), 0) as paid FROM invoices
    ''');

    // Unpaid amount by status
    final unpaidResult = await db.rawQuery('''
      SELECT 
        SUM(
          (SELECT COALESCE(SUM(price * quantity * (1 + taxRate/100)), 0) 
           FROM invoice_items WHERE invoiceId = invoices.id) - paidAmount
        ) as unpaid
      FROM invoices
      WHERE status != 'paid'
    ''');

    return {
      'total': (totalResult.first['total'] as num?)?.toDouble() ?? 0.0,
      'paid': (paidResult.first['paid'] as num?)?.toDouble() ?? 0.0,
      'unpaid': (unpaidResult.first['unpaid'] as num?)?.toDouble() ?? 0.0,
    };
  }

  Future<int> getInvoiceCount({PaymentStatus? status}) async {
    final db = await database;
    if (status == null) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM invoices',
      );
      return result.first['count'] as int;
    }
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM invoices WHERE status = ?',
      [status.name],
    );
    return result.first['count'] as int;
  }

  Future<int> getClientCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM clients');
    return result.first['count'] as int;
  }
}
