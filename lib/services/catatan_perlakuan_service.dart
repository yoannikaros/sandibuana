import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/catatan_perlakuan_model.dart';

class CatatanPerlakuanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'catatan_perlakuan';

  // Tambah catatan perlakuan baru
  Future<String> tambahCatatanPerlakuan({
    required DateTime tanggalPerlakuan,
    String? idJadwal,
    required String jenisPerlakuan,
    String? areaTanaman,
    String? bahanDigunakan,
    double? jumlahDigunakan,
    String? satuan,
    String? metode,
    String? kondisiCuaca,
    int? ratingEfektivitas,
    String? catatan,
    required String dicatatOleh,
  }) async {
    try {
      final perlakuan = CatatanPerlakuanModel(
        idPerlakuan: '',
        tanggalPerlakuan: tanggalPerlakuan,
        idJadwal: idJadwal,
        jenisPerlakuan: jenisPerlakuan,
        areaTanaman: areaTanaman,
        bahanDigunakan: bahanDigunakan,
        jumlahDigunakan: jumlahDigunakan,
        satuan: satuan,
        metode: metode,
        kondisiCuaca: kondisiCuaca,
        ratingEfektivitas: ratingEfektivitas,
        catatan: catatan,
        dicatatOleh: dicatatOleh,
        dicatatPada: DateTime.now(),
      );

      // Validasi data
      final validationError = perlakuan.validate();
      if (validationError != null) {
        throw Exception(validationError);
      }

      final docRef = await _firestore.collection(_collection).add(perlakuan.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Gagal menambahkan catatan perlakuan: $e');
    }
  }

  // Ambil semua catatan perlakuan
  Future<List<CatatanPerlakuanModel>> getAllCatatanPerlakuan() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('dicatat_pada', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CatatanPerlakuanModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data catatan perlakuan: $e');
    }
  }

  // Ambil catatan perlakuan berdasarkan tanggal
  Future<List<CatatanPerlakuanModel>> getCatatanPerlakuanByTanggal(DateTime tanggal) async {
    try {
      final startOfDay = DateTime(tanggal.year, tanggal.month, tanggal.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('tanggal_perlakuan', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('tanggal_perlakuan', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('tanggal_perlakuan')
          .orderBy('dicatat_pada', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CatatanPerlakuanModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil catatan perlakuan tanggal ${tanggal.day}/${tanggal.month}/${tanggal.year}: $e');
    }
  }

  // Ambil catatan perlakuan berdasarkan range tanggal
  Future<List<CatatanPerlakuanModel>> getCatatanPerlakuanByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('tanggal_perlakuan', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('tanggal_perlakuan', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('tanggal_perlakuan', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CatatanPerlakuanModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil catatan perlakuan berdasarkan range tanggal: $e');
    }
  }

  // Ambil catatan perlakuan berdasarkan jenis perlakuan
  Future<List<CatatanPerlakuanModel>> getCatatanPerlakuanByJenis(String jenisPerlakuan) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('jenis_perlakuan', isEqualTo: jenisPerlakuan)
          .orderBy('tanggal_perlakuan', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CatatanPerlakuanModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil catatan perlakuan jenis $jenisPerlakuan: $e');
    }
  }

  // Ambil catatan perlakuan berdasarkan area tanaman
  Future<List<CatatanPerlakuanModel>> getCatatanPerlakuanByArea(String areaTanaman) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('area_tanaman', isEqualTo: areaTanaman)
          .orderBy('tanggal_perlakuan', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CatatanPerlakuanModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil catatan perlakuan area $areaTanaman: $e');
    }
  }

  // Ambil catatan perlakuan berdasarkan rating
  Future<List<CatatanPerlakuanModel>> getCatatanPerlakuanByRating(int rating) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('rating_efektivitas', isEqualTo: rating)
          .orderBy('tanggal_perlakuan', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CatatanPerlakuanModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil catatan perlakuan rating $rating: $e');
    }
  }

  // Ambil catatan perlakuan berdasarkan jadwal
  Future<List<CatatanPerlakuanModel>> getCatatanPerlakuanByJadwal(String idJadwal) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('id_jadwal', isEqualTo: idJadwal)
          .orderBy('tanggal_perlakuan', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CatatanPerlakuanModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil catatan perlakuan jadwal $idJadwal: $e');
    }
  }

  // Update catatan perlakuan
  Future<void> updateCatatanPerlakuan(
    String idPerlakuan,
    Map<String, dynamic> updateData,
  ) async {
    try {
      await _firestore.collection(_collection).doc(idPerlakuan).update(updateData);
    } catch (e) {
      throw Exception('Gagal mengupdate catatan perlakuan: $e');
    }
  }

  // Hapus catatan perlakuan
  Future<void> hapusCatatanPerlakuan(String idPerlakuan) async {
    try {
      await _firestore.collection(_collection).doc(idPerlakuan).delete();
    } catch (e) {
      throw Exception('Gagal menghapus catatan perlakuan: $e');
    }
  }

  // Statistik perlakuan berdasarkan jenis
  Future<Map<String, dynamic>> getStatistikByJenis() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      final List<CatatanPerlakuanModel> allPerlakuan = querySnapshot.docs
          .map((doc) => CatatanPerlakuanModel.fromFirestore(doc))
          .toList();

      Map<String, int> jenisCount = {};
      Map<String, List<int>> jenisRatings = {};

      for (final perlakuan in allPerlakuan) {
        jenisCount[perlakuan.jenisPerlakuan] = (jenisCount[perlakuan.jenisPerlakuan] ?? 0) + 1;
        
        if (perlakuan.ratingEfektivitas != null) {
          jenisRatings[perlakuan.jenisPerlakuan] ??= [];
          jenisRatings[perlakuan.jenisPerlakuan]!.add(perlakuan.ratingEfektivitas!);
        }
      }

      Map<String, double> jenisAvgRating = {};
      jenisRatings.forEach((jenis, ratings) {
        if (ratings.isNotEmpty) {
          jenisAvgRating[jenis] = ratings.reduce((a, b) => a + b) / ratings.length;
        }
      });

      return {
        'total_perlakuan': allPerlakuan.length,
        'jenis_count': jenisCount,
        'jenis_avg_rating': jenisAvgRating,
      };
    } catch (e) {
      throw Exception('Gagal mengambil statistik perlakuan: $e');
    }
  }

  // Statistik perlakuan berdasarkan area
  Future<Map<String, dynamic>> getStatistikByArea() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      final List<CatatanPerlakuanModel> allPerlakuan = querySnapshot.docs
          .map((doc) => CatatanPerlakuanModel.fromFirestore(doc))
          .toList();

      Map<String, int> areaCount = {};
      Map<String, List<int>> areaRatings = {};

      for (final perlakuan in allPerlakuan) {
        final area = perlakuan.areaTanaman ?? 'Tidak Ditentukan';
        areaCount[area] = (areaCount[area] ?? 0) + 1;
        
        if (perlakuan.ratingEfektivitas != null) {
          areaRatings[area] ??= [];
          areaRatings[area]!.add(perlakuan.ratingEfektivitas!);
        }
      }

      Map<String, double> areaAvgRating = {};
      areaRatings.forEach((area, ratings) {
        if (ratings.isNotEmpty) {
          areaAvgRating[area] = ratings.reduce((a, b) => a + b) / ratings.length;
        }
      });

      return {
        'area_count': areaCount,
        'area_avg_rating': areaAvgRating,
      };
    } catch (e) {
      throw Exception('Gagal mengambil statistik area: $e');
    }
  }

  // Statistik perlakuan bulanan
  Future<Map<String, dynamic>> getStatistikBulanan(DateTime bulanTahun) async {
    try {
      final startOfMonth = DateTime(bulanTahun.year, bulanTahun.month, 1);
      final endOfMonth = DateTime(bulanTahun.year, bulanTahun.month + 1, 1).subtract(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('tanggal_perlakuan', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('tanggal_perlakuan', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      final List<CatatanPerlakuanModel> perlakuanBulan = querySnapshot.docs
          .map((doc) => CatatanPerlakuanModel.fromFirestore(doc))
          .toList();

      int totalPerlakuan = perlakuanBulan.length;
      int perlakuanDenganRating = perlakuanBulan.where((p) => p.ratingEfektivitas != null).length;
      
      double avgRating = 0;
      if (perlakuanDenganRating > 0) {
        final totalRating = perlakuanBulan
            .where((p) => p.ratingEfektivitas != null)
            .map((p) => p.ratingEfektivitas!)
            .reduce((a, b) => a + b);
        avgRating = totalRating / perlakuanDenganRating;
      }

      Map<String, int> jenisCount = {};
      for (final perlakuan in perlakuanBulan) {
        jenisCount[perlakuan.jenisPerlakuan] = (jenisCount[perlakuan.jenisPerlakuan] ?? 0) + 1;
      }

      return {
        'bulan_tahun': '${bulanTahun.month}/${bulanTahun.year}',
        'total_perlakuan': totalPerlakuan,
        'perlakuan_dengan_rating': perlakuanDenganRating,
        'rata_rata_rating': avgRating,
        'jenis_count': jenisCount,
      };
    } catch (e) {
      throw Exception('Gagal mengambil statistik bulanan: $e');
    }
  }

  // Laporan efektivitas perlakuan
  Future<Map<String, dynamic>> getLaporanEfektivitas() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      final List<CatatanPerlakuanModel> allPerlakuan = querySnapshot.docs
          .map((doc) => CatatanPerlakuanModel.fromFirestore(doc))
          .toList();

      final perlakuanDenganRating = allPerlakuan.where((p) => p.ratingEfektivitas != null).toList();
      
      if (perlakuanDenganRating.isEmpty) {
        return {
          'total_perlakuan': allPerlakuan.length,
          'perlakuan_dengan_rating': 0,
          'rata_rata_rating': 0,
          'distribusi_rating': {},
          'perlakuan_terbaik': [],
          'perlakuan_terburuk': [],
        };
      }

      // Distribusi rating
      Map<int, int> distribusiRating = {};
      for (int i = 1; i <= 5; i++) {
        distribusiRating[i] = perlakuanDenganRating.where((p) => p.ratingEfektivitas == i).length;
      }

      // Rata-rata rating
      final totalRating = perlakuanDenganRating.map((p) => p.ratingEfektivitas!).reduce((a, b) => a + b);
      final avgRating = totalRating / perlakuanDenganRating.length;

      // Perlakuan terbaik (rating 5)
      final perlakuanTerbaik = perlakuanDenganRating
          .where((p) => p.ratingEfektivitas == 5)
          .map((p) => {
                'jenis_perlakuan': p.jenisPerlakuan,
                'area_tanaman': p.areaTanaman,
                'tanggal_perlakuan': p.tanggalPerlakuan,
                'bahan_digunakan': p.bahanDigunakan,
              })
          .toList();

      // Perlakuan terburuk (rating 1-2)
      final perlakuanTerburuk = perlakuanDenganRating
          .where((p) => p.ratingEfektivitas! <= 2)
          .map((p) => {
                'jenis_perlakuan': p.jenisPerlakuan,
                'area_tanaman': p.areaTanaman,
                'tanggal_perlakuan': p.tanggalPerlakuan,
                'rating': p.ratingEfektivitas,
                'bahan_digunakan': p.bahanDigunakan,
              })
          .toList();

      return {
        'total_perlakuan': allPerlakuan.length,
        'perlakuan_dengan_rating': perlakuanDenganRating.length,
        'rata_rata_rating': avgRating,
        'distribusi_rating': distribusiRating,
        'perlakuan_terbaik': perlakuanTerbaik,
        'perlakuan_terburuk': perlakuanTerburuk,
      };
    } catch (e) {
      throw Exception('Gagal mengambil laporan efektivitas: $e');
    }
  }

  // Stream untuk real-time updates
  Stream<List<CatatanPerlakuanModel>> streamCatatanPerlakuan() {
    return _firestore
        .collection(_collection)
        .orderBy('tanggal_perlakuan', descending: true)
        .orderBy('dicatat_pada', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CatatanPerlakuanModel.fromFirestore(doc))
            .toList());
  }

  // Stream untuk catatan perlakuan hari ini
  Stream<List<CatatanPerlakuanModel>> streamCatatanPerlakuanHariIni() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection(_collection)
        .where('tanggal_perlakuan', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('tanggal_perlakuan', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('tanggal_perlakuan')
        .orderBy('dicatat_pada', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CatatanPerlakuanModel.fromFirestore(doc))
            .toList());
  }
}