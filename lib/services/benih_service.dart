import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/jenis_benih_model.dart';
import '../models/pembelian_benih_model.dart';
import '../models/catatan_pembenihan_model.dart';

class BenihService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========================================
  // JENIS BENIH OPERATIONS
  // ========================================

  // Tambah jenis benih baru
  Future<String> tambahJenisBenih(JenisBenihModel jenisBenih) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('jenis_benih')
          .add(jenisBenih.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Gagal menambah jenis benih: ${e.toString()}');
    }
  }

  // Ambil semua jenis benih aktif
  Future<List<JenisBenihModel>> getJenisBenihAktif() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('jenis_benih')
          .where('aktif', isEqualTo: true)
          .get();

      List<JenisBenihModel> data = querySnapshot.docs
          .map((doc) => JenisBenihModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // Sort di client side
      data.sort((a, b) => a.namaBenih.compareTo(b.namaBenih));
      return data;
    } catch (e) {
      throw Exception('Gagal mengambil data jenis benih: ${e.toString()}');
    }
  }

  // Ambil semua jenis benih (termasuk tidak aktif)
  Future<List<JenisBenihModel>> getAllJenisBenih() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('jenis_benih')
          .get();

      List<JenisBenihModel> data = querySnapshot.docs
          .map((doc) => JenisBenihModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // Sort di client side
      data.sort((a, b) => a.namaBenih.compareTo(b.namaBenih));
      return data;
    } catch (e) {
      throw Exception('Gagal mengambil data jenis benih: ${e.toString()}');
    }
  }

  // Ambil jenis benih berdasarkan ID
  Future<JenisBenihModel?> getJenisBenihById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('jenis_benih')
          .doc(id)
          .get();

      if (doc.exists) {
        return JenisBenihModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil data jenis benih: ${e.toString()}');
    }
  }

  // Update jenis benih
  Future<void> updateJenisBenih(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('jenis_benih').doc(id).update(data);
    } catch (e) {
      throw Exception('Gagal mengupdate jenis benih: ${e.toString()}');
    }
  }

  // Hapus jenis benih (soft delete - set aktif = false)
  Future<void> hapusJenisBenih(String id) async {
    try {
      await _firestore.collection('jenis_benih').doc(id).update({
        'aktif': false,
      });
    } catch (e) {
      throw Exception('Gagal menghapus jenis benih: ${e.toString()}');
    }
  }

  // Cari jenis benih berdasarkan nama
  Future<List<JenisBenihModel>> cariJenisBenih(String nama) async {
    try {
      // Ambil semua data aktif terlebih dahulu
      QuerySnapshot querySnapshot = await _firestore
          .collection('jenis_benih')
          .where('aktif', isEqualTo: true)
          .get();

      // Filter di client side untuk pencarian nama
      List<JenisBenihModel> allData = querySnapshot.docs
          .map((doc) => JenisBenihModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Filter berdasarkan nama (case insensitive)
      List<JenisBenihModel> filteredData = allData
          .where((benih) => benih.namaBenih
              .toLowerCase()
              .contains(nama.toLowerCase()))
          .toList();

      // Sort berdasarkan nama
      filteredData.sort((a, b) => a.namaBenih.compareTo(b.namaBenih));

      return filteredData;
    } catch (e) {
      throw Exception('Gagal mencari jenis benih: ${e.toString()}');
    }
  }

  // ========================================
  // PEMBELIAN BENIH OPERATIONS
  // ========================================

  // Tambah pembelian benih baru
  Future<String> tambahPembelianBenih(PembelianBenihModel pembelian) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('pembelian_benih')
          .add(pembelian.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Gagal menambah pembelian benih: ${e.toString()}');
    }
  }

  // Ambil pembelian benih berdasarkan tanggal
  Future<List<PembelianBenihModel>> getPembelianBenihByTanggal(
      DateTime startDate, DateTime endDate) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('pembelian_benih')
          .orderBy('tanggal_beli', descending: true)
          .get();

      // Filter di client side berdasarkan tanggal
      List<PembelianBenihModel> allData = querySnapshot.docs
          .map((doc) => PembelianBenihModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Filter berdasarkan range tanggal
      List<PembelianBenihModel> filteredData = allData
          .where((pembelian) {
            DateTime tanggalBeli = pembelian.tanggalBeli;
            return tanggalBeli.isAfter(startDate.subtract(Duration(days: 1))) &&
                   tanggalBeli.isBefore(endDate.add(Duration(days: 1)));
          })
          .toList();

      return filteredData;
    } catch (e) {
      throw Exception('Gagal mengambil data pembelian benih: ${e.toString()}');
    }
  }

  // Ambil pembelian benih berdasarkan jenis benih
  Future<List<PembelianBenihModel>> getPembelianBenihByJenis(String idBenih) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('pembelian_benih')
          .where('id_benih', isEqualTo: idBenih)
          .get();

      List<PembelianBenihModel> data = querySnapshot.docs
          .map((doc) => PembelianBenihModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // Sort di client side berdasarkan tanggal
      data.sort((a, b) => b.tanggalBeli.compareTo(a.tanggalBeli));
      return data;
    } catch (e) {
      throw Exception('Gagal mengambil data pembelian benih: ${e.toString()}');
    }
  }

  // Update pembelian benih
  Future<void> updatePembelianBenih(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('pembelian_benih').doc(id).update(data);
    } catch (e) {
      throw Exception('Gagal mengupdate pembelian benih: ${e.toString()}');
    }
  }

  // ========================================
  // CATATAN PEMBENIHAN OPERATIONS
  // ========================================

  // Tambah catatan pembenihan baru
  Future<String> tambahCatatanPembenihan(CatatanPembenihanModel catatan) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('catatan_pembenihan')
          .add(catatan.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Gagal menambah catatan pembenihan: ${e.toString()}');
    }
  }

  // Ambil semua catatan pembenihan
  Future<List<CatatanPembenihanModel>> getAllCatatanPembenihan() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('catatan_pembenihan')
          .orderBy('tanggal_semai', descending: true)
          .get();

      List<CatatanPembenihanModel> data = querySnapshot.docs
          .map((doc) => CatatanPembenihanModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      return data;
    } catch (e) {
      throw Exception('Gagal mengambil data catatan pembenihan: ${e.toString()}');
    }
  }

  // Ambil catatan pembenihan berdasarkan tanggal
  Future<List<CatatanPembenihanModel>> getCatatanPembenihanByTanggal(
      DateTime startDate, DateTime endDate) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('catatan_pembenihan')
          .orderBy('tanggal_semai', descending: true)
          .get();

      // Filter di client side berdasarkan tanggal
      List<CatatanPembenihanModel> allData = querySnapshot.docs
          .map((doc) => CatatanPembenihanModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Filter berdasarkan range tanggal
      List<CatatanPembenihanModel> filteredData = allData
          .where((catatan) {
            DateTime tanggalSemai = catatan.tanggalSemai;
            return tanggalSemai.isAfter(startDate.subtract(Duration(days: 1))) &&
                   tanggalSemai.isBefore(endDate.add(Duration(days: 1)));
          })
          .toList();

      return filteredData;
    } catch (e) {
      throw Exception('Gagal mengambil data catatan pembenihan: ${e.toString()}');
    }
  }

  // Ambil catatan pembenihan berdasarkan jenis benih
  Future<List<CatatanPembenihanModel>> getCatatanPembenihanByJenis(String idBenih) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('catatan_pembenihan')
          .where('id_benih', isEqualTo: idBenih)
          .get();

      List<CatatanPembenihanModel> data = querySnapshot.docs
          .map((doc) => CatatanPembenihanModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // Sort di client side berdasarkan tanggal
      data.sort((a, b) => b.tanggalSemai.compareTo(a.tanggalSemai));
      return data;
    } catch (e) {
      throw Exception('Gagal mengambil data catatan pembenihan: ${e.toString()}');
    }
  }

  // Ambil catatan pembenihan berdasarkan kode batch
  Future<CatatanPembenihanModel?> getCatatanPembenihanByBatch(String kodeBatch) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('catatan_pembenihan')
          .where('kode_batch', isEqualTo: kodeBatch)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return CatatanPembenihanModel.fromMap(
            querySnapshot.docs.first.data() as Map<String, dynamic>,
            querySnapshot.docs.first.id);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil data catatan pembenihan: ${e.toString()}');
    }
  }

  // Update catatan pembenihan
  Future<void> updateCatatanPembenihan(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('catatan_pembenihan').doc(id).update(data);
    } catch (e) {
      throw Exception('Gagal mengupdate catatan pembenihan: ${e.toString()}');
    }
  }

  // Hapus catatan pembenihan
  Future<void> hapusCatatanPembenihan(String id) async {
    try {
      await _firestore.collection('catatan_pembenihan').doc(id).delete();
    } catch (e) {
      throw Exception('Gagal menghapus catatan pembenihan: ${e.toString()}');
    }
  }

  // ========================================
  // UTILITY FUNCTIONS
  // ========================================

  // Stream untuk real-time updates jenis benih
  Stream<List<JenisBenihModel>> streamJenisBenihAktif() {
    return _firestore
        .collection('jenis_benih')
        .where('aktif', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          List<JenisBenihModel> data = snapshot.docs
              .map((doc) => JenisBenihModel.fromMap(
                  doc.data() as Map<String, dynamic>, doc.id))
              .toList();
          
          // Sort di client side
          data.sort((a, b) => a.namaBenih.compareTo(b.namaBenih));
          return data;
        });
  }

  // Inisialisasi data default jenis benih
  Future<void> initializeDefaultJenisBenih() async {
    try {
      // Cek apakah sudah ada data
      QuerySnapshot existing = await _firestore.collection('jenis_benih').limit(1).get();
      
      if (existing.docs.isEmpty) {
        // Data default dari database.sql
        List<Map<String, dynamic>> defaultData = [
          {
            'nama_benih': 'Selada Bumi Grand Rapid',
            'pemasok': 'Mutiara Bumi',
            'harga_per_satuan': 33000.0,
            'jenis_satuan': 'gram',
            'ukuran_satuan': '8 gram',
            'aktif': true,
            'dibuat_pada': FieldValue.serverTimestamp(),
          },
          {
            'nama_benih': 'Selada KYS Grand Rapid',
            'pemasok': 'KYS',
            'harga_per_satuan': 0.0,
            'jenis_satuan': 'gram',
            'ukuran_satuan': '8 gram',
            'aktif': true,
            'dibuat_pada': FieldValue.serverTimestamp(),
          },
          {
            'nama_benih': 'Romaine Veropas',
            'pemasok': 'Veropas',
            'harga_per_satuan': 900000.0,
            'jenis_satuan': 'biji',
            'ukuran_satuan': '5000 biji',
            'aktif': true,
            'dibuat_pada': FieldValue.serverTimestamp(),
          },
          {
            'nama_benih': 'Selada Sonybel',
            'pemasok': 'Sony',
            'harga_per_satuan': 65000.0,
            'jenis_satuan': 'gram',
            'ukuran_satuan': '1 gram',
            'aktif': true,
            'dibuat_pada': FieldValue.serverTimestamp(),
          },
          {
            'nama_benih': 'Selada Lilybel',
            'pemasok': 'Lily',
            'harga_per_satuan': 255000.0,
            'jenis_satuan': 'biji',
            'ukuran_satuan': '1000 biji',
            'aktif': true,
            'dibuat_pada': FieldValue.serverTimestamp(),
          },
        ];

        // Batch write untuk efisiensi
        WriteBatch batch = _firestore.batch();
        
        for (Map<String, dynamic> data in defaultData) {
          DocumentReference docRef = _firestore.collection('jenis_benih').doc();
          batch.set(docRef, data);
        }
        
        await batch.commit();
        print('Data default jenis benih berhasil diinisialisasi');
      }
    } catch (e) {
      print('Error inisialisasi data default: ${e.toString()}');
    }
  }
}