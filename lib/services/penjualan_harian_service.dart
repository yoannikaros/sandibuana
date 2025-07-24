import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/penjualan_harian_model.dart';
import '../models/pelanggan_model.dart';

class PenjualanHarianService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'penjualan_harian';
  final String _pelangganCollection = 'pelanggan';

  // Tambah penjualan baru
  Future<String> tambahPenjualan({
    required DateTime tanggalJual,
    required String idPelanggan,
    required String jenisSayur,
    required double jumlah,
    String? satuan,
    double? hargaPerSatuan,
    required double totalHarga,
    String statusKirim = 'pending',
    String? catatan,
    required String dicatatOleh,
  }) async {
    try {
      final penjualan = PenjualanHarianModel(
        id: '',
        tanggalJual: tanggalJual,
        idPelanggan: idPelanggan,
        jenisSayur: jenisSayur,
        jumlah: jumlah,
        satuan: satuan,
        hargaPerSatuan: hargaPerSatuan,
        totalHarga: totalHarga,
        statusKirim: statusKirim,
        catatan: catatan,
        dicatatOleh: dicatatOleh,
        dicatatPada: DateTime.now(),
      );

      // Validasi data
      final validationError = penjualan.validate();
      if (validationError != null) {
        throw Exception(validationError);
      }

      final docRef = await _firestore.collection(_collection).add(penjualan.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Gagal menambahkan penjualan: $e');
    }
  }

  // Ambil semua penjualan
  Future<List<PenjualanHarianModel>> getAllPenjualan() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('tanggal_jual', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PenjualanHarianModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data penjualan: $e');
    }
  }

  // Ambil penjualan berdasarkan tanggal
  Future<List<PenjualanHarianModel>> getPenjualanByTanggal(DateTime tanggal) async {
    try {
      final startOfDay = DateTime(tanggal.year, tanggal.month, tanggal.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('tanggal_jual', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('tanggal_jual', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('tanggal_jual')
          .get();

      return querySnapshot.docs
          .map((doc) => PenjualanHarianModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil penjualan tanggal ${tanggal.day}/${tanggal.month}/${tanggal.year}: $e');
    }
  }

  // Ambil penjualan berdasarkan range tanggal
  Future<List<PenjualanHarianModel>> getPenjualanByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('tanggal_jual', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('tanggal_jual', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('tanggal_jual', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PenjualanHarianModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil penjualan berdasarkan range tanggal: $e');
    }
  }

  // Ambil penjualan berdasarkan pelanggan
  Future<List<PenjualanHarianModel>> getPenjualanByPelanggan(String idPelanggan) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('id_pelanggan', isEqualTo: idPelanggan)
          .orderBy('tanggal_jual', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PenjualanHarianModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil penjualan pelanggan: $e');
    }
  }

  // Ambil penjualan berdasarkan jenis sayur
  Future<List<PenjualanHarianModel>> getPenjualanByJenisSayur(String jenisSayur) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('jenis_sayur', isEqualTo: jenisSayur)
          .orderBy('tanggal_jual', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PenjualanHarianModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil penjualan jenis sayur $jenisSayur: $e');
    }
  }

  // Ambil penjualan berdasarkan status
  Future<List<PenjualanHarianModel>> getPenjualanByStatus(String status) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('status_kirim', isEqualTo: status)
          .orderBy('tanggal_jual', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PenjualanHarianModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil penjualan status $status: $e');
    }
  }

  // Update penjualan
  Future<void> updatePenjualan(
    String idPenjualan,
    Map<String, dynamic> updateData,
  ) async {
    try {
      await _firestore.collection(_collection).doc(idPenjualan).update(updateData);
    } catch (e) {
      throw Exception('Gagal mengupdate penjualan: $e');
    }
  }

  // Update status kirim
  Future<void> updateStatusKirim(String idPenjualan, String statusBaru) async {
    try {
      await _firestore.collection(_collection).doc(idPenjualan).update({
        'status_kirim': statusBaru,
      });
    } catch (e) {
      throw Exception('Gagal mengupdate status kirim: $e');
    }
  }

  // Hapus penjualan
  Future<void> hapusPenjualan(String idPenjualan) async {
    try {
      await _firestore.collection(_collection).doc(idPenjualan).delete();
    } catch (e) {
      throw Exception('Gagal menghapus penjualan: $e');
    }
  }

  // Cari penjualan
  Future<List<PenjualanHarianModel>> cariPenjualan(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('tanggal_jual', descending: true)
          .get();

      final allPenjualan = querySnapshot.docs
          .map((doc) => PenjualanHarianModel.fromFirestore(doc))
          .toList();

      // Filter berdasarkan jenis sayur atau catatan
      return allPenjualan.where((penjualan) {
        final jenisSayur = penjualan.jenisSayur.toLowerCase();
        final catatan = penjualan.catatan?.toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();
        return jenisSayur.contains(searchQuery) || catatan.contains(searchQuery);
      }).toList();
    } catch (e) {
      throw Exception('Gagal mencari penjualan: $e');
    }
  }

  // Statistik penjualan
  Future<Map<String, dynamic>> getStatistikPenjualan(DateTime startDate, DateTime endDate) async {
    try {
      final penjualanList = await getPenjualanByDateRange(startDate, endDate);
      
      // Filter hanya yang tidak dibatal
      final validPenjualan = penjualanList.where((p) => p.statusKirim != 'batal').toList();
      
      double totalPenjualan = 0;
      int totalTransaksi = validPenjualan.length;
      Map<String, int> sayurCount = {};
      Map<String, double> sayurTotal = {};
      Map<String, int> pelangganCount = {};
      Map<String, double> pelangganTotal = {};
      
      for (final penjualan in validPenjualan) {
        totalPenjualan += penjualan.totalHarga;
        
        // Hitung per jenis sayur
        sayurCount[penjualan.jenisSayur] = (sayurCount[penjualan.jenisSayur] ?? 0) + 1;
        sayurTotal[penjualan.jenisSayur] = (sayurTotal[penjualan.jenisSayur] ?? 0) + penjualan.totalHarga;
        
        // Hitung per pelanggan
        pelangganCount[penjualan.idPelanggan] = (pelangganCount[penjualan.idPelanggan] ?? 0) + 1;
        pelangganTotal[penjualan.idPelanggan] = (pelangganTotal[penjualan.idPelanggan] ?? 0) + penjualan.totalHarga;
      }
      
      return {
        'total_penjualan': totalPenjualan,
        'total_transaksi': totalTransaksi,
        'rata_rata_per_transaksi': totalTransaksi > 0 ? totalPenjualan / totalTransaksi : 0,
        'sayur_terpopuler': sayurCount,
        'sayur_total_penjualan': sayurTotal,
        'pelanggan_count': pelangganCount,
        'pelanggan_total': pelangganTotal,
      };
    } catch (e) {
      throw Exception('Gagal mengambil statistik penjualan: $e');
    }
  }

  // Laporan harian
  Future<Map<String, dynamic>> getLaporanHarian(DateTime tanggal) async {
    try {
      final startDate = DateTime(tanggal.year, tanggal.month, tanggal.day);
      final endDate = startDate.add(const Duration(days: 1));
      
      return await getStatistikPenjualan(startDate, endDate);
    } catch (e) {
      throw Exception('Gagal mengambil laporan harian: $e');
    }
  }

  // Laporan bulanan
  Future<Map<String, dynamic>> getLaporanBulanan(int year, int month) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
      
      return await getStatistikPenjualan(startDate, endDate);
    } catch (e) {
      throw Exception('Gagal mengambil laporan bulanan: $e');
    }
  }

  // Get top selling products
  Future<List<Map<String, dynamic>>> getTopSellingProducts(DateTime startDate, DateTime endDate, {int limit = 5}) async {
    try {
      final penjualanList = await getPenjualanByDateRange(startDate, endDate);
      final validPenjualan = penjualanList.where((p) => p.statusKirim != 'batal').toList();
      
      Map<String, double> sayurQuantity = {};
      Map<String, double> sayurRevenue = {};
      
      for (final penjualan in validPenjualan) {
        sayurQuantity[penjualan.jenisSayur] = (sayurQuantity[penjualan.jenisSayur] ?? 0) + penjualan.jumlah;
        sayurRevenue[penjualan.jenisSayur] = (sayurRevenue[penjualan.jenisSayur] ?? 0) + penjualan.totalHarga;
      }
      
      final sortedProducts = sayurRevenue.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      return sortedProducts.take(limit).map((entry) => {
        'jenis_sayur': entry.key,
        'total_quantity': sayurQuantity[entry.key] ?? 0,
        'total_revenue': entry.value,
      }).toList();
    } catch (e) {
      throw Exception('Gagal mengambil produk terlaris: $e');
    }
  }

  // Get pending deliveries
  Future<List<PenjualanHarianModel>> getPendingDeliveries() async {
    try {
      return await getPenjualanByStatus('pending');
    } catch (e) {
      throw Exception('Gagal mengambil pengiriman pending: $e');
    }
  }
}