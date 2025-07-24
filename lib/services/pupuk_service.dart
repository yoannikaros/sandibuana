import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/jenis_pupuk_model.dart';
import '../models/penggunaan_pupuk_model.dart';

class PupukService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========================================
  // JENIS PUPUK OPERATIONS
  // ========================================

  // Get all jenis pupuk
  Future<List<JenisPupukModel>> getAllJenisPupuk() async {
    try {
      final querySnapshot = await _firestore
          .collection('jenis_pupuk')
          .get();
      
      List<JenisPupukModel> pupukList = querySnapshot.docs
          .map((doc) => JenisPupukModel.fromFirestore(doc.data(), doc.id))
          .toList();
      
      // Client-side sorting
      pupukList.sort((a, b) => a.namaPupuk.compareTo(b.namaPupuk));
      return pupukList;
    } catch (e) {
      throw Exception('Gagal mengambil data jenis pupuk: $e');
    }
  }

  // Get active jenis pupuk only
  Future<List<JenisPupukModel>> getJenisPupukAktif() async {
    try {
      final querySnapshot = await _firestore
          .collection('jenis_pupuk')
          .where('aktif', isEqualTo: true)
          .get();
      
      List<JenisPupukModel> pupukList = querySnapshot.docs
          .map((doc) => JenisPupukModel.fromFirestore(doc.data(), doc.id))
          .toList();
      
      // Client-side sorting
      pupukList.sort((a, b) => a.namaPupuk.compareTo(b.namaPupuk));
      return pupukList;
    } catch (e) {
      throw Exception('Gagal mengambil data jenis pupuk aktif: $e');
    }
  }

  // Stream active jenis pupuk
  Stream<List<JenisPupukModel>> streamJenisPupukAktif() {
    return _firestore
        .collection('jenis_pupuk')
        .where('aktif', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      List<JenisPupukModel> pupukList = snapshot.docs
          .map((doc) => JenisPupukModel.fromFirestore(doc.data(), doc.id))
          .toList();
      
      // Client-side sorting
      pupukList.sort((a, b) => a.namaPupuk.compareTo(b.namaPupuk));
      return pupukList;
    });
  }

  // Search jenis pupuk
  Future<List<JenisPupukModel>> cariJenisPupuk(String keyword) async {
    try {
      final querySnapshot = await _firestore
          .collection('jenis_pupuk')
          .where('aktif', isEqualTo: true)
          .get();
      
      List<JenisPupukModel> pupukList = querySnapshot.docs
          .map((doc) => JenisPupukModel.fromFirestore(doc.data(), doc.id))
          .toList();
      
      // Client-side filtering and sorting
      if (keyword.isNotEmpty) {
        pupukList = pupukList.where((pupuk) {
          return pupuk.namaPupuk.toLowerCase().contains(keyword.toLowerCase()) ||
                 (pupuk.kodePupuk?.toLowerCase().contains(keyword.toLowerCase()) ?? false);
        }).toList();
      }
      
      pupukList.sort((a, b) => a.namaPupuk.compareTo(b.namaPupuk));
      return pupukList;
    } catch (e) {
      throw Exception('Gagal mencari jenis pupuk: $e');
    }
  }

  // Add new jenis pupuk
  Future<String> tambahJenisPupuk(JenisPupukModel pupuk) async {
    try {
      final docRef = await _firestore
          .collection('jenis_pupuk')
          .add(pupuk.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Gagal menambah jenis pupuk: $e');
    }
  }

  // Update jenis pupuk
  Future<void> updateJenisPupuk(String id, JenisPupukModel pupuk) async {
    try {
      await _firestore
          .collection('jenis_pupuk')
          .doc(id)
          .update(pupuk.toFirestore());
    } catch (e) {
      throw Exception('Gagal mengupdate jenis pupuk: $e');
    }
  }

  // Delete jenis pupuk (soft delete)
  Future<void> hapusJenisPupuk(String id) async {
    try {
      await _firestore
          .collection('jenis_pupuk')
          .doc(id)
          .update({'aktif': false});
    } catch (e) {
      throw Exception('Gagal menghapus jenis pupuk: $e');
    }
  }

  // Get jenis pupuk by ID
  Future<JenisPupukModel?> getJenisPupukById(String id) async {
    try {
      final doc = await _firestore
          .collection('jenis_pupuk')
          .doc(id)
          .get();
      
      if (doc.exists && doc.data() != null) {
        return JenisPupukModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil data jenis pupuk: $e');
    }
  }

  // ========================================
  // PENGGUNAAN PUPUK OPERATIONS
  // ========================================

  // Add penggunaan pupuk
  Future<String> tambahPenggunaanPupuk(PenggunaanPupukModel penggunaan) async {
    try {
      final docRef = await _firestore
          .collection('penggunaan_pupuk_harian')
          .add(penggunaan.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Gagal menambah penggunaan pupuk: $e');
    }
  }

  // Get all penggunaan pupuk
  Future<List<PenggunaanPupukModel>> getAllPenggunaanPupuk() async {
    try {
      final querySnapshot = await _firestore
          .collection('penggunaan_pupuk_harian')
          .orderBy('tanggal_pakai', descending: true)
          .get();
      
      List<PenggunaanPupukModel> penggunaanList = querySnapshot.docs
          .map((doc) => PenggunaanPupukModel.fromFirestore(doc.data(), doc.id))
          .toList();
      
      return penggunaanList;
    } catch (e) {
      throw Exception('Gagal mengambil data penggunaan pupuk: $e');
    }
  }

  // Get penggunaan pupuk by date range
  Future<List<PenggunaanPupukModel>> getPenggunaanPupukByTanggal(
      DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await _firestore
          .collection('penggunaan_pupuk_harian')
          .orderBy('tanggal_pakai', descending: true)
          .get();
      
      List<PenggunaanPupukModel> penggunaanList = querySnapshot.docs
          .map((doc) => PenggunaanPupukModel.fromFirestore(doc.data(), doc.id))
          .toList();
      
      // Client-side filtering by date range
      penggunaanList = penggunaanList.where((penggunaan) {
        final tanggal = penggunaan.tanggalPakai;
        return tanggal.isAfter(startDate.subtract(const Duration(days: 1))) &&
               tanggal.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
      
      return penggunaanList;
    } catch (e) {
      throw Exception('Gagal mengambil data penggunaan pupuk: $e');
    }
  }

  // Get penggunaan pupuk by jenis pupuk
  Future<List<PenggunaanPupukModel>> getPenggunaanPupukByJenis(String idPupuk) async {
    try {
      final querySnapshot = await _firestore
          .collection('penggunaan_pupuk_harian')
          .where('id_pupuk', isEqualTo: idPupuk)
          .get();
      
      List<PenggunaanPupukModel> penggunaanList = querySnapshot.docs
          .map((doc) => PenggunaanPupukModel.fromFirestore(doc.data(), doc.id))
          .toList();
      
      // Client-side sorting
      penggunaanList.sort((a, b) => b.tanggalPakai.compareTo(a.tanggalPakai));
      return penggunaanList;
    } catch (e) {
      throw Exception('Gagal mengambil data penggunaan pupuk: $e');
    }
  }

  // Update penggunaan pupuk
  Future<void> updatePenggunaanPupuk(String id, PenggunaanPupukModel penggunaan) async {
    try {
      await _firestore
          .collection('penggunaan_pupuk_harian')
          .doc(id)
          .update(penggunaan.toFirestore());
    } catch (e) {
      throw Exception('Gagal mengupdate penggunaan pupuk: $e');
    }
  }

  // Delete penggunaan pupuk
  Future<void> hapusPenggunaanPupuk(String id) async {
    try {
      await _firestore
          .collection('penggunaan_pupuk_harian')
          .doc(id)
          .delete();
    } catch (e) {
      throw Exception('Gagal menghapus penggunaan pupuk: $e');
    }
  }

  // ========================================
  // INITIALIZATION
  // ========================================

  // Initialize default jenis pupuk data
  Future<void> initializeJenisPupukData() async {
    try {
      // Check if data already exists
      final existingData = await _firestore
          .collection('jenis_pupuk')
          .limit(1)
          .get();
      
      if (existingData.docs.isNotEmpty) {
        print('Jenis pupuk data already exists');
        return;
      }

      // Default jenis pupuk data from database.sql
      final List<Map<String, dynamic>> defaultPupuk = [
        {
          'nama_pupuk': 'Pupuk CEF',
          'kode_pupuk': 'CEF',
          'tipe': 'makro',
          'keterangan': 'Pupuk campuran unsur hara makro',
          'aktif': true,
        },
        {
          'nama_pupuk': 'Pupuk Coklat',
          'kode_pupuk': 'COKLAT',
          'tipe': 'makro',
          'keterangan': 'Pupuk makro nutrien warna coklat',
          'aktif': true,
        },
        {
          'nama_pupuk': 'Pupuk Putih',
          'kode_pupuk': 'PUTIH',
          'tipe': 'makro',
          'keterangan': 'Pupuk berbasis nitrogen/fosfor',
          'aktif': true,
        },
        {
          'nama_pupuk': 'Pythium Treatment',
          'kode_pupuk': 'PTH',
          'tipe': 'kimia',
          'keterangan': 'Anti jamur akar Pythium',
          'aktif': true,
        },
        {
          'nama_pupuk': 'HIRACOL',
          'kode_pupuk': 'HIRACOL',
          'tipe': 'kimia',
          'keterangan': 'Fungisida/insektisida',
          'aktif': true,
        },
        {
          'nama_pupuk': 'ANTRACOL',
          'kode_pupuk': 'ANTRACOL',
          'tipe': 'kimia',
          'keterangan': 'Fungisida untuk penyakit tanaman',
          'aktif': true,
        },
        {
          'nama_pupuk': 'Bawang Putih',
          'kode_pupuk': 'BAWANG',
          'tipe': 'organik',
          'keterangan': 'Ekstrak alami anti jamur',
          'aktif': true,
        },
      ];

      // Add each pupuk to Firestore
      final batch = _firestore.batch();
      for (final pupukData in defaultPupuk) {
        final docRef = _firestore.collection('jenis_pupuk').doc();
        batch.set(docRef, pupukData);
      }
      
      await batch.commit();
      print('Default jenis pupuk data initialized successfully');
    } catch (e) {
      print('Error initializing jenis pupuk data: $e');
      throw Exception('Gagal menginisialisasi data jenis pupuk: $e');
    }
  }
}