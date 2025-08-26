import 'package:sqflite/sqflite.dart';
import '../models/pengeluaran_harian_model.dart';
import 'database_helper.dart';

class PengeluaranService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  // Predefined categories
  static const List<String> kategoriPengeluaran = [
    'Listrik',
    'Bensin', 
    'Benih',
    'Rockwool',
    'Pupuk',
    'Lain-lain',
  ];

  // ========================================
  // KATEGORI METHODS
  // ========================================
  
  // Get predefined categories
  List<String> getAllKategori() {
    return kategoriPengeluaran;
  }

  // ========================================
  // PENGELUARAN HARIAN METHODS
  // ========================================

  // Get all expenses
  Future<List<PengeluaranHarianModel>> getAllPengeluaran() async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'pengeluaran_harian',
        orderBy: 'tanggal_pengeluaran DESC',
      );

      return List.generate(maps.length, (i) {
        return PengeluaranHarianModel.fromMap(maps[i]);
      });
    } catch (e) {
      throw Exception('Gagal mengambil data pengeluaran: $e');
    }
  }

  // Get expenses by date range
  Future<List<PengeluaranHarianModel>> getPengeluaranByTanggal(
      DateTime startDate, DateTime endDate) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'pengeluaran_harian',
        where: 'tanggal_pengeluaran >= ? AND tanggal_pengeluaran <= ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
        orderBy: 'tanggal_pengeluaran DESC',
      );

      return List.generate(maps.length, (i) {
        return PengeluaranHarianModel.fromMap(maps[i]);
      });
    } catch (e) {
      throw Exception('Gagal mengambil pengeluaran berdasarkan tanggal: $e');
    }
  }

  // Get expenses by category
  Future<List<PengeluaranHarianModel>> getPengeluaranByKategori(
      String kategori) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'pengeluaran_harian',
        where: 'kategori = ?',
        whereArgs: [kategori],
        orderBy: 'tanggal_pengeluaran DESC',
      );

      return List.generate(maps.length, (i) {
        return PengeluaranHarianModel.fromMap(maps[i]);
      });
    } catch (e) {
      throw Exception('Gagal mengambil pengeluaran berdasarkan kategori: $e');
    }
  }

  // Search expenses by description
  Future<List<PengeluaranHarianModel>> searchPengeluaran(String query) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'pengeluaran_harian',
        where: 'keterangan LIKE ? OR pemasok LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'tanggal_pengeluaran DESC',
      );

      return List.generate(maps.length, (i) {
        return PengeluaranHarianModel.fromMap(maps[i]);
      });
    } catch (e) {
      throw Exception('Gagal mencari pengeluaran: $e');
    }
  }

  // Get expense by ID
  Future<PengeluaranHarianModel?> getPengeluaranById(String id) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'pengeluaran_harian',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isNotEmpty) {
        return PengeluaranHarianModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil pengeluaran: $e');
    }
  }

  // Add new expense
  Future<int> tambahPengeluaran(PengeluaranHarianModel pengeluaran) async {
    try {
      final db = await _databaseHelper.database;
      final id = await db.insert('pengeluaran_harian', pengeluaran.toMapForInsert());
      return id;
    } catch (e) {
      throw Exception('Gagal menambah pengeluaran: $e');
    }
  }

  // Update expense
  Future<void> updatePengeluaran(String id, PengeluaranHarianModel pengeluaran) async {
    try {
      final db = await _databaseHelper.database;
      // Create map without id for update
      final updateMap = pengeluaran.toMapForInsert();
      await db.update(
        'pengeluaran_harian',
        updateMap,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Gagal mengupdate pengeluaran: $e');
    }
  }

  // Delete expense
  Future<void> hapusPengeluaran(String id) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(
        'pengeluaran_harian',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Gagal menghapus pengeluaran: $e');
    }
  }

  // Get total expenses by date range
  Future<double> getTotalPengeluaranByTanggal(
      DateTime startDate, DateTime endDate) async {
    try {
      final pengeluaranList = await getPengeluaranByTanggal(startDate, endDate);
      return pengeluaranList.fold<double>(0.0, (double sum, PengeluaranHarianModel item) => sum + item.jumlah);
    } catch (e) {
      throw Exception('Gagal menghitung total pengeluaran: $e');
    }
  }

  // Get total expenses by category
  Future<double> getTotalPengeluaranByKategori(String kategori) async {
    try {
      final pengeluaranList = await getPengeluaranByKategori(kategori);
      return pengeluaranList.fold<double>(0.0, (double sum, PengeluaranHarianModel item) => sum + item.jumlah);
    } catch (e) {
      throw Exception('Gagal menghitung total pengeluaran kategori: $e');
    }
  }
}