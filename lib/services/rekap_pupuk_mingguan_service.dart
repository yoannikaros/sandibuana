import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rekap_pupuk_mingguan_model.dart';

class RekapPupukMingguanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'rekap_pupuk_mingguan';

  // Add new weekly fertilizer recap
  Future<String> tambahRekapPupukMingguan(RekapPupukMingguanModel rekap) async {
    try {
      final docRef = await _firestore.collection(_collection).add(rekap.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Gagal menambah rekap pupuk mingguan: $e');
    }
  }

  // Get all weekly fertilizer recaps
  Future<List<RekapPupukMingguanModel>> getAllRekapPupukMingguan() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('tanggal_mulai', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => RekapPupukMingguanModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data rekap pupuk mingguan: $e');
    }
  }

  // Get recap by ID
  Future<RekapPupukMingguanModel?> getRekapPupukMingguanById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return RekapPupukMingguanModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil rekap pupuk mingguan: $e');
    }
  }

  // Get recaps by tandon
  Future<List<RekapPupukMingguanModel>> getRekapByTandon(String idTandon) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('id_tandon', isEqualTo: idTandon)
          .orderBy('tanggal_mulai', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => RekapPupukMingguanModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil rekap pupuk mingguan berdasarkan tandon: $e');
    }
  }

  // Get recaps by fertilizer type
  Future<List<RekapPupukMingguanModel>> getRekapByPupuk(String idPupuk) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('id_pupuk', isEqualTo: idPupuk)
          .orderBy('tanggal_mulai', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => RekapPupukMingguanModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil rekap pupuk mingguan berdasarkan pupuk: $e');
    }
  }

  // Get recaps by date range
  Future<List<RekapPupukMingguanModel>> getRekapByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('tanggal_mulai', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('tanggal_selesai', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('tanggal_mulai', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => RekapPupukMingguanModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil rekap pupuk mingguan berdasarkan tanggal: $e');
    }
  }

  // Get recaps with leak indication
  Future<List<RekapPupukMingguanModel>> getRekapWithLeakIndication() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('indikasi_bocor', isEqualTo: true)
          .orderBy('tanggal_mulai', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => RekapPupukMingguanModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil rekap dengan indikasi bocor: $e');
    }
  }

  // Get this week's recaps
  Future<List<RekapPupukMingguanModel>> getRekapMingguIni() async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      
      return await getRekapByDateRange(startOfWeek, endOfWeek);
    } catch (e) {
      throw Exception('Gagal mengambil rekap minggu ini: $e');
    }
  }

  // Get this month's recaps
  Future<List<RekapPupukMingguanModel>> getRekapBulanIni() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);
      
      return await getRekapByDateRange(startOfMonth, endOfMonth);
    } catch (e) {
      throw Exception('Gagal mengambil rekap bulan ini: $e');
    }
  }

  // Update recap
  Future<void> updateRekapPupukMingguan(String id, RekapPupukMingguanModel rekap) async {
    try {
      await _firestore.collection(_collection).doc(id).update(rekap.toFirestore());
    } catch (e) {
      throw Exception('Gagal mengupdate rekap pupuk mingguan: $e');
    }
  }

  // Delete recap
  Future<void> hapusRekapPupukMingguan(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Gagal menghapus rekap pupuk mingguan: $e');
    }
  }

  // Stream for real-time updates
  Stream<List<RekapPupukMingguanModel>> streamRekapPupukMingguan() {
    return _firestore
        .collection(_collection)
        .orderBy('tanggal_mulai', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RekapPupukMingguanModel.fromFirestore(doc))
            .toList());
  }

  // Stream by tandon
  Stream<List<RekapPupukMingguanModel>> streamRekapByTandon(String idTandon) {
    return _firestore
        .collection(_collection)
        .where('id_tandon', isEqualTo: idTandon)
        .orderBy('tanggal_mulai', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RekapPupukMingguanModel.fromFirestore(doc))
            .toList());
  }

  // Get statistics for analytics
  Future<Map<String, dynamic>> getStatistik() async {
    try {
      final allRecaps = await getAllRekapPupukMingguan();
      
      final totalRecaps = allRecaps.length;
      final leakRecaps = allRecaps.where((r) => r.indikasiBocor == true).length;
      final normalRecaps = allRecaps.where((r) => r.indikasiBocor != true).length;
      
      final totalFertilizerUsed = allRecaps.fold<double>(
        0.0, 
        (sum, recap) => sum + recap.jumlahDigunakan
      );
      
      final averageUsage = totalRecaps > 0 ? totalFertilizerUsed / totalRecaps : 0.0;
      
      // Group by tandon
      final Map<String, List<RekapPupukMingguanModel>> byTandon = {};
      for (final recap in allRecaps) {
        byTandon.putIfAbsent(recap.idTandon, () => []).add(recap);
      }
      
      // Group by pupuk
      final Map<String, List<RekapPupukMingguanModel>> byPupuk = {};
      for (final recap in allRecaps) {
        byPupuk.putIfAbsent(recap.idPupuk, () => []).add(recap);
      }
      
      return {
        'totalRecaps': totalRecaps,
        'leakRecaps': leakRecaps,
        'normalRecaps': normalRecaps,
        'leakPercentage': totalRecaps > 0 ? (leakRecaps / totalRecaps * 100) : 0.0,
        'totalFertilizerUsed': totalFertilizerUsed,
        'averageUsage': averageUsage,
        'tandonCount': byTandon.length,
        'pupukCount': byPupuk.length,
        'byTandon': byTandon.map((key, value) => MapEntry(key, {
          'count': value.length,
          'totalUsage': value.fold<double>(0.0, (sum, r) => sum + r.jumlahDigunakan),
          'leakCount': value.where((r) => r.indikasiBocor == true).length,
        })),
        'byPupuk': byPupuk.map((key, value) => MapEntry(key, {
          'count': value.length,
          'totalUsage': value.fold<double>(0.0, (sum, r) => sum + r.jumlahDigunakan),
          'leakCount': value.where((r) => r.indikasiBocor == true).length,
        })),
      };
    } catch (e) {
      throw Exception('Gagal mengambil statistik: $e');
    }
  }

  // Calculate expected usage based on tank capacity and standard formula
  double calculateExpectedUsage(double tankCapacity, String fertilizerType) {
    // Standard formula: capacity (L) * concentration factor
    // This is a simplified calculation, adjust based on actual requirements
    switch (fertilizerType.toLowerCase()) {
      case 'cef':
        return tankCapacity * 0.002; // 2ml per liter
      case 'coklat':
        return tankCapacity * 0.0015; // 1.5ml per liter
      case 'putih':
        return tankCapacity * 0.001; // 1ml per liter
      default:
        return tankCapacity * 0.001; // Default 1ml per liter
    }
  }

  // Analyze potential leaks for a specific tandon
  Future<Map<String, dynamic>> analyzeLeakForTandon(String idTandon) async {
    try {
      final recaps = await getRekapByTandon(idTandon);
      
      if (recaps.isEmpty) {
        return {
          'hasData': false,
          'message': 'Tidak ada data untuk tandon ini'
        };
      }
      
      final recentRecaps = recaps.take(4).toList(); // Last 4 weeks
      final leakCount = recentRecaps.where((r) => r.indikasiBocor == true).length;
      final totalUsage = recentRecaps.fold<double>(0.0, (sum, r) => sum + r.jumlahDigunakan);
      final averageUsage = totalUsage / recentRecaps.length;
      
      // Calculate trend
      final usageValues = recentRecaps.map((r) => r.jumlahDigunakan).toList();
      final isIncreasingTrend = usageValues.length > 1 && 
          usageValues.first > usageValues.last;
      
      return {
        'hasData': true,
        'tandonId': idTandon,
        'totalRecaps': recentRecaps.length,
        'leakCount': leakCount,
        'leakPercentage': (leakCount / recentRecaps.length * 100),
        'averageUsage': averageUsage,
        'totalUsage': totalUsage,
        'isIncreasingTrend': isIncreasingTrend,
        'riskLevel': _calculateRiskLevel(leakCount, recentRecaps.length, isIncreasingTrend),
        'recommendation': _getRecommendation(leakCount, recentRecaps.length, isIncreasingTrend),
      };
    } catch (e) {
      throw Exception('Gagal menganalisis kebocoran untuk tandon: $e');
    }
  }

  String _calculateRiskLevel(int leakCount, int totalRecaps, bool isIncreasingTrend) {
    final leakPercentage = leakCount / totalRecaps * 100;
    
    if (leakPercentage >= 75 || (leakPercentage >= 50 && isIncreasingTrend)) {
      return 'Tinggi';
    } else if (leakPercentage >= 25 || isIncreasingTrend) {
      return 'Sedang';
    } else {
      return 'Rendah';
    }
  }

  String _getRecommendation(int leakCount, int totalRecaps, bool isIncreasingTrend) {
    final leakPercentage = leakCount / totalRecaps * 100;
    
    if (leakPercentage >= 75) {
      return 'Segera lakukan inspeksi menyeluruh dan perbaikan tandon';
    } else if (leakPercentage >= 50) {
      return 'Lakukan pemeriksaan detail pada sistem tandon';
    } else if (leakPercentage >= 25 || isIncreasingTrend) {
      return 'Monitor lebih ketat dan periksa kondisi tandon';
    } else {
      return 'Kondisi tandon dalam keadaan baik';
    }
  }
}