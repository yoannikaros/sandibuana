import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/jadwal_pemupukan_model.dart';

class JadwalPemupukanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'jadwal_pemupukan_bulanan';

  // Tambah jadwal pemupukan baru
  Future<String> tambahJadwalPemupukan({
    required DateTime bulanTahun,
    required int mingguKe,
    required int hariDalamMinggu,
    required String perlakuanPupuk,
    String? perlakuanTambahan,
    String? catatan,
    String? idPembenihan,
    required String dibuatOleh,
  }) async {
    try {
      // Cek apakah jadwal untuk minggu dan hari yang sama sudah ada
      final existingQuery = await _firestore
          .collection(_collection)
          .where('bulan_tahun', isEqualTo: Timestamp.fromDate(DateTime(bulanTahun.year, bulanTahun.month, 1)))
          .where('minggu_ke', isEqualTo: mingguKe)
          .where('hari_dalam_minggu', isEqualTo: hariDalamMinggu)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        throw Exception('Jadwal untuk minggu ke-$mingguKe hari ${JadwalPemupukanModel.getNamaHari(hariDalamMinggu)} sudah ada');
      }

      final jadwal = JadwalPemupukanModel(
        idJadwal: '',
        bulanTahun: DateTime(bulanTahun.year, bulanTahun.month, 1),
        mingguKe: mingguKe,
        hariDalamMinggu: hariDalamMinggu,
        perlakuanPupuk: perlakuanPupuk,
        perlakuanTambahan: perlakuanTambahan,
        catatan: catatan,
        idPembenihan: idPembenihan,
        dibuatOleh: dibuatOleh,
        dibuatPada: DateTime.now(),
      );

      final docRef = await _firestore.collection(_collection).add(jadwal.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Gagal menambahkan jadwal pemupukan: $e');
    }
  }

  // Ambil semua jadwal pemupukan
  Future<List<JadwalPemupukanModel>> getAllJadwalPemupukan() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('bulan_tahun', descending: true)
          .orderBy('minggu_ke')
          .orderBy('hari_dalam_minggu')
          .get();

      return querySnapshot.docs
          .map((doc) => JadwalPemupukanModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data jadwal pemupukan: $e');
    }
  }

  // Ambil jadwal pemupukan berdasarkan bulan dan tahun
  Future<List<JadwalPemupukanModel>> getJadwalPemupukanByBulan(DateTime bulanTahun) async {
    try {
      final startOfMonth = DateTime(bulanTahun.year, bulanTahun.month, 1);
      final endOfMonth = DateTime(bulanTahun.year, bulanTahun.month + 1, 1).subtract(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('bulan_tahun', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('bulan_tahun', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .orderBy('bulan_tahun')
          .orderBy('minggu_ke')
          .orderBy('hari_dalam_minggu')
          .get();

      return querySnapshot.docs
          .map((doc) => JadwalPemupukanModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil jadwal pemupukan bulan ${bulanTahun.month}/${bulanTahun.year}: $e');
    }
  }

  // Ambil jadwal pemupukan berdasarkan status
  Future<List<JadwalPemupukanModel>> getJadwalPemupukanByStatus(bool sudahSelesai) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('sudah_selesai', isEqualTo: sudahSelesai)
          .orderBy('bulan_tahun', descending: true)
          .orderBy('minggu_ke')
          .orderBy('hari_dalam_minggu')
          .get();

      return querySnapshot.docs
          .map((doc) => JadwalPemupukanModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil jadwal pemupukan berdasarkan status: $e');
    }
  }

  // Ambil jadwal pemupukan berdasarkan range tanggal
  Future<List<JadwalPemupukanModel>> getJadwalPemupukanByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('bulan_tahun', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('bulan_tahun', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('bulan_tahun')
          .orderBy('minggu_ke')
          .orderBy('hari_dalam_minggu')
          .get();

      return querySnapshot.docs
          .map((doc) => JadwalPemupukanModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil jadwal pemupukan berdasarkan range tanggal: $e');
    }
  }

  // Update jadwal pemupukan
  Future<void> updateJadwalPemupukan(
    String idJadwal,
    Map<String, dynamic> updateData,
  ) async {
    try {
      await _firestore.collection(_collection).doc(idJadwal).update(updateData);
    } catch (e) {
      throw Exception('Gagal mengupdate jadwal pemupukan: $e');
    }
  }

  // Tandai jadwal sebagai selesai
  Future<void> tandaiSelesai(
    String idJadwal,
    String diselesaikanOleh,
  ) async {
    try {
      await _firestore.collection(_collection).doc(idJadwal).update({
        'sudah_selesai': true,
        'diselesaikan_oleh': diselesaikanOleh,
        'diselesaikan_pada': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Gagal menandai jadwal sebagai selesai: $e');
    }
  }

  // Batalkan penyelesaian jadwal
  Future<void> batalkanSelesai(String idJadwal) async {
    try {
      await _firestore.collection(_collection).doc(idJadwal).update({
        'sudah_selesai': false,
        'diselesaikan_oleh': null,
        'diselesaikan_pada': null,
      });
    } catch (e) {
      throw Exception('Gagal membatalkan penyelesaian jadwal: $e');
    }
  }

  // Hapus jadwal pemupukan
  Future<void> hapusJadwalPemupukan(String idJadwal) async {
    try {
      await _firestore.collection(_collection).doc(idJadwal).delete();
    } catch (e) {
      throw Exception('Gagal menghapus jadwal pemupukan: $e');
    }
  }

  // Ambil jadwal yang akan datang (belum selesai)
  Future<List<JadwalPemupukanModel>> getJadwalMendatang() async {
    try {
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);
      
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('bulan_tahun', isGreaterThanOrEqualTo: Timestamp.fromDate(currentMonth))
          .where('sudah_selesai', isEqualTo: false)
          .orderBy('bulan_tahun')
          .orderBy('minggu_ke')
          .orderBy('hari_dalam_minggu')
          .get();

      return querySnapshot.docs
          .map((doc) => JadwalPemupukanModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil jadwal mendatang: $e');
    }
  }

  // Ambil jadwal yang terlambat
  Future<List<JadwalPemupukanModel>> getJadwalTerlambat() async {
    try {
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);
      
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('bulan_tahun', isLessThanOrEqualTo: Timestamp.fromDate(currentMonth))
          .where('sudah_selesai', isEqualTo: false)
          .orderBy('bulan_tahun')
          .orderBy('minggu_ke')
          .orderBy('hari_dalam_minggu')
          .get();

      List<JadwalPemupukanModel> allJadwal = querySnapshot.docs
          .map((doc) => JadwalPemupukanModel.fromFirestore(doc))
          .toList();

      // Filter jadwal yang benar-benar terlambat
      return allJadwal.where((jadwal) => jadwal.isOverdue()).toList();
    } catch (e) {
      throw Exception('Gagal mengambil jadwal terlambat: $e');
    }
  }

  // Generate jadwal untuk bulan tertentu (template)
  Future<void> generateJadwalBulanan(
    DateTime bulanTahun,
    String dibuatOleh,
  ) async {
    try {
      // Template jadwal default untuk 4 minggu
      final List<Map<String, dynamic>> templateJadwal = [
        // Minggu 1
        {'minggu': 1, 'hari': 1, 'perlakuan': 'Pupuk CEF + PTh', 'tambahan': 'HIRACOL'},
        {'minggu': 1, 'hari': 3, 'perlakuan': 'Pupuk Coklat', 'tambahan': null},
        {'minggu': 1, 'hari': 5, 'perlakuan': 'Pupuk Putih', 'tambahan': 'ANTRACOL'},
        
        // Minggu 2
        {'minggu': 2, 'hari': 1, 'perlakuan': 'Pupuk CEF', 'tambahan': 'Bawang Putih'},
        {'minggu': 2, 'hari': 3, 'perlakuan': 'Pupuk Coklat + HIRACOL', 'tambahan': null},
        {'minggu': 2, 'hari': 5, 'perlakuan': 'Pupuk Putih', 'tambahan': null},
        
        // Minggu 3
        {'minggu': 3, 'hari': 1, 'perlakuan': 'Pupuk CEF + PTh', 'tambahan': 'ANTRACOL'},
        {'minggu': 3, 'hari': 3, 'perlakuan': 'Pupuk Coklat', 'tambahan': 'Bawang Putih'},
        {'minggu': 3, 'hari': 5, 'perlakuan': 'Pupuk Putih + ANTRACOL', 'tambahan': null},
        
        // Minggu 4
        {'minggu': 4, 'hari': 1, 'perlakuan': 'Pupuk CEF', 'tambahan': 'HIRACOL'},
        {'minggu': 4, 'hari': 3, 'perlakuan': 'Pupuk Coklat', 'tambahan': null},
        {'minggu': 4, 'hari': 5, 'perlakuan': 'Treatment Khusus', 'tambahan': 'Kombinasi HIRACOL + ANTRACOL'},
      ];

      // Cek apakah sudah ada jadwal untuk bulan ini
      final existingJadwal = await getJadwalPemupukanByBulan(bulanTahun);
      if (existingJadwal.isNotEmpty) {
        throw Exception('Jadwal untuk bulan ${bulanTahun.month}/${bulanTahun.year} sudah ada');
      }

      // Buat batch write untuk efisiensi
      final batch = _firestore.batch();
      
      for (final template in templateJadwal) {
        final jadwal = JadwalPemupukanModel(
          idJadwal: '',
          bulanTahun: DateTime(bulanTahun.year, bulanTahun.month, 1),
          mingguKe: template['minggu'],
          hariDalamMinggu: template['hari'],
          perlakuanPupuk: template['perlakuan'],
          perlakuanTambahan: template['tambahan'],
          catatan: 'Jadwal otomatis untuk ${bulanTahun.month}/${bulanTahun.year}',
          dibuatOleh: dibuatOleh,
          dibuatPada: DateTime.now(),
        );

        final docRef = _firestore.collection(_collection).doc();
        batch.set(docRef, jadwal.toFirestore());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Gagal generate jadwal bulanan: $e');
    }
  }

  // Statistik jadwal pemupukan
  Future<Map<String, dynamic>> getStatistikJadwal(DateTime bulanTahun) async {
    try {
      final jadwalList = await getJadwalPemupukanByBulan(bulanTahun);
      
      int totalJadwal = jadwalList.length;
      int selesai = jadwalList.where((j) => j.sudahSelesai).length;
      int belumSelesai = totalJadwal - selesai;
      int terlambat = jadwalList.where((j) => j.isOverdue()).length;
      
      double persentaseSelesai = totalJadwal > 0 ? (selesai / totalJadwal) * 100 : 0;
      
      return {
        'total_jadwal': totalJadwal,
        'selesai': selesai,
        'belum_selesai': belumSelesai,
        'terlambat': terlambat,
        'persentase_selesai': persentaseSelesai,
        'bulan_tahun': '${bulanTahun.month}/${bulanTahun.year}',
      };
    } catch (e) {
      throw Exception('Gagal mengambil statistik jadwal: $e');
    }
  }

  // Stream untuk real-time updates
  Stream<List<JadwalPemupukanModel>> streamJadwalPemupukan() {
    return _firestore
        .collection(_collection)
        .orderBy('bulan_tahun', descending: true)
        .orderBy('minggu_ke')
        .orderBy('hari_dalam_minggu')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JadwalPemupukanModel.fromFirestore(doc))
            .toList());
  }

  // Stream untuk jadwal bulan tertentu
  Stream<List<JadwalPemupukanModel>> streamJadwalByBulan(DateTime bulanTahun) {
    final startOfMonth = DateTime(bulanTahun.year, bulanTahun.month, 1);
    final endOfMonth = DateTime(bulanTahun.year, bulanTahun.month + 1, 1).subtract(const Duration(days: 1));

    return _firestore
        .collection(_collection)
        .where('bulan_tahun', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('bulan_tahun', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .orderBy('bulan_tahun')
        .orderBy('minggu_ke')
        .orderBy('hari_dalam_minggu')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JadwalPemupukanModel.fromFirestore(doc))
            .toList());
  }
}