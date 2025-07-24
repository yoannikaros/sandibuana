import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/jenis_pelanggan_model.dart';

class JenisPelangganService {
  static Database? _database;
  static const String _tableName = 'jenis_pelanggan';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'jenis_pelanggan.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createTable,
    );
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
        'nama': 'Restoran',
        'kode': 'restoran',
        'deskripsi': 'Pelanggan restoran dan rumah makan',
        'aktif': 1,
        'dibuat_pada': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'nama': 'Hotel',
        'kode': 'hotel',
        'deskripsi': 'Pelanggan hotel dan penginapan',
        'aktif': 1,
        'dibuat_pada': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'nama': 'Individu',
        'kode': 'individu',
        'deskripsi': 'Pelanggan perorangan',
        'aktif': 1,
        'dibuat_pada': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'nama': 'Grosir',
        'kode': 'grosir',
        'deskripsi': 'Pelanggan grosir dan distributor',
        'aktif': 1,
        'dibuat_pada': DateTime.now().millisecondsSinceEpoch,
      },
    ];

    for (var data in defaultData) {
      await db.insert(_tableName, data);
    }
  }

  // CREATE - Tambah jenis pelanggan baru
  Future<int> tambahJenisPelanggan(JenisPelangganModel jenisPelanggan) async {
    final db = await database;
    
    // Cek duplikasi nama atau kode
    final existing = await db.query(
      _tableName,
      where: 'nama = ? OR kode = ?',
      whereArgs: [jenisPelanggan.nama, jenisPelanggan.kode],
    );
    
    if (existing.isNotEmpty) {
      throw Exception('Nama atau kode jenis pelanggan sudah ada');
    }
    
    final data = jenisPelanggan.copyWith(
      dibuatPada: DateTime.now(),
    ).toMap();
    data.remove('id'); // Remove id for auto increment
    
    return await db.insert(_tableName, data);
  }

  // READ - Ambil semua jenis pelanggan
  Future<List<JenisPelangganModel>> getAllJenisPelanggan() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'nama ASC',
    );

    return List.generate(maps.length, (i) {
      return JenisPelangganModel.fromMap(maps[i]);
    });
  }

  // READ - Ambil jenis pelanggan aktif saja
  Future<List<JenisPelangganModel>> getJenisPelangganAktif() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'aktif = ?',
      whereArgs: [1],
      orderBy: 'nama ASC',
    );

    return List.generate(maps.length, (i) {
      return JenisPelangganModel.fromMap(maps[i]);
    });
  }

  // READ - Ambil jenis pelanggan berdasarkan ID
  Future<JenisPelangganModel?> getJenisPelangganById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return JenisPelangganModel.fromMap(maps.first);
    }
    return null;
  }

  // UPDATE - Update jenis pelanggan
  Future<void> updateJenisPelanggan(int id, JenisPelangganModel jenisPelanggan) async {
    final db = await database;
    
    // Cek duplikasi nama atau kode (kecuali untuk record yang sedang diupdate)
    final existing = await db.query(
      _tableName,
      where: '(nama = ? OR kode = ?) AND id != ?',
      whereArgs: [jenisPelanggan.nama, jenisPelanggan.kode, id],
    );
    
    if (existing.isNotEmpty) {
      throw Exception('Nama atau kode jenis pelanggan sudah ada');
    }
    
    final data = jenisPelanggan.copyWith(
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

  // DELETE - Hapus jenis pelanggan (soft delete)
  Future<void> hapusJenisPelanggan(int id) async {
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

  // DELETE - Hapus jenis pelanggan permanen
  Future<void> hapusJenisPelangganPermanen(int id) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // UTILITY - Cari jenis pelanggan berdasarkan nama
  Future<List<JenisPelangganModel>> cariJenisPelanggan(String keyword) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'nama LIKE ? OR kode LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'nama ASC',
    );

    return List.generate(maps.length, (i) {
      return JenisPelangganModel.fromMap(maps[i]);
    });
  }

  // UTILITY - Restore jenis pelanggan yang dihapus
  Future<void> restoreJenisPelanggan(int id) async {
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
  Future<List<String>> getKodeJenisPelanggan() async {
    final jenisPelangganList = await getJenisPelangganAktif();
    return jenisPelangganList.map((jenis) => jenis.kode).toList();
  }
}