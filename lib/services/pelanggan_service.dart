import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pelanggan_model.dart';

class PelangganService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'pelanggan';

  // Get all pelanggan
  Future<List<PelangganModel>> getAllPelanggan() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('nama_pelanggan')
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        print('No pelanggan documents found in Firestore');
        return [];
      }
      
      final List<PelangganModel> pelangganList = [];
      
      for (final doc in querySnapshot.docs) {
        try {
          final pelanggan = PelangganModel.fromFirestore(doc);
          pelangganList.add(pelanggan);
        } catch (e) {
          print('Error parsing pelanggan document ${doc.id}: $e');
          continue; // Skip this document and continue with others
        }
      }
      
      return pelangganList;
    } catch (e) {
      print('Error in getAllPelanggan: $e');
      throw Exception('Gagal mengambil data pelanggan: $e');
    }
  }

  // Get active pelanggan only
  Future<List<PelangganModel>> getPelangganAktif() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('aktif', isEqualTo: true)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        print('No active pelanggan documents found in Firestore');
        return [];
      }
      
      final List<PelangganModel> pelangganList = [];
      
      for (final doc in querySnapshot.docs) {
        try {
          final pelanggan = PelangganModel.fromFirestore(doc);
          if (pelanggan.aktif) { // Double check aktif status
            pelangganList.add(pelanggan);
          }
        } catch (e) {
          print('Error parsing active pelanggan document ${doc.id}: $e');
          continue; // Skip this document and continue with others
        }
      }
      
      // Sort by nama_pelanggan in memory to avoid composite index
      try {
        pelangganList.sort((a, b) => a.namaPelanggan.compareTo(b.namaPelanggan));
      } catch (e) {
        print('Error sorting pelanggan list: $e');
        // Continue without sorting if there's an error
      }
      
      return pelangganList;
    } catch (e) {
      print('Error in getPelangganAktif: $e');
      throw Exception('Gagal mengambil data pelanggan aktif: $e');
    }
  }

  // Stream active pelanggan
  Stream<List<PelangganModel>> streamPelangganAktif() {
    return _firestore
        .collection(_collection)
        .where('aktif', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final pelangganList = snapshot.docs
          .map((doc) => PelangganModel.fromFirestore(doc))
          .toList();
      
      // Sort by nama_pelanggan in memory to avoid composite index
      pelangganList.sort((a, b) => a.namaPelanggan.compareTo(b.namaPelanggan));
      
      return pelangganList;
    });
  }

  // Search pelanggan by name
  Future<List<PelangganModel>> cariPelanggan(String keyword) async {
    try {
      if (keyword.isEmpty) {
        return await getAllPelanggan();
      }

      final querySnapshot = await _firestore
          .collection(_collection)
          .get();
      
      final pelangganList = querySnapshot.docs
          .map((doc) => PelangganModel.fromFirestore(doc))
          .toList();
      
      // Client-side filtering for better search
      return pelangganList.where((pelanggan) {
        final nama = pelanggan.namaPelanggan.toLowerCase();
        final tempatUsaha = pelanggan.namaTempatUsaha?.toLowerCase() ?? '';
        final kontak = pelanggan.kontakPerson?.toLowerCase() ?? '';
        final telepon = pelanggan.telepon ?? '';
        final searchTerm = keyword.toLowerCase();
        
        return nama.contains(searchTerm) || 
               tempatUsaha.contains(searchTerm) ||
               kontak.contains(searchTerm) ||
               telepon.contains(searchTerm);
      }).toList();
    } catch (e) {
      throw Exception('Gagal mencari pelanggan: $e');
    }
  }

  // Add new pelanggan
  Future<String> tambahPelanggan(PelangganModel pelanggan) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(pelanggan.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Gagal menambah pelanggan: $e');
    }
  }

  // Update pelanggan
  Future<void> updatePelanggan(String id, PelangganModel pelanggan) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(id)
          .update(pelanggan.toFirestore());
    } catch (e) {
      throw Exception('Gagal mengupdate pelanggan: $e');
    }
  }

  // Soft delete pelanggan (set aktif = false)
  Future<void> hapusPelanggan(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'aktif': false,
      });
    } catch (e) {
      throw Exception('Gagal menghapus pelanggan: $e');
    }
  }

  // Get pelanggan by ID
  Future<PelangganModel?> getPelangganById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return PelangganModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil data pelanggan: $e');
    }
  }

  // Get pelanggan by jenis
  Future<List<PelangganModel>> getPelangganByJenis(String jenis) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('jenis_pelanggan', isEqualTo: jenis)
          .get();
      
      final pelangganList = querySnapshot.docs
          .map((doc) => PelangganModel.fromFirestore(doc))
          .where((pelanggan) => pelanggan.aktif) // Filter aktif in memory
          .toList();
      
      // Sort by nama_pelanggan in memory to avoid composite index
      pelangganList.sort((a, b) => a.namaPelanggan.compareTo(b.namaPelanggan));
      
      return pelangganList;
    } catch (e) {
      throw Exception('Gagal mengambil data pelanggan berdasarkan jenis: $e');
    }
  }

  // Initialize default pelanggan data
  Future<void> initializePelangganData() async {
    try {
      // Check if data already exists
      final existingData = await _firestore
          .collection(_collection)
          .limit(1)
          .get();
      
      if (existingData.docs.isNotEmpty) {
        print('Pelanggan data already exists');
        return;
      }

      // Default pelanggan data
      final List<Map<String, dynamic>> defaultPelanggan = [
        {
          'nama_pelanggan': 'Restoran Sari Rasa',
          'jenis_pelanggan': 'restoran',
          'nama_tempat_usaha': 'Restoran Sari Rasa',
          'kontak_person': 'Budi Santoso',
          'telepon': '081234567890',
          'alamat': 'Jl. Merdeka No. 123, Jakarta',
          'aktif': true,
          'dibuat_pada': Timestamp.now(),
        },
        {
          'nama_pelanggan': 'Hotel Grand Indonesia',
          'jenis_pelanggan': 'hotel',
          'nama_tempat_usaha': 'Hotel Grand Indonesia',
          'kontak_person': 'Siti Nurhaliza',
          'telepon': '081234567891',
          'alamat': 'Jl. Sudirman No. 456, Jakarta',
          'aktif': true,
          'dibuat_pada': Timestamp.now(),
        },
        {
          'nama_pelanggan': 'Ibu Ani',
          'jenis_pelanggan': 'individu',
          'nama_tempat_usaha': null,
          'kontak_person': 'Ani Wijaya',
          'telepon': '081234567892',
          'alamat': 'Jl. Kebon Jeruk No. 789, Jakarta',
          'aktif': true,
          'dibuat_pada': Timestamp.now(),
        },
      ];

      // Add default data
      final batch = _firestore.batch();
      for (final pelangganData in defaultPelanggan) {
        final docRef = _firestore.collection(_collection).doc();
        batch.set(docRef, pelangganData);
      }
      await batch.commit();
      
      print('Default pelanggan data initialized successfully');
    } catch (e) {
      print('Error initializing pelanggan data: $e');
      throw Exception('Gagal inisialisasi data pelanggan: $e');
    }
  }
}