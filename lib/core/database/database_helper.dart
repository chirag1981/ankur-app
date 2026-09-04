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
      version: 9,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        // Ensure profit_margin_rate column exists in customers table
        final customerCols = await db.rawQuery('PRAGMA table_info(customers)');
        final hasProfitMargin = customerCols.any((c) => c['name'] == 'profit_margin_rate');
        if (!hasProfitMargin) {
          await db.execute('ALTER TABLE customers ADD COLUMN profit_margin_rate REAL NOT NULL DEFAULT 0.0');
        }

        // Ensure company_profile table exists
        await db.execute('''
          CREATE TABLE IF NOT EXISTS company_profile (
            id INTEGER PRIMARY KEY,
            company_name TEXT NOT NULL,
            tagline TEXT,
            phone TEXT,
            email TEXT,
            facebook_id TEXT,
            instagram_id TEXT,
            address TEXT,
            logo_path TEXT
          )
        ''');

        // Seed default company profile if empty
        final profileRows = await db.query('company_profile');
        if (profileRows.isEmpty) {
          await db.insert('company_profile', {
            'id': 1,
            'company_name': 'ARHAM ENTERPRISE',
            'tagline': 'INVISIBLE GRILL - Secure, Stylish & Invisible',
            'phone': '+91 98765 43210',
            'email': 'contact@arhamenterprise.com',
            'facebook_id': 'Arham Invisible Grill',
            'instagram_id': '@arham_enterprise',
            'address': '',
            'logo_path': 'assets/images/logo.png',
          });
        }

        // Automatically ensure master and default Labor materials are updated to 20.0/sq.ft
        await db.execute('''
          UPDATE materials 
          SET unit_price = 20.0, calculation_type = 'per_sq_ft', unit = 'Sq. Ft'
          WHERE LOWER(name) = 'labor' AND (unit_price = 40.0 OR calculation_type != 'per_sq_ft')
        ''');

        // Automatically ensure Channel is configured in Ft (width * 2) at 90.0/ft (10ft = 900rs)
        await db.execute('''
          UPDATE materials 
          SET unit = 'Ft', unit_price = 90.0, calculation_type = 'per_ft'
          WHERE (LOWER(name) LIKE '%channel%' OR LOWER(category) = 'channel') 
            AND (calculation_type = 'per_sq_ft' OR calculation_type = 'per_window' OR unit = 'Sq. Ft')
        ''');

        // Automatically ensure Wire is configured in Meters (Sq.Ft * 2.7)
        await db.execute('''
          UPDATE materials 
          SET unit = 'Meter', unit_price = 13.0, calculation_type = 'per_wire_meter', name = 'Wire (2.5mm)'
          WHERE LOWER(name) = 'wire' AND (calculation_type = 'per_sq_ft' OR unit = 'Sq. Ft')
        ''');

        // Automatically ensure Bolt is configured as per_channel_bolts (12 bolts per 10ft channel)
        await db.execute('''
          UPDATE materials 
          SET unit = 'Pcs', calculation_type = 'per_channel_bolts'
          WHERE LOWER(name) LIKE '%bolt%' AND (calculation_type = 'per_window' OR calculation_type = 'per_sq_ft')
        ''');

        // Automatically ensure Chokdi is configured as per_channel_chokdi (60 chokdi per 10ft channel)
        await db.execute('''
          UPDATE materials 
          SET unit = 'Pcs', calculation_type = 'per_channel_chokdi'
          WHERE LOWER(name) LIKE '%chokdi%' AND (calculation_type = 'per_window' OR calculation_type = 'per_sq_ft')
        ''');

        // Automatically ensure Transport is available in master materials
        final masterTransport = await db.query(
          'materials',
          where: 'customer_id IS NULL AND LOWER(name) LIKE ?',
          whereArgs: ['%transport%'],
        );
        if (masterTransport.isEmpty) {
          await db.insert('materials', {
            'customer_id': null,
            'name': 'Transport',
            'category': 'Transport',
            'unit': 'Trip',
            'unit_price': 0.0,
            'calculation_type': 'fixed',
            'multiplier': 1.0,
            'manual_quantity': 1.0,
            'is_enabled': 1,
          });
        }

        // Automatically ensure every customer has a Transport item
        final customersWithoutTransport = await db.rawQuery('''
          SELECT id FROM customers 
          WHERE id NOT IN (
            SELECT customer_id FROM materials WHERE customer_id IS NOT NULL AND LOWER(name) LIKE '%transport%'
          )
        ''');
        for (final row in customersWithoutTransport) {
          final custId = row['id'] as int;
          await db.insert('materials', {
            'customer_id': custId,
            'name': 'Transport',
            'category': 'Transport',
            'unit': 'Trip',
            'unit_price': 0.0,
            'calculation_type': 'fixed',
            'multiplier': 1.0,
            'manual_quantity': 1.0,
            'is_enabled': 1,
          });
        }
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
        tax_rate REAL NOT NULL DEFAULT 0.0,
        profit_margin_rate REAL NOT NULL DEFAULT 0.0
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

    // Company Profile Table
    await db.execute('''
      CREATE TABLE company_profile (
        id INTEGER PRIMARY KEY,
        company_name TEXT NOT NULL,
        tagline TEXT,
        phone TEXT,
        email TEXT,
        facebook_id TEXT,
        instagram_id TEXT,
        address TEXT,
        logo_path TEXT
      )
    ''');
    await db.insert('company_profile', {
      'id': 1,
      'company_name': 'ARHAM ENTERPRISE',
      'tagline': 'INVISIBLE GRILL - Secure, Stylish & Invisible',
      'phone': '+91 98765 43210',
      'email': 'contact@arhamenterprise.com',
      'facebook_id': 'Arham Invisible Grill',
      'instagram_id': '@arham_enterprise',
      'address': '',
      'logo_path': 'assets/images/logo.png',
    });

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
    if (oldVersion < 3) {
      await db.execute('''
        UPDATE materials 
        SET unit = 'Ft', unit_price = 90.0, calculation_type = 'per_ft'
        WHERE LOWER(name) = 'channel'
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        UPDATE materials 
        SET unit = 'Meter', unit_price = 13.0, calculation_type = 'per_wire_meter', name = 'Wire (2.5mm)'
        WHERE LOWER(name) = 'wire' AND (calculation_type = 'per_sq_ft' OR unit = 'Sq. Ft')
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        UPDATE materials 
        SET unit = 'Pcs', calculation_type = 'per_channel_bolts'
        WHERE LOWER(name) LIKE '%bolt%'
      ''');
    }
    if (oldVersion < 6) {
      await db.execute('''
        UPDATE materials 
        SET unit = 'Pcs', calculation_type = 'per_channel_chokdi'
        WHERE LOWER(name) LIKE '%chokdi%'
      ''');
    }
    if (oldVersion < 7) {
      final masterTransport = await db.query(
        'materials',
        where: 'customer_id IS NULL AND LOWER(name) LIKE ?',
        whereArgs: ['%transport%'],
      );
      if (masterTransport.isEmpty) {
        await db.insert('materials', {
          'customer_id': null,
          'name': 'Transport',
          'category': 'Transport',
          'unit': 'Trip',
          'unit_price': 0.0,
          'calculation_type': 'fixed',
          'multiplier': 1.0,
          'manual_quantity': 1.0,
          'is_enabled': 1,
        });
      }
    }
    if (oldVersion < 8) {
      final customerCols = await db.rawQuery('PRAGMA table_info(customers)');
      final hasProfitMargin = customerCols.any((c) => c['name'] == 'profit_margin_rate');
      if (!hasProfitMargin) {
        await db.execute('ALTER TABLE customers ADD COLUMN profit_margin_rate REAL NOT NULL DEFAULT 0.0');
      }
    }
    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS company_profile (
          id INTEGER PRIMARY KEY,
          company_name TEXT NOT NULL,
          tagline TEXT,
          phone TEXT,
          email TEXT,
          facebook_id TEXT,
          instagram_id TEXT,
          address TEXT,
          logo_path TEXT
        )
      ''');
      final profileRows = await db.query('company_profile');
      if (profileRows.isEmpty) {
        await db.insert('company_profile', {
          'id': 1,
          'company_name': 'ARHAM ENTERPRISE',
          'tagline': 'INVISIBLE GRILL - Secure, Stylish & Invisible',
          'phone': '+91 98765 43210',
          'email': 'contact@arhamenterprise.com',
          'facebook_id': 'Arham Invisible Grill',
          'instagram_id': '@arham_enterprise',
          'address': '',
          'logo_path': 'assets/images/logo.png',
        });
      }
    }
  }

  Future<void> _seedDefaultMasterMaterials(Database db) async {
    final defaultMaterials = [
      {
        'customer_id': null,
        'name': 'Channel',
        'category': 'Channel',
        'unit': 'Ft',
        'unit_price': 90.0,
        'calculation_type': 'per_ft',
        'multiplier': 1.0,
        'manual_quantity': 1.0,
        'is_enabled': 1,
      },
      {
        'customer_id': null,
        'name': 'Wire (2.5mm)',
        'category': 'Wire',
        'unit': 'Meter',
        'unit_price': 13.0,
        'calculation_type': 'per_wire_meter',
        'multiplier': 1.0,
        'manual_quantity': 1.0,
        'is_enabled': 1,
      },
      {
        'customer_id': null,
        'name': 'Wire (2mm)',
        'category': 'Wire',
        'unit': 'Meter',
        'unit_price': 9.0,
        'calculation_type': 'per_wire_meter',
        'multiplier': 1.0,
        'manual_quantity': 1.0,
        'is_enabled': 0,
      },
      {
        'customer_id': null,
        'name': 'Wire (3mm)',
        'category': 'Wire',
        'unit': 'Meter',
        'unit_price': 16.0,
        'calculation_type': 'per_wire_meter',
        'multiplier': 1.0,
        'manual_quantity': 1.0,
        'is_enabled': 0,
      },
      {
        'customer_id': null,
        'name': 'Bolt',
        'category': 'Hardware',
        'unit': 'Pcs',
        'unit_price': 5.0,
        'calculation_type': 'per_channel_bolts',
        'multiplier': 1.0,
        'manual_quantity': 1.0,
        'is_enabled': 1,
      },
      {
        'customer_id': null,
        'name': 'Chokdi',
        'category': 'Hardware',
        'unit': 'Pcs',
        'unit_price': 2.0,
        'calculation_type': 'per_channel_chokdi',
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
      {
        'customer_id': null,
        'name': 'Transport',
        'category': 'Transport',
        'unit': 'Trip',
        'unit_price': 0.0,
        'calculation_type': 'fixed',
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

  // ==========================================
  // COMPANY PROFILE
  // ==========================================

  Future<CompanyProfile> getCompanyProfile() async {
    final db = await database;
    final maps = await db.query('company_profile', where: 'id = 1');
    if (maps.isNotEmpty) {
      return CompanyProfile.fromMap(maps.first);
    }
    final defaultProfile = CompanyProfile();
    await db.insert('company_profile', defaultProfile.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return defaultProfile;
  }

  Future<void> updateCompanyProfile(CompanyProfile profile) async {
    final db = await database;
    await db.insert(
      'company_profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
