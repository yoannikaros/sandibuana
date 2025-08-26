import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/dropdown_option_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'sandibuana.db');
    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabel untuk menyimpan opsi dropdown
    await db.execute('''
      CREATE TABLE dropdown_options (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        value TEXT NOT NULL,
        description TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        UNIQUE(category, value)
      )
    ''');

    // Tabel untuk pengeluaran harian
    await db.execute('''
      CREATE TABLE pengeluaran_harian (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tanggal_pengeluaran TEXT NOT NULL,
        kategori TEXT NOT NULL,
        keterangan TEXT NOT NULL,
        jumlah REAL NOT NULL,
        nomor_nota TEXT,
        pemasok TEXT,
        catatan TEXT,
        dicatat_oleh TEXT,
        dicatat_pada TEXT NOT NULL
      )
    ''');

    // Tabel untuk menyimpan session login
    await db.execute('''
      CREATE TABLE user_session (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        email TEXT NOT NULL,
        username TEXT NOT NULL,
        nama_lengkap TEXT NOT NULL,
        peran TEXT NOT NULL,
        remember_me INTEGER NOT NULL DEFAULT 0,
        login_time TEXT NOT NULL,
        last_activity TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Insert data default
    await _insertDefaultData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      // Tambahkan tabel user_session untuk versi 4
      await db.execute('''
        CREATE TABLE user_session (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL,
          email TEXT NOT NULL,
          username TEXT NOT NULL,
          nama_lengkap TEXT NOT NULL,
          peran TEXT NOT NULL,
          remember_me INTEGER NOT NULL DEFAULT 0,
          login_time TEXT NOT NULL,
          last_activity TEXT NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1
        )
      ''');
    }
  }

  Future<void> _insertDefaultData(Database db) async {
    final now = DateTime.now().toIso8601String();

    // Removed Area Tanaman data - no longer needed

    // Data default untuk Jenis Perlakuan
    final jenisPerlakuanData = [
      'Pemupukan',
      'Penyiraman',
      'Penyemprotan Pestisida',
      'Penyiangan',
      'Pemangkasan',
      'Penggemburan Tanah',
      'Mulching',
      'Transplanting',
      'Harvesting',
      'Lainnya',
    ];

    for (String jenis in jenisPerlakuanData) {
      await db.insert('dropdown_options', {
        'category': DropdownCategories.jenisPerlakuan,
        'value': jenis,
        'is_active': 1,
        'created_at': now,
      });
    }

    // Data default untuk Metode
    final metodeData = [
      'Manual',
      'Sprayer',
      'Drip Irrigation',
      'Sprinkler',
      'Foliar Application',
      'Soil Application',
      'Broadcasting',
      'Side Dressing',
      'Fertigation',
      'Organic Method',
    ];

    for (String metode in metodeData) {
      await db.insert('dropdown_options', {
        'category': DropdownCategories.metode,
        'value': metode,
        'is_active': 1,
        'created_at': now,
      });
    }
  }

  // CRUD Operations untuk Dropdown Options
  
  Future<List<DropdownOptionModel>> getDropdownOptions(String category, {bool activeOnly = true}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'dropdown_options',
      where: activeOnly ? 'category = ? AND is_active = 1' : 'category = ?',
      whereArgs: [category],
      orderBy: 'value ASC',
    );

    return List.generate(maps.length, (i) {
      return DropdownOptionModel.fromMap(maps[i]);
    });
  }

  Future<List<String>> getDropdownValues(String category, {bool activeOnly = true}) async {
    final options = await getDropdownOptions(category, activeOnly: activeOnly);
    return options.map((option) => option.value).toList();
  }

  Future<int> insertDropdownOption(DropdownOptionModel option) async {
    final db = await database;
    final optionWithTimestamp = option.copyWith(
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return await db.insert('dropdown_options', optionWithTimestamp.toMap());
  }

  Future<int> updateDropdownOption(DropdownOptionModel option) async {
    final db = await database;
    final optionWithTimestamp = option.copyWith(
      updatedAt: DateTime.now(),
    );
    return await db.update(
      'dropdown_options',
      optionWithTimestamp.toMap(),
      where: 'id = ?',
      whereArgs: [option.id],
    );
  }

  Future<int> deleteDropdownOption(int id) async {
    final db = await database;
    return await db.delete(
      'dropdown_options',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleDropdownOptionStatus(int id) async {
    final db = await database;
    
    // Get current status
    final List<Map<String, dynamic>> result = await db.query(
      'dropdown_options',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result.isEmpty) return 0;
    
    final currentStatus = result.first['is_active'] == 1;
    final newStatus = !currentStatus;
    
    return await db.update(
      'dropdown_options',
      {
        'is_active': newStatus ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> isValueExists(String category, String value, {int? excludeId}) async {
    final db = await database;
    String whereClause = 'category = ? AND value = ?';
    List<dynamic> whereArgs = [category, value];
    
    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }
    
    final List<Map<String, dynamic>> result = await db.query(
      'dropdown_options',
      where: whereClause,
      whereArgs: whereArgs,
    );
    
    return result.isNotEmpty;
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}