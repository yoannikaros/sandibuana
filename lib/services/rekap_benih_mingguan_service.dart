import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rekap_benih_mingguan_model.dart';

class RekapBenihMingguanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'rekap_benih_mingguan';

  // Create - Tambah rekap benih mingguan baru
  Future<String> addRekapBenihMingguan(RekapBenihMingguanModel rekap) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(rekap.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Gagal menambah rekap benih mingguan: $e');
    }
  }

  // Read - Ambil semua rekap benih mingguan
  Future<List<RekapBenihMingguanModel>> getAllRekapBenihMingguan() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('tanggal_mulai', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => RekapBenihMingguanModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data rekap benih mingguan: $e');
    }
  }

  // Read - Ambil rekap benih mingguan berdasarkan ID
  Future<RekapBenihMingguanModel?> getRekapBenihMingguanById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return RekapBenihMingguanModel.fromFirestore(doc, null);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil rekap benih mingguan: $e');
    }
  }

  // Read - Ambil rekap benih mingguan berdasarkan catatan pembenihan
  Future<List<RekapBenihMingguanModel>> getRekapBenihMingguanByPembenihan(String idPembenihan) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('id_pembenihan', isEqualTo: idPembenihan)
          .orderBy('tanggal_mulai', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => RekapBenihMingguanModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil rekap benih mingguan berdasarkan pembenihan: $e');
    }
  }

  // Read - Ambil rekap benih mingguan berdasarkan rentang tanggal
  Future<List<RekapBenihMingguanModel>> getRekapBenihMingguanByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('tanggal_mulai', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('tanggal_mulai', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('tanggal_mulai', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => RekapBenihMingguanModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil rekap benih mingguan berdasarkan rentang tanggal: $e');
    }
  }

  // Read - Ambil rekap benih mingguan minggu ini
  Future<List<RekapBenihMingguanModel>> getRekapBenihMingguanThisWeek() async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('tanggal_mulai', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .where('tanggal_mulai', isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek))
          .orderBy('tanggal_mulai', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => RekapBenihMingguanModel.fromFirestore(doc, null))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil rekap benih mingguan minggu ini: $e');
    }
  }

  // Read - Ambil rekap benih mingguan bulan ini
  Future<List<RekapBenihMingguanModel>> getRekapBenihMingguanThisMonth() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);
      
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('tanggal_mulai', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('tanggal_mulai', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .orderBy('tanggal_mulai', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => RekapBenihMingguanModel.fromFirestore(doc, null))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil rekap benih mingguan bulan ini: $e');
    }
  }

  // Update - Perbarui rekap benih mingguan
  Future<void> updateRekapBenihMingguan(String id, RekapBenihMingguanModel rekap) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(id)
          .update(rekap.toFirestore());
    } catch (e) {
      throw Exception('Gagal memperbarui rekap benih mingguan: $e');
    }
  }

  // Delete - Hapus rekap benih mingguan
  Future<void> deleteRekapBenihMingguan(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Gagal menghapus rekap benih mingguan: $e');
    }
  }

  // Stream - Real-time data rekap benih mingguan
  Stream<List<RekapBenihMingguanModel>> streamRekapBenihMingguan() {
    return _firestore
        .collection(_collection)
        .orderBy('tanggal_mulai', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RekapBenihMingguanModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Stream - Real-time data rekap benih mingguan berdasarkan filter
  Stream<List<RekapBenihMingguanModel>> streamRekapBenihMingguanByFilter({
    String? idPembenihan,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _firestore.collection(_collection);
    
    if (idPembenihan != null) {
      query = query.where('id_pembenihan', isEqualTo: idPembenihan);
    }
    
    if (startDate != null) {
      query = query.where('tanggal_mulai', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    
    if (endDate != null) {
      query = query.where('tanggal_mulai', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }
    
    return query
        .orderBy('tanggal_mulai', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RekapBenihMingguanModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Analytics - Statistik rekap benih mingguan
  Future<Map<String, dynamic>> getStatistikRekapBenihMingguan() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      final rekaps = querySnapshot.docs
          .map((doc) => RekapBenihMingguanModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      if (rekaps.isEmpty) {
        return {
          'total_rekap': 0,
          'total_nampan': 0,
          'rata_rata_nampan': 0.0,
          'pembenihan_terpopuler': '',
          'distribusi_pembenihan': <String, int>{},
        };
      }

      final totalRekap = rekaps.length;
      final totalNampan = rekaps.fold<int>(0, (sum, rekap) => sum + rekap.jumlahNampan);
      final rataRataNampan = totalNampan / totalRekap;

      // Distribusi per catatan pembenihan
      final distribusiPembenihan = <String, int>{};
      for (final rekap in rekaps) {
        if (rekap.idPembenihan != null) {
          distribusiPembenihan[rekap.idPembenihan!] = 
              (distribusiPembenihan[rekap.idPembenihan!] ?? 0) + rekap.jumlahNampan;
        }
      }

      // Pembenihan terpopuler
      String pembenihanTerpopuler = '';
      int maxNampan = 0;
      distribusiPembenihan.forEach((idPembenihan, jumlah) {
        if (jumlah > maxNampan) {
          maxNampan = jumlah;
          pembenihanTerpopuler = idPembenihan;
        }
      });

      return {
        'total_rekap': totalRekap,
        'total_nampan': totalNampan,
        'rata_rata_nampan': rataRataNampan,
        'pembenihan_terpopuler': pembenihanTerpopuler,
        'distribusi_pembenihan': distribusiPembenihan,
      };
    } catch (e) {
      throw Exception('Gagal mengambil statistik rekap benih mingguan: $e');
    }
  }

  // Analytics - Statistik rekap benih mingguan berdasarkan periode
  Future<Map<String, dynamic>> getStatistikRekapBenihMingguanByPeriode(
      DateTime startDate, DateTime endDate) async {
    try {
      final rekaps = await getRekapBenihMingguanByDateRange(startDate, endDate);

      if (rekaps.isEmpty) {
        return {
          'total_rekap': 0,
          'total_nampan': 0,
          'rata_rata_nampan': 0.0,
          'pembenihan_terpopuler': '',
          'distribusi_pembenihan': <String, int>{},
        };
      }

      final totalRekap = rekaps.length;
      final totalNampan = rekaps.fold<int>(0, (sum, rekap) => sum + rekap.jumlahNampan);
      final rataRataNampan = totalNampan / totalRekap;

      // Distribusi per catatan pembenihan
      final distribusiPembenihan = <String, int>{};
      for (final rekap in rekaps) {
        if (rekap.idPembenihan != null) {
          distribusiPembenihan[rekap.idPembenihan!] = 
              (distribusiPembenihan[rekap.idPembenihan!] ?? 0) + rekap.jumlahNampan;
        }
      }

      // Pembenihan terpopuler
      String pembenihanTerpopuler = '';
      int maxNampan = 0;
      distribusiPembenihan.forEach((idPembenihan, jumlah) {
        if (jumlah > maxNampan) {
          maxNampan = jumlah;
          pembenihanTerpopuler = idPembenihan;
        }
      });

      return {
        'total_rekap': totalRekap,
        'total_nampan': totalNampan,
        'rata_rata_nampan': rataRataNampan,
        'pembenihan_terpopuler': pembenihanTerpopuler,
        'distribusi_pembenihan': distribusiPembenihan,
      };
    } catch (e) {
      throw Exception('Gagal mengambil statistik rekap benih mingguan berdasarkan periode: $e');
    }
  }
}