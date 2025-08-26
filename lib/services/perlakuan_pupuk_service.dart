import 'package:sqflite/sqflite.dart';
import '../models/perlakuan_pupuk_model.dart';
import 'package:uuid/uuid.dart';
import 'database_helper.dart';

class PerlakuanPupukService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String tableName = 'perlakuan_pupuk';
  final Uuid _uuid = const Uuid();

  // Get database instance
  Future<Database> get database async {
    final db = await _dbHelper.database;
    
    // Check if table exists, if not create it
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'"
    );
    
    if (tables.isEmpty) {
      await _createTable(db, 1);
    }
    
    return db;
  }

  Future<void> _createTable(Database db, int version) async {
    await db.execute(createTableQuery);
    await _insertDefaultData(db);
  }

  Future<void> _insertDefaultData(Database db) async {
    final defaultData = PerlakuanPupukModel.getDefaultData();
    
    for (final data in defaultData) {
      await db.insert(
        tableName,
        data,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // Create table
  static String get createTableQuery => '''
    CREATE TABLE $tableName (
      id_perlakuan TEXT PRIMARY KEY,
      kode_perlakuan TEXT NOT NULL UNIQUE,
      nama_perlakuan TEXT NOT NULL,
      deskripsi TEXT,
      is_aktif INTEGER NOT NULL DEFAULT 1,
      dibuat_pada TEXT NOT NULL,
      diupdate_pada TEXT,
      dibuat_oleh TEXT NOT NULL,
      diupdate_oleh TEXT
    )
  ''';

  // Get all perlakuan pupuk
  Future<List<PerlakuanPupukModel>> getAllPerlakuanPupuk() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'nama_perlakuan ASC',
    );

    return List.generate(maps.length, (i) {
      return PerlakuanPupukModel.fromMap(maps[i]);
    });
  }

  // Get active perlakuan pupuk
  Future<List<PerlakuanPupukModel>> getActivePerlakuanPupuk() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'is_aktif = ?',
      whereArgs: [1],
      orderBy: 'nama_perlakuan ASC',
    );

    return List.generate(maps.length, (i) {
      return PerlakuanPupukModel.fromMap(maps[i]);
    });
  }

  // Get perlakuan pupuk by ID
  Future<PerlakuanPupukModel?> getPerlakuanPupukById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id_perlakuan = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return PerlakuanPupukModel.fromMap(maps.first);
    }
    return null;
  }

  // Get perlakuan pupuk by kode
  Future<PerlakuanPupukModel?> getPerlakuanPupukByKode(String kode) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'kode_perlakuan = ?',
      whereArgs: [kode],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return PerlakuanPupukModel.fromMap(maps.first);
    }
    return null;
  }

  // Search perlakuan pupuk
  Future<List<PerlakuanPupukModel>> searchPerlakuanPupuk(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'kode_perlakuan LIKE ? OR nama_perlakuan LIKE ? OR deskripsi LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'nama_perlakuan ASC',
    );

    return List.generate(maps.length, (i) {
      return PerlakuanPupukModel.fromMap(maps[i]);
    });
  }

  // Add perlakuan pupuk
  Future<String> addPerlakuanPupuk({
    required String kodePerlakuan,
    required String namaPerlakuan,
    String? deskripsi,
    required String dibuatOleh,
  }) async {
    final db = await database;
    final id = _uuid.v4();
    
    // Check if kode already exists
    final existing = await getPerlakuanPupukByKode(kodePerlakuan);
    if (existing != null) {
      throw Exception('Kode perlakuan pupuk sudah ada');
    }

    final perlakuan = PerlakuanPupukModel(
      idPerlakuan: id,
      kodePerlakuan: kodePerlakuan,
      namaPerlakuan: namaPerlakuan,
      deskripsi: deskripsi,
      isAktif: true,
      dibuatPada: DateTime.now(),
      dibuatOleh: dibuatOleh,
    );

    await db.insert(tableName, perlakuan.toMap());
    return id;
  }

  // Update perlakuan pupuk
  Future<void> updatePerlakuanPupuk(
    String id,
    Map<String, dynamic> updateData,
  ) async {
    final db = await database;
    
    // Add update timestamp and user
    updateData['diupdate_pada'] = DateTime.now().toIso8601String();
    
    // Check if kode already exists (if kode is being updated)
    if (updateData.containsKey('kode_perlakuan')) {
      final existing = await getPerlakuanPupukByKode(updateData['kode_perlakuan']);
      if (existing != null && existing.idPerlakuan != id) {
        throw Exception('Kode perlakuan pupuk sudah ada');
      }
    }

    final result = await db.update(
      tableName,
      updateData,
      where: 'id_perlakuan = ?',
      whereArgs: [id],
    );

    if (result == 0) {
      throw Exception('Perlakuan pupuk tidak ditemukan');
    }
  }

  // Soft delete (set is_aktif = false)
  Future<void> softDeletePerlakuanPupuk(String id, String diupdateOleh) async {
    await updatePerlakuanPupuk(id, {
      'is_aktif': 0,
      'diupdate_oleh': diupdateOleh,
    });
  }

  // Restore (set is_aktif = true)
  Future<void> restorePerlakuanPupuk(String id, String diupdateOleh) async {
    await updatePerlakuanPupuk(id, {
      'is_aktif': 1,
      'diupdate_oleh': diupdateOleh,
    });
  }

  // Hard delete
  Future<void> deletePerlakuanPupuk(String id) async {
    final db = await database;
    
    final result = await db.delete(
      tableName,
      where: 'id_perlakuan = ?',
      whereArgs: [id],
    );

    if (result == 0) {
      throw Exception('Perlakuan pupuk tidak ditemukan');
    }
  }

  // Check if kode exists
  Future<bool> isKodeExists(String kode, {String? excludeId}) async {
    final db = await database;
    
    String whereClause = 'kode_perlakuan = ?';
    List<dynamic> whereArgs = [kode];
    
    if (excludeId != null) {
      whereClause += ' AND id_perlakuan != ?';
      whereArgs.add(excludeId);
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    return maps.isNotEmpty;
  }

  // Get count by status
  Future<Map<String, int>> getCountByStatus() async {
    final db = await database;
    
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
    final activeResult = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName WHERE is_aktif = 1');
    
    final total = totalResult.first['count'] as int;
    final active = activeResult.first['count'] as int;
    final inactive = total - active;
    
    return {
      'total': total,
      'active': active,
      'inactive': inactive,
    };
  }

  // Get dropdown options (kode)
  Future<List<String>> getDropdownKodeOptions() async {
    final activePerlakuan = await getActivePerlakuanPupuk();
    return activePerlakuan.map((p) => p.kodePerlakuan).toList();
  }

  // Get dropdown options (nama)
  Future<List<String>> getDropdownNamaOptions() async {
    final activePerlakuan = await getActivePerlakuanPupuk();
    return activePerlakuan.map((p) => p.namaPerlakuan).toList();
  }

  // Get dropdown options (display name)
  Future<List<String>> getDropdownDisplayOptions() async {
    final activePerlakuan = await getActivePerlakuanPupuk();
    return activePerlakuan.map((p) => p.displayName).toList();
  }
}