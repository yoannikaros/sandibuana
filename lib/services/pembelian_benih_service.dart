import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pembelian_benih_model.dart';

class PembelianBenihService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'pembelian_benih';

  // Create - Tambah pembelian benih baru
  Future<String> addPembelianBenih(PembelianBenihModel pembelian) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(pembelian.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Gagal menambah pembelian benih: $e');
    }
  }

  // Read - Ambil semua pembelian benih
  Future<List<PembelianBenihModel>> getAllPembelianBenih() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('tanggal_beli', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => PembelianBenihModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data pembelian benih: $e');
    }
  }

  // Read - Ambil pembelian benih berdasarkan ID
  Future<PembelianBenihModel?> getPembelianBenihById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return PembelianBenihModel.fromFirestore(doc, null);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil pembelian benih: $e');
    }
  }

  // Read - Ambil pembelian benih berdasarkan tanggal
  Future<List<PembelianBenihModel>> getPembelianBenihByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('tanggal_beli', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('tanggal_beli', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('tanggal_beli', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => PembelianBenihModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil pembelian benih berdasarkan tanggal: $e');
    }
  }

  // Read - Ambil pembelian benih berdasarkan rentang tanggal
  Future<List<PembelianBenihModel>> getPembelianBenihByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('tanggal_beli', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('tanggal_beli', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('tanggal_beli', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => PembelianBenihModel.fromFirestore(doc, null))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil pembelian benih berdasarkan rentang tanggal: $e');
    }
  }

  // Read - Ambil pembelian benih berdasarkan jenis benih
  Future<List<PembelianBenihModel>> getPembelianBenihByJenisBenih(String idBenih) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('id_benih', isEqualTo: idBenih)
          .orderBy('tanggal_beli', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => PembelianBenihModel.fromFirestore(doc, null))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil pembelian benih berdasarkan jenis: $e');
    }
  }

  // Read - Ambil pembelian benih berdasarkan pemasok
  Future<List<PembelianBenihModel>> getPembelianBenihByPemasok(String pemasok) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('pemasok', isEqualTo: pemasok)
          .orderBy('tanggal_beli', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => PembelianBenihModel.fromFirestore(doc, null))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil pembelian benih berdasarkan pemasok: $e');
    }
  }

  // Read - Ambil pembelian benih yang akan kadaluarsa
  Future<List<PembelianBenihModel>> getPembelianBenihExpiringSoon(int days) async {
    try {
      final futureDate = DateTime.now().add(Duration(days: days));
      
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('tanggal_kadaluarsa', isLessThanOrEqualTo: Timestamp.fromDate(futureDate))
          .where('tanggal_kadaluarsa', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .orderBy('tanggal_kadaluarsa')
          .get();
      
      return querySnapshot.docs
          .map((doc) => PembelianBenihModel.fromFirestore(doc, null))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil pembelian benih yang akan kadaluarsa: $e');
    }
  }

  // Read - Ambil pembelian benih yang sudah kadaluarsa
  Future<List<PembelianBenihModel>> getPembelianBenihExpired() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('tanggal_kadaluarsa', isLessThan: Timestamp.fromDate(DateTime.now()))
          .orderBy('tanggal_kadaluarsa', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => PembelianBenihModel.fromFirestore(doc, null))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil pembelian benih yang kadaluarsa: $e');
    }
  }

  // Update - Perbarui pembelian benih
  Future<void> updatePembelianBenih(String id, PembelianBenihModel pembelian) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(id)
          .update(pembelian.toFirestore());
    } catch (e) {
      throw Exception('Gagal memperbarui pembelian benih: $e');
    }
  }

  // Delete - Hapus pembelian benih
  Future<void> deletePembelianBenih(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Gagal menghapus pembelian benih: $e');
    }
  }

  // Stream - Real-time data pembelian benih
  Stream<List<PembelianBenihModel>> streamPembelianBenih() {
    return _firestore
        .collection(_collection)
        .orderBy('tanggal_beli', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PembelianBenihModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Stream - Real-time data pembelian benih berdasarkan filter
  Stream<List<PembelianBenihModel>> streamPembelianBenihByFilter({
    String? idBenih,
    String? pemasok,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _firestore.collection(_collection);
    
    if (idBenih != null) {
      query = query.where('id_benih', isEqualTo: idBenih);
    }
    if (pemasok != null) {
      query = query.where('pemasok', isEqualTo: pemasok);
    }
    if (startDate != null) {
      query = query.where('tanggal_beli', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('tanggal_beli', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }
    
    return query
        .orderBy('tanggal_beli', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PembelianBenihModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Analytics - Total pembelian berdasarkan periode
  Future<Map<String, dynamic>> getTotalPembelianByPeriod(
      DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('tanggal_beli', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('tanggal_beli', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();
      
      double totalHarga = 0;
      int totalTransaksi = querySnapshot.docs.length;
      Map<String, int> benihCount = {};
      Map<String, double> benihTotal = {};
      
      for (var doc in querySnapshot.docs) {
        final pembelian = PembelianBenihModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        totalHarga += pembelian.totalHarga;
        
        benihCount[pembelian.idBenih] = (benihCount[pembelian.idBenih] ?? 0) + 1;
        benihTotal[pembelian.idBenih] = (benihTotal[pembelian.idBenih] ?? 0) + pembelian.totalHarga;
      }
      
      return {
        'total_harga': totalHarga,
        'total_transaksi': totalTransaksi,
        'rata_rata_per_transaksi': totalTransaksi > 0 ? totalHarga / totalTransaksi : 0,
        'benih_terpopuler': benihCount,
        'benih_total_harga': benihTotal,
      };
    } catch (e) {
      throw Exception('Gagal mengambil statistik pembelian: $e');
    }
  }

  // Analytics - Laporan bulanan
  Future<Map<String, dynamic>> getLaporanBulanan(int year, int month) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
      
      return await getTotalPembelianByPeriod(startDate, endDate);
    } catch (e) {
      throw Exception('Gagal mengambil laporan bulanan: $e');
    }
  }

  // Analytics - Laporan tahunan
  Future<Map<String, dynamic>> getLaporanTahunan(int year) async {
    try {
      final startDate = DateTime(year, 1, 1);
      final endDate = DateTime(year, 12, 31, 23, 59, 59);
      
      return await getTotalPembelianByPeriod(startDate, endDate);
    } catch (e) {
      throw Exception('Gagal mengambil laporan tahunan: $e');
    }
  }

  // Utility - Ambil daftar pemasok unik
  Future<List<String>> getUniquePemasok() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      final pemasokSet = <String>{};
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['pemasok'] != null) {
          pemasokSet.add(data['pemasok']);
        }
      }
      
      final pemasokList = pemasokSet.toList();
      pemasokList.sort();
      return pemasokList;
    } catch (e) {
      throw Exception('Gagal mengambil daftar pemasok: $e');
    }
  }

  // Utility - Ambil daftar satuan unik
  Future<List<String>> getUniqueSatuan() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      final satuanSet = <String>{};
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['satuan'] != null) {
          satuanSet.add(data['satuan']);
        }
      }
      
      final satuanList = satuanSet.toList();
      satuanList.sort();
      return satuanList;
    } catch (e) {
      throw Exception('Gagal mengambil daftar satuan: $e');
    }
  }
}