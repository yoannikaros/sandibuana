import 'package:sqflite/sqflite.dart';
import '../models/tipe_pupuk_model.dart';
import 'database_helper.dart';

class TipePupukService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String _tableName = 'tipe_pupuk';

  Future<Database> get database async {
    final db = await _dbHelper.database;
    
    // Check if table exists, if not create it
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='$_tableName'"
    );
    
    if (tables.isEmpty) {
      await _createTable(db, 1);
    }
    
    return db;
  }

  Future<void> _createTable(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL UNIQUE,
        kode TEXT NOT NULL UNIQUE,
        deskripsi TEXT,
        aktif INTEGER NOT NULL DEFAULT 1,
        dibuat_pada INTEGER NOT NULL,
        diubah_pada INTEGER
      )
    ''');

    // Insert data default
    await _insertDefaultData(db);
  }

  Future<void> _insertDefaultData(Database db) async {
    final defaultData = [
      {
        'nama': 'Makro',
        'kode': 'makro',
        'deskripsi': 'Pupuk dengan unsur hara makro (NPK)',
        'aktif': 1,
        'dibuat_pada': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'nama': 'Mikro',
        'kode': 'mikro',
        'deskripsi': 'Pupuk dengan unsur hara mikro',
        'aktif': 1,
        'dibuat_pada': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'nama': 'Organik',
        'kode': 'organik',
        'deskripsi': 'Pupuk berbahan dasar organik',
        'aktif': 1,
        'dibuat_pada': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'nama': 'Kimia',
        'kode': 'kimia',
        'deskripsi': 'Pupuk kimia sintetis',
        'aktif': 1,
        'dibuat_pada': DateTime.now().millisecondsSinceEpoch,
      },
    ];

    for (var data in defaultData) {
      await db.insert(_tableName, data);
    }
  }

  // CREATE - Tambah tipe pupuk baru
  Future<int> tambahTipePupuk(TipePupukModel tipePupuk) async {
    final db = await database;
    
    // Cek duplikasi nama atau kode
    final existing = await db.query(
      _tableName,
      where: 'nama = ? OR kode = ?',
      whereArgs: [tipePupuk.nama, tipePupuk.kode],
    );
    
    if (existing.isNotEmpty) {
      throw Exception('Nama atau kode tipe pupuk sudah ada');
    }
    
    final data = tipePupuk.copyWith(
      dibuatPada: DateTime.now(),
    ).toMap();
    data.remove('id'); // Remove id for auto increment
    
    return await db.insert(_tableName, data);
  }

  // READ - Ambil semua tipe pupuk
  Future<List<TipePupukModel>> getAllTipePupuk() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'nama ASC',
    );

    return List.generate(maps.length, (i) {
      return TipePupukModel.fromMap(maps[i]);
    });
  }

  // READ - Ambil tipe pupuk aktif saja
  Future<List<TipePupukModel>> getTipePupukAktif() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'aktif = ?',
      whereArgs: [1],
      orderBy: 'nama ASC',
    );

    return List.generate(maps.length, (i) {
      return TipePupukModel.fromMap(maps[i]);
    });
  }

  // READ - Ambil tipe pupuk berdasarkan ID
  Future<TipePupukModel?> getTipePupukById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return TipePupukModel.fromMap(maps.first);
    }
    return null;
  }

  // UPDATE - Update tipe pupuk
  Future<void> updateTipePupuk(int id, TipePupukModel tipePupuk) async {
    final db = await database;
    
    // Cek duplikasi nama atau kode (kecuali untuk record yang sedang diupdate)
    final existing = await db.query(
      _tableName,
      where: '(nama = ? OR kode = ?) AND id != ?',
      whereArgs: [tipePupuk.nama, tipePupuk.kode, id],
    );
    
    if (existing.isNotEmpty) {
      throw Exception('Nama atau kode tipe pupuk sudah ada');
    }
    
    final data = tipePupuk.copyWith(
      id: id,
      diubahPada: DateTime.now(),
    ).toMap();
    
    await db.update(
      _tableName,
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DELETE - Hapus tipe pupuk (soft delete)
  Future<void> hapusTipePupuk(int id) async {
    final db = await database;
    await db.update(
      _tableName,
      {
        'aktif': 0,
        'diubah_pada': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DELETE - Hapus tipe pupuk permanen
  Future<void> hapusTipePupukPermanen(int id) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // UTILITY - Cari tipe pupuk berdasarkan nama
  Future<List<TipePupukModel>> cariTipePupuk(String keyword) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'nama LIKE ? OR kode LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'nama ASC',
    );

    return List.generate(maps.length, (i) {
      return TipePupukModel.fromMap(maps[i]);
    });
  }

  // UTILITY - Restore tipe pupuk yang dihapus
  Future<void> restoreTipePupuk(int id) async {
    final db = await database;
    await db.update(
      _tableName,
      {
        'aktif': 1,
        'diubah_pada': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // UTILITY - Ambil daftar kode untuk dropdown
  Future<List<String>> getKodeTipePupuk() async {
    final tipePupukList = await getTipePupukAktif();
    return tipePupukList.map((tipe) => tipe.kode).toList();
  }
}