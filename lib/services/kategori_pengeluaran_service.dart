import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/kategori_pengeluaran_model.dart';

class KategoriPengeluaranService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'kategori_pengeluaran';

  // Get collection reference
  CollectionReference get _kategoriesRef => _firestore.collection(_collection);

  // Add new category
  Future<String?> addKategori(KategoriPengeluaranModel kategori) async {
    try {
      final docRef = await _kategoriesRef.add(kategori.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Gagal menambahkan kategori: $e');
    }
  }

  // Get all categories
  Future<List<KategoriPengeluaranModel>> getAllKategori() async {
    try {
      final querySnapshot = await _kategoriesRef
          .orderBy('nama_kategori')
          .get();
      
      return querySnapshot.docs
          .map((doc) => KategoriPengeluaranModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data kategori: $e');
    }
  }

  // Get active categories only
  Future<List<KategoriPengeluaranModel>> getActiveKategori() async {
    try {
      final querySnapshot = await _kategoriesRef
          .where('aktif', isEqualTo: true)
          .orderBy('nama_kategori')
          .get();
      
      return querySnapshot.docs
          .map((doc) => KategoriPengeluaranModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil kategori aktif: $e');
    }
  }

  // Get category by ID
  Future<KategoriPengeluaranModel?> getKategoriById(String id) async {
    try {
      final doc = await _kategoriesRef.doc(id).get();
      if (doc.exists) {
        return KategoriPengeluaranModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil kategori: $e');
    }
  }

  // Update category
  Future<void> updateKategori(String id, KategoriPengeluaranModel kategori) async {
    try {
      await _kategoriesRef.doc(id).update(kategori.toFirestore());
    } catch (e) {
      throw Exception('Gagal memperbarui kategori: $e');
    }
  }

  // Delete category (soft delete by setting aktif = false)
  Future<void> deleteKategori(String id) async {
    try {
      await _kategoriesRef.doc(id).update({'aktif': false});
    } catch (e) {
      throw Exception('Gagal menghapus kategori: $e');
    }
  }

  // Hard delete category
  Future<void> hardDeleteKategori(String id) async {
    try {
      await _kategoriesRef.doc(id).delete();
    } catch (e) {
      throw Exception('Gagal menghapus kategori: $e');
    }
  }

  // Check if category name exists
  Future<bool> isKategoriNameExists(String namaKategori, {String? excludeId}) async {
    try {
      Query query = _kategoriesRef
          .where('nama_kategori', isEqualTo: namaKategori.trim());
      
      final querySnapshot = await query.get();
      
      if (excludeId != null) {
        return querySnapshot.docs.any((doc) => doc.id != excludeId);
      }
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Gagal memeriksa nama kategori: $e');
    }
  }

  // Search categories by name
  Future<List<KategoriPengeluaranModel>> searchKategori(String searchTerm) async {
    try {
      final querySnapshot = await _kategoriesRef
          .orderBy('nama_kategori')
          .get();
      
      final allKategori = querySnapshot.docs
          .map((doc) => KategoriPengeluaranModel.fromFirestore(doc))
          .toList();
      
      if (searchTerm.isEmpty) {
        return allKategori;
      }
      
      final searchLower = searchTerm.toLowerCase();
      return allKategori.where((kategori) {
        return kategori.namaKategori.toLowerCase().contains(searchLower) ||
               (kategori.keterangan?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    } catch (e) {
      throw Exception('Gagal mencari kategori: $e');
    }
  }

  // Get categories stream for real-time updates
  Stream<List<KategoriPengeluaranModel>> getKategoriStream() {
    return _kategoriesRef
        .orderBy('nama_kategori')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => KategoriPengeluaranModel.fromFirestore(doc))
            .toList());
  }

  // Get active categories stream
  Stream<List<KategoriPengeluaranModel>> getActiveKategoriStream() {
    return _kategoriesRef
        .where('aktif', isEqualTo: true)
        .orderBy('nama_kategori')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => KategoriPengeluaranModel.fromFirestore(doc))
            .toList());
  }

  // Initialize default categories if collection is empty
  Future<void> initializeDefaultKategori() async {
    try {
      final querySnapshot = await _kategoriesRef.limit(1).get();
      
      if (querySnapshot.docs.isEmpty) {
        final defaultKategori = KategoriPengeluaranModel.defaultKategori;
        
        final batch = _firestore.batch();
        for (final kategori in defaultKategori) {
          final docRef = _kategoriesRef.doc();
          batch.set(docRef, kategori.toFirestore());
        }
        
        await batch.commit();
      }
    } catch (e) {
      throw Exception('Gagal menginisialisasi kategori default: $e');
    }
  }

  // Get category usage statistics
  Future<Map<String, int>> getKategoriUsageStats() async {
    try {
      final pengeluaranSnapshot = await _firestore
          .collection('pengeluaran_harian')
          .get();
      
      final Map<String, int> usageStats = {};
      
      for (final doc in pengeluaranSnapshot.docs) {
        final data = doc.data();
        final idKategori = data['id_kategori'] as String?;
        if (idKategori != null) {
          usageStats[idKategori] = (usageStats[idKategori] ?? 0) + 1;
        }
      }
      
      return usageStats;
    } catch (e) {
      throw Exception('Gagal mengambil statistik penggunaan kategori: $e');
    }
  }

  // Get categories with usage count
  Future<List<Map<String, dynamic>>> getKategoriWithUsage() async {
    try {
      final kategoriList = await getAllKategori();
      final usageStats = await getKategoriUsageStats();
      
      return kategoriList.map((kategori) {
        return {
          'kategori': kategori,
          'usage_count': usageStats[kategori.id] ?? 0,
        };
      }).toList();
    } catch (e) {
      throw Exception('Gagal mengambil kategori dengan statistik: $e');
    }
  }

  // Check if category can be deleted (not used in any pengeluaran)
  Future<bool> canDeleteKategori(String id) async {
    try {
      final pengeluaranSnapshot = await _firestore
          .collection('pengeluaran_harian')
          .where('id_kategori', isEqualTo: id)
          .limit(1)
          .get();
      
      return pengeluaranSnapshot.docs.isEmpty;
    } catch (e) {
      throw Exception('Gagal memeriksa penggunaan kategori: $e');
    }
  }
}