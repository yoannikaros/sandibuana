import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/penanaman_sayur_model.dart';

class PenanamanSayurService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'penanaman_sayur';

  // ========================================
  // CREATE OPERATIONS
  // ========================================

  // Tambah penanaman sayur baru
  Future<void> tambahPenanamanSayur(PenanamanSayurModel penanaman) async {
    try {
      await _firestore.collection(_collection).add(penanaman.toFirestore());
    } catch (e) {
      throw Exception('Gagal menambah penanaman sayur: ${e.toString()}');
    }
  }

  // ========================================
  // READ OPERATIONS
  // ========================================

  // Get all penanaman sayur
  Future<List<PenanamanSayurModel>> getAllPenanamanSayur() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('tanggal_tanam', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PenanamanSayurModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data penanaman sayur: ${e.toString()}');
    }
  }

  // Get penanaman sayur by tanggal range
  Future<List<PenanamanSayurModel>> getPenanamanSayurByTanggal(
      DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('tanggal_tanam', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('tanggal_tanam', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('tanggal_tanam', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PenanamanSayurModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data penanaman sayur berdasarkan tanggal: ${e.toString()}');
    }
  }

  // Get penanaman sayur by jenis sayur
  Future<List<PenanamanSayurModel>> getPenanamanSayurByJenis(String jenisSayur) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('jenis_sayur', isEqualTo: jenisSayur)
          .orderBy('tanggal_tanam', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PenanamanSayurModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data penanaman sayur berdasarkan jenis: ${e.toString()}');
    }
  }

  // Get penanaman sayur by tahap pertumbuhan
  Future<List<PenanamanSayurModel>> getPenanamanSayurByTahap(String tahapPertumbuhan) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('tahap_pertumbuhan', isEqualTo: tahapPertumbuhan)
          .orderBy('tanggal_tanam', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PenanamanSayurModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data penanaman sayur berdasarkan tahap: ${e.toString()}');
    }
  }

  // Get penanaman sayur by lokasi
  Future<List<PenanamanSayurModel>> getPenanamanSayurByLokasi(String lokasi) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('lokasi', isEqualTo: lokasi)
          .orderBy('tanggal_tanam', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PenanamanSayurModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data penanaman sayur berdasarkan lokasi: ${e.toString()}');
    }
  }

  // Get penanaman sayur by pembenihan ID
  Future<List<PenanamanSayurModel>> getPenanamanSayurByPembenihan(String idPembenihan) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('id_pembenihan', isEqualTo: idPembenihan)
          .orderBy('tanggal_tanam', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PenanamanSayurModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data penanaman sayur berdasarkan pembenihan: ${e.toString()}');
    }
  }

  // ========================================
  // UPDATE OPERATIONS
  // ========================================

  // Update penanaman sayur
  Future<void> updatePenanamanSayur(String id, Map<String, dynamic> data) async {
    try {
      // Add updated timestamp
      data['diubah_pada'] = FieldValue.serverTimestamp();
      
      // Calculate tingkat_keberhasilan if jumlah_dipanen or jumlah_ditanam is updated
      if (data.containsKey('jumlah_dipanen') || data.containsKey('jumlah_ditanam')) {
        final doc = await _firestore.collection(_collection).doc(id).get();
        if (doc.exists) {
          final currentData = doc.data() as Map<String, dynamic>;
          final jumlahDitanam = data['jumlah_ditanam'] ?? currentData['jumlah_ditanam'] ?? 0;
          final jumlahDipanen = data['jumlah_dipanen'] ?? currentData['jumlah_dipanen'] ?? 0;
          
          if (jumlahDitanam > 0) {
            data['tingkat_keberhasilan'] = (jumlahDipanen / jumlahDitanam) * 100;
          } else {
            data['tingkat_keberhasilan'] = 0.0;
          }
        }
      }
      
      await _firestore.collection(_collection).doc(id).update(data);
    } catch (e) {
      throw Exception('Gagal mengupdate penanaman sayur: ${e.toString()}');
    }
  }

  // Update tahap pertumbuhan
  Future<void> updateTahapPertumbuhan(String id, String tahapBaru) async {
    try {
      await updatePenanamanSayur(id, {
        'tahap_pertumbuhan': tahapBaru,
      });
    } catch (e) {
      throw Exception('Gagal mengupdate tahap pertumbuhan: ${e.toString()}');
    }
  }

  // Update data panen
  Future<void> updateDataPanen(String id, {
    required DateTime tanggalPanen,
    required int jumlahDipanen,
    int? jumlahGagal,
    String? alasanGagal,
  }) async {
    try {
      final updateData = {
        'tahap_pertumbuhan': 'panen',
        'tanggal_panen': Timestamp.fromDate(tanggalPanen),
        'jumlah_dipanen': jumlahDipanen,
      };
      
      if (jumlahGagal != null) {
        updateData['jumlah_gagal'] = jumlahGagal;
      }
      
      if (alasanGagal != null && alasanGagal.isNotEmpty) {
        updateData['alasan_gagal'] = alasanGagal;
      }
      
      await updatePenanamanSayur(id, updateData);
    } catch (e) {
      throw Exception('Gagal mengupdate data panen: ${e.toString()}');
    }
  }

  // ========================================
  // DELETE OPERATIONS
  // ========================================

  // Hapus penanaman sayur
  Future<void> hapusPenanamanSayur(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Gagal menghapus penanaman sayur: ${e.toString()}');
    }
  }

  // ========================================
  // STATISTICS & REPORTS
  // ========================================

  // Get tingkat keberhasilan by jenis sayur
  Future<Map<String, double>> getTingkatKeberhasilanByJenis() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('tahap_pertumbuhan', isEqualTo: 'panen')
          .get();

      final Map<String, List<double>> jenisKeberhasilan = {};
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final jenisSayur = data['jenis_sayur'] as String;
        final tingkatKeberhasilan = (data['tingkat_keberhasilan'] ?? 0.0).toDouble();
        
        if (!jenisKeberhasilan.containsKey(jenisSayur)) {
          jenisKeberhasilan[jenisSayur] = [];
        }
        jenisKeberhasilan[jenisSayur]!.add(tingkatKeberhasilan);
      }
      
      final Map<String, double> result = {};
      jenisKeberhasilan.forEach((jenis, keberhasilanList) {
        final rataRata = keberhasilanList.reduce((a, b) => a + b) / keberhasilanList.length;
        result[jenis] = rataRata;
      });
      
      return result;
    } catch (e) {
      throw Exception('Gagal mengambil tingkat keberhasilan: ${e.toString()}');
    }
  }

  // Get total produksi by periode
  Future<Map<String, int>> getTotalProduksiByPeriode(DateTime startDate, DateTime endDate) async {
    try {
      // First, get all documents with tahap_pertumbuhan = 'panen'
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('tahap_pertumbuhan', isEqualTo: 'panen')
          .get();

      final Map<String, int> produksi = {};
      final startTimestamp = Timestamp.fromDate(startDate);
      final endTimestamp = Timestamp.fromDate(endDate);
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final tanggalPanen = data['tanggal_panen'] as Timestamp?;
        
        // Filter by date range in memory to avoid composite index requirement
        if (tanggalPanen != null && 
            tanggalPanen.compareTo(startTimestamp) >= 0 && 
            tanggalPanen.compareTo(endTimestamp) <= 0) {
          final jenisSayur = data['jenis_sayur'] as String;
          final jumlahDipanen = data['jumlah_dipanen'] as int? ?? 0;
          
          produksi[jenisSayur] = (produksi[jenisSayur] ?? 0) + jumlahDipanen;
        }
      }
      
      return produksi;
    } catch (e) {
      throw Exception('Gagal mengambil total produksi: ${e.toString()}');
    }
  }

  // Get available jenis sayur
  Future<List<String>> getAvailableJenisSayur() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .get();

      final Set<String> jenisSayurSet = {};
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final jenisSayur = data['jenis_sayur'] as String?;
        if (jenisSayur != null && jenisSayur.isNotEmpty) {
          jenisSayurSet.add(jenisSayur);
        }
      }
      
      final List<String> result = jenisSayurSet.toList();
      result.sort(); // Sort alphabetically
      return result;
    } catch (e) {
      throw Exception('Gagal mengambil daftar jenis sayur: ${e.toString()}');
    }
  }

  // Get summary statistics
  Future<Map<String, dynamic>> getSummaryStatistics() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      
      int totalPenanaman = 0;
      int totalDitanam = 0;
      int totalDipanen = 0;
      int totalGagal = 0;
      final Map<String, int> countByTahap = {};
      final Map<String, int> countByJenis = {};
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        totalPenanaman++;
        totalDitanam += (data['jumlah_ditanam'] as int? ?? 0);
        totalDipanen += (data['jumlah_dipanen'] as int? ?? 0);
        totalGagal += (data['jumlah_gagal'] as int? ?? 0);
        
        final tahap = data['tahap_pertumbuhan'] as String? ?? 'semai';
        countByTahap[tahap] = (countByTahap[tahap] ?? 0) + 1;
        
        final jenis = data['jenis_sayur'] as String? ?? 'Unknown';
        countByJenis[jenis] = (countByJenis[jenis] ?? 0) + 1;
      }
      
      final double tingkatKeberhasilanKeseluruhan = totalDitanam > 0 
          ? (totalDipanen / totalDitanam) * 100 
          : 0.0;
      
      return {
        'total_penanaman': totalPenanaman,
        'total_ditanam': totalDitanam,
        'total_dipanen': totalDipanen,
        'total_gagal': totalGagal,
        'tingkat_keberhasilan_keseluruhan': tingkatKeberhasilanKeseluruhan,
        'count_by_tahap': countByTahap,
        'count_by_jenis': countByJenis,
      };
    } catch (e) {
      throw Exception('Gagal mengambil statistik ringkasan: ${e.toString()}');
    }
  }
}