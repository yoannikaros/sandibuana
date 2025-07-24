import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/kegagalan_panen_model.dart';

class KegagalanPanenService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'kegagalan_panen_harian';

  // Menambah data kegagalan panen baru
  Future<String?> tambahKegagalanPanen({
    required DateTime tanggalGagal,
    required String idPenanaman,
    required int jumlahGagal,
    required String jenisKegagalan,
    String? penyebabGagal,
    String? lokasi,
    String? tindakanDiambil,
    required String dicatatOleh,
  }) async {
    try {
      final docRef = await _firestore.collection(_collection).add({
        'tanggal_gagal': Timestamp.fromDate(tanggalGagal),
        'id_penanaman': idPenanaman,
        'jumlah_gagal': jumlahGagal,
        'jenis_kegagalan': jenisKegagalan,
        'penyebab_gagal': penyebabGagal,
        'lokasi': lokasi,
        'tindakan_diambil': tindakanDiambil,
        'dicatat_oleh': dicatatOleh,
        'dicatat_pada': Timestamp.now(),
      });
      return docRef.id;
    } catch (e) {
      print('Error menambah kegagalan panen: $e');
      return null;
    }
  }

  // Mengambil semua data kegagalan panen
  Future<List<KegagalanPanenModel>> getAllKegagalanPanen() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('tanggal_gagal', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => KegagalanPanenModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error mengambil data kegagalan panen: $e');
      return [];
    }
  }

  // Mengambil data kegagalan panen berdasarkan rentang tanggal
  Future<List<KegagalanPanenModel>> getKegagalanPanenByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('tanggal_gagal', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('tanggal_gagal', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('tanggal_gagal', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => KegagalanPanenModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error mengambil data kegagalan panen by date range: $e');
      return [];
    }
  }

  // Mengambil data kegagalan panen berdasarkan jenis kegagalan
  Future<List<KegagalanPanenModel>> getKegagalanPanenByJenis(
    String jenisKegagalan,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('jenis_kegagalan', isEqualTo: jenisKegagalan)
          .orderBy('tanggal_gagal', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => KegagalanPanenModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error mengambil data kegagalan panen by jenis: $e');
      return [];
    }
  }

  // Mengambil data kegagalan panen berdasarkan ID penanaman
  Future<List<KegagalanPanenModel>> getKegagalanPanenByPenanaman(
    String idPenanaman,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('id_penanaman', isEqualTo: idPenanaman)
          .orderBy('tanggal_gagal', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => KegagalanPanenModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error mengambil data kegagalan panen by penanaman: $e');
      return [];
    }
  }

  // Mengambil data kegagalan panen berdasarkan lokasi
  Future<List<KegagalanPanenModel>> getKegagalanPanenByLokasi(
    String lokasi,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('lokasi', isEqualTo: lokasi)
          .orderBy('tanggal_gagal', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => KegagalanPanenModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error mengambil data kegagalan panen by lokasi: $e');
      return [];
    }
  }

  // Update data kegagalan panen
  Future<bool> updateKegagalanPanen(
    String idKegagalan,
    Map<String, dynamic> updateData,
  ) async {
    try {
      await _firestore.collection(_collection).doc(idKegagalan).update(updateData);
      return true;
    } catch (e) {
      print('Error update kegagalan panen: $e');
      return false;
    }
  }

  // Hapus data kegagalan panen
  Future<bool> hapusKegagalanPanen(String idKegagalan) async {
    try {
      await _firestore.collection(_collection).doc(idKegagalan).delete();
      return true;
    } catch (e) {
      print('Error hapus kegagalan panen: $e');
      return false;
    }
  }

  // Mengambil statistik kegagalan panen berdasarkan jenis
  Future<Map<String, int>> getStatistikKegagalanByJenis(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('tanggal_gagal', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('tanggal_gagal', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();
      
      Map<String, int> statistik = {};
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final jenisKegagalan = data['jenis_kegagalan'] as String;
        final jumlahGagal = data['jumlah_gagal'] as int;
        
        statistik[jenisKegagalan] = (statistik[jenisKegagalan] ?? 0) + jumlahGagal;
      }
      
      return statistik;
    } catch (e) {
      print('Error mengambil statistik kegagalan by jenis: $e');
      return {};
    }
  }

  // Mengambil total kegagalan per bulan
  Future<Map<String, int>> getTotalKegagalanPerBulan(
    int tahun,
  ) async {
    try {
      final startDate = DateTime(tahun, 1, 1);
      final endDate = DateTime(tahun, 12, 31, 23, 59, 59);
      
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('tanggal_gagal', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('tanggal_gagal', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();
      
      Map<String, int> totalPerBulan = {};
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final tanggalGagal = (data['tanggal_gagal'] as Timestamp).toDate();
        final jumlahGagal = data['jumlah_gagal'] as int;
        
        final bulanKey = '${tahun}-${tanggalGagal.month.toString().padLeft(2, '0')}';
        totalPerBulan[bulanKey] = (totalPerBulan[bulanKey] ?? 0) + jumlahGagal;
      }
      
      return totalPerBulan;
    } catch (e) {
      print('Error mengambil total kegagalan per bulan: $e');
      return {};
    }
  }

  // Mengambil ringkasan kegagalan panen
  Future<Map<String, dynamic>> getRingkasanKegagalanPanen(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('tanggal_gagal', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('tanggal_gagal', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();
      
      int totalKegagalan = 0;
      int totalJumlahGagal = 0;
      Map<String, int> jenisKegagalan = {};
      Map<String, int> lokasiKegagalan = {};
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final jenis = data['jenis_kegagalan'] as String;
        final lokasi = data['lokasi'] as String?;
        final jumlah = data['jumlah_gagal'] as int;
        
        totalKegagalan++;
        totalJumlahGagal += jumlah;
        
        jenisKegagalan[jenis] = (jenisKegagalan[jenis] ?? 0) + jumlah;
        
        if (lokasi != null && lokasi.isNotEmpty) {
          lokasiKegagalan[lokasi] = (lokasiKegagalan[lokasi] ?? 0) + jumlah;
        }
      }
      
      return {
        'total_kegagalan': totalKegagalan,
        'total_jumlah_gagal': totalJumlahGagal,
        'jenis_kegagalan': jenisKegagalan,
        'lokasi_kegagalan': lokasiKegagalan,
        'rata_rata_per_kejadian': totalKegagalan > 0 ? totalJumlahGagal / totalKegagalan : 0,
      };
    } catch (e) {
      print('Error mengambil ringkasan kegagalan panen: $e');
      return {
        'total_kegagalan': 0,
        'total_jumlah_gagal': 0,
        'jenis_kegagalan': {},
        'lokasi_kegagalan': {},
        'rata_rata_per_kejadian': 0,
      };
    }
  }

  // Stream untuk real-time updates
  Stream<List<KegagalanPanenModel>> streamKegagalanPanen() {
    return _firestore
        .collection(_collection)
        .orderBy('tanggal_gagal', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => KegagalanPanenModel.fromFirestore(doc))
            .toList());
  }

  // Stream untuk kegagalan panen berdasarkan tanggal
  Stream<List<KegagalanPanenModel>> streamKegagalanPanenByDate(
    DateTime date,
  ) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    return _firestore
        .collection(_collection)
        .where('tanggal_gagal', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('tanggal_gagal', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('tanggal_gagal', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => KegagalanPanenModel.fromFirestore(doc))
            .toList());
  }
}