import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/kondisi_meja_model.dart';

class KondisiMejaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'kondisi_meja';

  // Get all kondisi meja
  Future<List<KondisiMejaModel>> getAllKondisiMeja() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('aktif', isEqualTo: true)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        print('No kondisi meja documents found in Firestore');
        return [];
      }
      
      final List<KondisiMejaModel> kondisiMejaList = [];
      
      for (final doc in querySnapshot.docs) {
        try {
          final kondisiMeja = KondisiMejaModel.fromFirestore(doc);
          kondisiMejaList.add(kondisiMeja);
        } catch (e) {
          print('Error parsing kondisi meja document ${doc.id}: $e');
          continue; // Skip this document and continue with others
        }
      }
      
      // Sort by nama_meja in memory to avoid composite index requirement
      kondisiMejaList.sort((a, b) => a.namaMeja.compareTo(b.namaMeja));
      
      return kondisiMejaList;
    } catch (e) {
      print('Error in getAllKondisiMeja: $e');
      throw Exception('Gagal mengambil data kondisi meja: $e');
    }
  }

  // Get kondisi meja by kondisi
  Future<List<KondisiMejaModel>> getKondisiMejaByKondisi(String kondisi) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('aktif', isEqualTo: true)
          .where('kondisi', isEqualTo: kondisi)
          .get();
      
      final List<KondisiMejaModel> kondisiMejaList = [];
      
      for (final doc in querySnapshot.docs) {
        try {
          final kondisiMeja = KondisiMejaModel.fromFirestore(doc);
          kondisiMejaList.add(kondisiMeja);
        } catch (e) {
          print('Error parsing kondisi meja document ${doc.id}: $e');
          continue;
        }
      }
      
      // Sort by nama_meja in memory to avoid composite index requirement
      kondisiMejaList.sort((a, b) => a.namaMeja.compareTo(b.namaMeja));
      
      return kondisiMejaList;
    } catch (e) {
      print('Error in getKondisiMejaByKondisi: $e');
      throw Exception('Gagal mengambil data kondisi meja berdasarkan kondisi: $e');
    }
  }

  // Stream kondisi meja
  Stream<List<KondisiMejaModel>> streamKondisiMeja() {
    return _firestore
        .collection(_collection)
        .where('aktif', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final kondisiMejaList = snapshot.docs
          .map((doc) {
            try {
              return KondisiMejaModel.fromFirestore(doc);
            } catch (e) {
              print('Error parsing kondisi meja document ${doc.id}: $e');
              return null;
            }
          })
          .where((kondisiMeja) => kondisiMeja != null)
          .cast<KondisiMejaModel>()
          .toList();
      
      // Sort by nama_meja in memory to avoid composite index requirement
      kondisiMejaList.sort((a, b) => a.namaMeja.compareTo(b.namaMeja));
      
      return kondisiMejaList;
    });
  }

  // Search kondisi meja by name
  Future<List<KondisiMejaModel>> cariKondisiMeja(String keyword) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('aktif', isEqualTo: true)
          .get();
      
      final List<KondisiMejaModel> kondisiMejaList = [];
      
      for (final doc in querySnapshot.docs) {
        try {
          final kondisiMeja = KondisiMejaModel.fromFirestore(doc);
          if (kondisiMeja.namaMeja.toLowerCase().contains(keyword.toLowerCase()) ||
              (kondisiMeja.jenisSayur != null && kondisiMeja.jenisSayur!.toLowerCase().contains(keyword.toLowerCase()))) {
            kondisiMejaList.add(kondisiMeja);
          }
        } catch (e) {
          print('Error parsing kondisi meja document ${doc.id}: $e');
          continue;
        }
      }
      
      // Sort by nama_meja
      kondisiMejaList.sort((a, b) => a.namaMeja.compareTo(b.namaMeja));
      
      return kondisiMejaList;
    } catch (e) {
      print('Error in cariKondisiMeja: $e');
      throw Exception('Gagal mencari kondisi meja: $e');
    }
  }

  // Add new kondisi meja
  Future<String> tambahKondisiMeja(KondisiMejaModel kondisiMeja) async {
    try {
      // Check if meja name already exists
      final existingQuery = await _firestore
          .collection(_collection)
          .where('nama_meja', isEqualTo: kondisiMeja.namaMeja)
          .where('aktif', isEqualTo: true)
          .get();
      
      if (existingQuery.docs.isNotEmpty) {
        throw Exception('Nama meja "${kondisiMeja.namaMeja}" sudah ada');
      }
      
      final docRef = await _firestore.collection(_collection).add(kondisiMeja.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error in tambahKondisiMeja: $e');
      throw Exception('Gagal menambah kondisi meja: $e');
    }
  }

  // Update kondisi meja
  Future<void> updateKondisiMeja(String id, KondisiMejaModel kondisiMeja) async {
    try {
      // Check if meja name already exists (excluding current document)
      final existingQuery = await _firestore
          .collection(_collection)
          .where('nama_meja', isEqualTo: kondisiMeja.namaMeja)
          .where('aktif', isEqualTo: true)
          .get();
      
      final existingDocs = existingQuery.docs.where((doc) => doc.id != id).toList();
      if (existingDocs.isNotEmpty) {
        throw Exception('Nama meja "${kondisiMeja.namaMeja}" sudah ada');
      }
      
      final updatedKondisiMeja = kondisiMeja.copyWith(
        diubahPada: DateTime.now(),
      );
      
      await _firestore.collection(_collection).doc(id).update(updatedKondisiMeja.toFirestore());
    } catch (e) {
      print('Error in updateKondisiMeja: $e');
      throw Exception('Gagal mengupdate kondisi meja: $e');
    }
  }

  // Delete kondisi meja (soft delete)
  Future<void> hapusKondisiMeja(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'aktif': false,
        'diubah_pada': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error in hapusKondisiMeja: $e');
      throw Exception('Gagal menghapus kondisi meja: $e');
    }
  }

  // Get kondisi meja by ID
  Future<KondisiMejaModel?> getKondisiMejaById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      
      if (!doc.exists) {
        return null;
      }
      
      return KondisiMejaModel.fromFirestore(doc);
    } catch (e) {
      print('Error in getKondisiMejaById: $e');
      throw Exception('Gagal mengambil kondisi meja: $e');
    }
  }

  // Update kondisi meja (untuk perubahan status saja)
  Future<void> updateKondisiMejaStatus(String id, {
    String? kondisi,
    DateTime? tanggalTanam,
    String? jenisSayur,
    int? targetHariPanen,
    String? catatan,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'diubah_pada': Timestamp.fromDate(DateTime.now()),
      };
      
      if (kondisi != null) updateData['kondisi'] = kondisi;
      if (tanggalTanam != null) updateData['tanggal_tanam'] = Timestamp.fromDate(tanggalTanam);
      if (jenisSayur != null) updateData['jenis_sayur'] = jenisSayur;
      if (targetHariPanen != null) updateData['target_hari_panen'] = targetHariPanen;
      if (catatan != null) updateData['catatan'] = catatan;
      
      // Jika kondisi berubah ke kosong, hapus data tanam
      if (kondisi == 'kosong') {
        updateData['tanggal_tanam'] = null;
        updateData['jenis_sayur'] = null;
        updateData['target_hari_panen'] = null;
      }
      
      await _firestore.collection(_collection).doc(id).update(updateData);
    } catch (e) {
      print('Error in updateKondisiMejaStatus: $e');
      throw Exception('Gagal mengupdate status kondisi meja: $e');
    }
  }
}