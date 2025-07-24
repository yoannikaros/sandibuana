import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pengeluaran_harian_model.dart';
import '../models/kategori_pengeluaran_model.dart';

class PengeluaranService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _pengeluaranCollection = 'pengeluaran_harian';
  final String _kategoriCollection = 'kategori_pengeluaran';

  // ========================================
  // KATEGORI PENGELUARAN METHODS
  // ========================================

  // Get all categories
  Future<List<KategoriPengeluaranModel>> getAllKategori() async {
    try {
      final querySnapshot = await _firestore
          .collection(_kategoriCollection)
          .where('aktif', isEqualTo: true)
          .orderBy('nama_kategori')
          .get();

      return querySnapshot.docs
          .map((doc) => KategoriPengeluaranModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data kategori: $e');
    }
  }

  // Get category by ID
  Future<KategoriPengeluaranModel?> getKategoriById(String id) async {
    try {
      final doc = await _firestore.collection(_kategoriCollection).doc(id).get();
      if (doc.exists) {
        return KategoriPengeluaranModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil kategori: $e');
    }
  }

  // Add new category
  Future<String> tambahKategori(KategoriPengeluaranModel kategori) async {
    try {
      final docRef = await _firestore
          .collection(_kategoriCollection)
          .add(kategori.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Gagal menambah kategori: $e');
    }
  }

  // Update category
  Future<void> updateKategori(KategoriPengeluaranModel kategori) async {
    try {
      await _firestore
          .collection(_kategoriCollection)
          .doc(kategori.id)
          .update(kategori.toFirestore());
    } catch (e) {
      throw Exception('Gagal mengupdate kategori: $e');
    }
  }

  // Soft delete category
  Future<void> hapusKategori(String id) async {
    try {
      await _firestore.collection(_kategoriCollection).doc(id).update({
        'aktif': false,
      });
    } catch (e) {
      throw Exception('Gagal menghapus kategori: $e');
    }
  }

  // Initialize default categories
  Future<void> initializeDefaultKategori() async {
    try {
      final existingKategori = await getAllKategori();
      if (existingKategori.isEmpty) {
        for (final kategori in KategoriPengeluaranModel.defaultKategori) {
          await tambahKategori(kategori);
        }
      }
    } catch (e) {
      throw Exception('Gagal inisialisasi kategori default: $e');
    }
  }

  // ========================================
  // PENGELUARAN HARIAN METHODS
  // ========================================

  // Get all expenses
  Future<List<PengeluaranHarianModel>> getAllPengeluaran() async {
    try {
      final querySnapshot = await _firestore
          .collection(_pengeluaranCollection)
          .orderBy('tanggal_pengeluaran', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PengeluaranHarianModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data pengeluaran: $e');
    }
  }

  // Get expenses by date range
  Future<List<PengeluaranHarianModel>> getPengeluaranByTanggal(
      DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await _firestore
          .collection(_pengeluaranCollection)
          .where('tanggal_pengeluaran',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('tanggal_pengeluaran',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('tanggal_pengeluaran', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PengeluaranHarianModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil pengeluaran berdasarkan tanggal: $e');
    }
  }

  // Get expenses by category
  Future<List<PengeluaranHarianModel>> getPengeluaranByKategori(
      String idKategori) async {
    try {
      final querySnapshot = await _firestore
          .collection(_pengeluaranCollection)
          .where('id_kategori', isEqualTo: idKategori)
          .orderBy('tanggal_pengeluaran', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PengeluaranHarianModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil pengeluaran berdasarkan kategori: $e');
    }
  }

  // Search expenses by description
  Future<List<PengeluaranHarianModel>> searchPengeluaran(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection(_pengeluaranCollection)
          .orderBy('tanggal_pengeluaran', descending: true)
          .get();

      final allPengeluaran = querySnapshot.docs
          .map((doc) => PengeluaranHarianModel.fromFirestore(doc))
          .toList();

      // Filter by description or supplier
      return allPengeluaran.where((pengeluaran) {
        final keterangan = pengeluaran.keterangan.toLowerCase();
        final pemasok = pengeluaran.pemasok?.toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();
        return keterangan.contains(searchQuery) || pemasok.contains(searchQuery);
      }).toList();
    } catch (e) {
      throw Exception('Gagal mencari pengeluaran: $e');
    }
  }

  // Get expense by ID
  Future<PengeluaranHarianModel?> getPengeluaranById(String id) async {
    try {
      final doc = await _firestore.collection(_pengeluaranCollection).doc(id).get();
      if (doc.exists) {
        return PengeluaranHarianModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil pengeluaran: $e');
    }
  }

  // Add new expense
  Future<String> tambahPengeluaran(PengeluaranHarianModel pengeluaran) async {
    try {
      final docRef = await _firestore
          .collection(_pengeluaranCollection)
          .add(pengeluaran.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Gagal menambah pengeluaran: $e');
    }
  }

  // Update expense
  Future<void> updatePengeluaran(PengeluaranHarianModel pengeluaran) async {
    try {
      await _firestore
          .collection(_pengeluaranCollection)
          .doc(pengeluaran.id)
          .update(pengeluaran.toFirestore());
    } catch (e) {
      throw Exception('Gagal mengupdate pengeluaran: $e');
    }
  }

  // Delete expense
  Future<void> hapusPengeluaran(String id) async {
    try {
      await _firestore.collection(_pengeluaranCollection).doc(id).delete();
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
  Future<double> getTotalPengeluaranByKategori(String idKategori) async {
    try {
      final pengeluaranList = await getPengeluaranByKategori(idKategori);
      return pengeluaranList.fold<double>(0.0, (double sum, PengeluaranHarianModel item) => sum + item.jumlah);
    } catch (e) {
      throw Exception('Gagal menghitung total pengeluaran kategori: $e');
    }
  }

  // Stream for real-time updates
  Stream<List<PengeluaranHarianModel>> streamPengeluaran() {
    return _firestore
        .collection(_pengeluaranCollection)
        .orderBy('tanggal_pengeluaran', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PengeluaranHarianModel.fromFirestore(doc))
            .toList());
  }

  // Stream categories for real-time updates
  Stream<List<KategoriPengeluaranModel>> streamKategori() {
    return _firestore
        .collection(_kategoriCollection)
        .where('aktif', isEqualTo: true)
        .orderBy('nama_kategori')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => KategoriPengeluaranModel.fromFirestore(doc))
            .toList());
  }
}