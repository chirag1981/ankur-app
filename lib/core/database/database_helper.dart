import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('invisible_grills.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        // Automatically ensure master and default Labor materials are updated to 20.0/sq.ft
        await db.execute('''
          UPDATE materials 
          SET unit_price = 20.0, calculation_type = 'per_sq_ft', unit = 'Sq. Ft'
          WHERE LOWER(name) = 'labor' AND (unit_price = 40.0 OR calculation_type != 'per_sq_ft')
        ''');
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Customers Table
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'quotation',
        discount_type TEXT NOT NULL DEFAULT 'flat',
        discount_value REAL NOT NULL DEFAULT 0.0,
        advance_amount REAL NOT NULL DEFAULT 0.0,
        tax_rate REAL NOT NULL DEFAULT 0.0
      )
    ''');

    // Rooms Table
    await db.execute('''
      CREATE TABLE rooms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
      )
    ''');

    // Windows Table
    await db.execute('''
      CREATE TABLE windows (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        room_id INTEGER NOT NULL,
        customer_id INTEGER NOT NULL,
        label TEXT NOT NULL,
        window_type TEXT NOT NULL,
        width_inches REAL NOT NULL,
        height_inches REAL NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        rate_per_sq_ft REAL NOT NULL DEFAULT 0.0,
        FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE,
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
      )
    ''');

    // Materials Table
    await db.execute('''
      CREATE TABLE materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        unit TEXT NOT NULL,
        unit_price REAL NOT NULL,
        calculation_type TEXT NOT NULL,
        multiplier REAL NOT NULL DEFAULT 1.0,
        manual_quantity REAL NOT NULL DEFAULT 1.0,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
      )
    ''');

    // Seed master default material items (where customer_id IS NULL)
    await _seedDefaultMasterMaterials(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        UPDATE materials 
        SET unit_price = 20.0, calculation_type = 'per_sq_ft', unit = 'Sq. Ft'
        WHERE LOWER(name) = 'labor'
      ''');
    }
  }

  Future<void> _seedDefaultMasterMaterials(Database db) async {
    final defaultMaterials = [
      {
        'customer_id': null,
        'name': 'Channel',
        'category': 'Channel',
        'unit': 'Sq. Ft',
        'unit_price': 120.0,
        'calculation_type': 'per_sq_ft',
        'multiplier': 1.0,
        'manual_quantity': 1.0,
        'is_enabled': 1,
      },
      {
        'customer_id': null,
        'name': 'Wire',
        'category': 'Wire',
        'unit': 'Sq. Ft',
        'unit_price': 85.0,
        'calculation_type': 'per_sq_ft',
        'multiplier': 1.0,
        'manual_quantity': 1.0,
        'is_enabled': 1,
      },
      {
        'customer_id': null,
        'name': 'Bolt',
        'category': 'Hardware',
        'unit': 'Per Window',
        'unit_price': 30.0,
        'calculation_type': 'per_window',
        'multiplier': 1.0,
        'manual_quantity': 1.0,
        'is_enabled': 1,
      },
      {
        'customer_id': null,
        'name': 'Chokdi',
        'category': 'Hardware',
        'unit': 'Per Window',
        'unit_price': 50.0,
        'calculation_type': 'per_window',
        'multiplier': 1.0,
        'manual_quantity': 1.0,
        'is_enabled': 1,
      },
      {
        'customer_id': null,
        'name': 'Labor',
        'category': 'Labor',
        'unit': 'Sq. Ft',
        'unit_price': 20.0,
        'calculation_type': 'per_sq_ft',
        'multiplier': 1.0,
        'manual_quantity': 1.0,
        'is_enabled': 1,
      },
    ];

    for (final mat in defaultMaterials) {
      await db.insert('materials', mat);
    }
  }

  // ==========================================
  // CUSTOMER CRUD
  // ==========================================

  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    final id = await db.insert('customers', customer.toMap());
    // Copy master materials to this customer automatically so it's isolated
    await copyMasterMaterialsToCustomer(id);
    return id;
  }

  Future<List<Customer>> getAllCustomers({String? searchQuery, String? statusFilter}) async {
    final db = await database;
    String where = '';
    List<dynamic> whereArgs = [];

    final conditions = <String>[];
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      conditions.add('(name LIKE ? OR phone LIKE ? OR address LIKE ?)');
      final term = '%${searchQuery.trim()}%';
      whereArgs.addAll([term, term, term]);
    }
    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
      conditions.add('status = ?');
      whereArgs.add(statusFilter);
    }

    if (conditions.isNotEmpty) {
      where = conditions.join(' AND ');
    }

    final maps = await db.query(
      'customers',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'id DESC',
    );

    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  Future<Customer?> getCustomerById(int id) async {
    final db = await database;
    final maps = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // ROOM CRUD
  // ==========================================

  Future<int> insertRoom(Room room) async {
    final db = await database;
    return await db.insert('rooms', room.toMap());
  }

  Future<List<Room>> getRoomsForCustomer(int customerId) async {
    final db = await database;
    final maps = await db.query(
      'rooms',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'id ASC',
    );
    return maps.map((m) => Room.fromMap(m)).toList();
  }

  Future<int> updateRoom(Room room) async {
    final db = await database;
    return await db.update(
      'rooms',
      room.toMap(),
      where: 'id = ?',
      whereArgs: [room.id],
    );
  }

  Future<int> deleteRoom(int id) async {
    final db = await database;
    return await db.delete('rooms', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // WINDOW CRUD
  // ==========================================

  Future<int> insertWindow(WindowItem window) async {
    final db = await database;
    return await db.insert('windows', window.toMap());
  }

  Future<List<WindowItem>> getWindowsForRoom(int roomId) async {
    final db = await database;
    final maps = await db.query(
      'windows',
      where: 'room_id = ?',
      whereArgs: [roomId],
      orderBy: 'id ASC',
    );
    return maps.map((m) => WindowItem.fromMap(m)).toList();
  }

  Future<List<WindowItem>> getWindowsForCustomer(int customerId) async {
    final db = await database;
    final maps = await db.query(
      'windows',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'id ASC',
    );
    return maps.map((m) => WindowItem.fromMap(m)).toList();
  }

  Future<int> updateWindow(WindowItem window) async {
    final db = await database;
    return await db.update(
      'windows',
      window.toMap(),
      where: 'id = ?',
      whereArgs: [window.id],
    );
  }

  Future<int> deleteWindow(int id) async {
    final db = await database;
    return await db.delete('windows', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // MATERIALS CRUD
  // ==========================================

  Future<List<MaterialItem>> getMasterMaterials() async {
    final db = await database;
    final maps = await db.query(
      'materials',
      where: 'customer_id IS NULL',
      orderBy: 'id ASC',
    );
    return maps.map((m) => MaterialItem.fromMap(m)).toList();
  }

  Future<List<MaterialItem>> getMaterialsForCustomer(int customerId) async {
    final db = await database;
    var maps = await db.query(
      'materials',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'id ASC',
    );

    // If customer has no materials yet, copy from master
    if (maps.isEmpty) {
      await copyMasterMaterialsToCustomer(customerId);
      maps = await db.query(
        'materials',
        where: 'customer_id = ?',
        whereArgs: [customerId],
        orderBy: 'id ASC',
      );
    }

    return maps.map((m) => MaterialItem.fromMap(m)).toList();
  }

  Future<void> copyMasterMaterialsToCustomer(int customerId) async {
    final db = await database;
    final master = await getMasterMaterials();
    for (final item in master) {
      final copy = MaterialItem(
        customerId: customerId,
        name: item.name,
        category: item.category,
        unit: item.unit,
        unitPrice: item.unitPrice,
        calculationType: item.calculationType,
        multiplier: item.multiplier,
        manualQuantity: item.manualQuantity,
        isEnabled: item.isEnabled,
      );
      await db.insert('materials', copy.toMap());
    }
  }

  Future<int> insertMaterial(MaterialItem material) async {
    final db = await database;
    return await db.insert('materials', material.toMap());
  }

  Future<int> updateMaterial(MaterialItem material) async {
    final db = await database;
    return await db.update(
      'materials',
      material.toMap(),
      where: 'id = ?',
      whereArgs: [material.id],
    );
  }

  Future<int> deleteMaterial(int id) async {
    final db = await database;
    return await db.delete('materials', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // COMPLETE ESTIMATE LOADER
  // ==========================================

  Future<CustomerEstimate?> getCompleteCustomerEstimate(int customerId) async {
    final customer = await getCustomerById(customerId);
    if (customer == null) return null;

    final rooms = await getRoomsForCustomer(customerId);
    final allWindows = await getWindowsForCustomer(customerId);
    final materials = await getMaterialsForCustomer(customerId);

    final Map<int, List<WindowItem>> windowsByRoom = {};
    for (final room in rooms) {
      windowsByRoom[room.id!] = allWindows.where((w) => w.roomId == room.id).toList();
    }

    return CustomerEstimate(
      customer: customer,
      rooms: rooms,
      windowsByRoom: windowsByRoom,
      materials: materials,
    );
  }
}
