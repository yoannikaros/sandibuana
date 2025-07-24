import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tandon_air_model.dart';
import '../models/monitoring_nutrisi_model.dart';

class TandonService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _tandonCollection = 'tandon_air';
  final String _monitoringCollection = 'monitoring_nutrisi_harian';

  // ========================================
  // TANDON AIR OPERATIONS
  // ========================================

  // Get all tandon air with client-side sorting
  Future<List<TandonAirModel>> getAllTandonAir() async {
    try {
      final querySnapshot = await _firestore.collection(_tandonCollection).get();
      final tandons = querySnapshot.docs
          .map((doc) => TandonAirModel.fromFirestore(doc))
          .toList();
      
      // Client-side sorting by kode_tandon
      tandons.sort((a, b) => a.kodeTandon.compareTo(b.kodeTandon));
      return tandons;
    } catch (e) {
      throw Exception('Gagal mengambil data tandon air: $e');
    }
  }

  // Get active tandon air only
  Future<List<TandonAirModel>> getTandonAirAktif() async {
    try {
      final querySnapshot = await _firestore
          .collection(_tandonCollection)
          .where('aktif', isEqualTo: true)
          .get();
      
      final tandons = querySnapshot.docs
          .map((doc) => TandonAirModel.fromFirestore(doc))
          .toList();
      
      // Client-side sorting by kode_tandon
      tandons.sort((a, b) => a.kodeTandon.compareTo(b.kodeTandon));
      return tandons;
    } catch (e) {
      throw Exception('Gagal mengambil data tandon air aktif: $e');
    }
  }

  // Search tandon air with client-side filtering
  Future<List<TandonAirModel>> cariTandonAir(String query) async {
    try {
      final allTandons = await getAllTandonAir();
      
      if (query.isEmpty) return allTandons;
      
      final searchQuery = query.toLowerCase();
      return allTandons.where((tandon) {
        return tandon.kodeTandon.toLowerCase().contains(searchQuery) ||
               (tandon.namaTandon?.toLowerCase().contains(searchQuery) ?? false) ||
               (tandon.lokasi?.toLowerCase().contains(searchQuery) ?? false);
      }).toList();
    } catch (e) {
      throw Exception('Gagal mencari tandon air: $e');
    }
  }

  // Add new tandon air
  Future<void> tambahTandonAir(TandonAirModel tandon) async {
    try {
      await _firestore.collection(_tandonCollection).add(tandon.toFirestore());
    } catch (e) {
      throw Exception('Gagal menambah tandon air: $e');
    }
  }

  // Update tandon air
  Future<void> updateTandonAir(TandonAirModel tandon) async {
    try {
      await _firestore
          .collection(_tandonCollection)
          .doc(tandon.id)
          .update(tandon.toFirestore());
    } catch (e) {
      throw Exception('Gagal mengupdate tandon air: $e');
    }
  }

  // Delete tandon air
  Future<void> hapusTandonAir(String id) async {
    try {
      await _firestore.collection(_tandonCollection).doc(id).delete();
    } catch (e) {
      throw Exception('Gagal menghapus tandon air: $e');
    }
  }

  // Get tandon air by ID
  Future<TandonAirModel?> getTandonAirById(String id) async {
    try {
      final doc = await _firestore.collection(_tandonCollection).doc(id).get();
      if (doc.exists) {
        return TandonAirModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil tandon air: $e');
    }
  }

  // Stream tandon air aktif for real-time updates
  Stream<List<TandonAirModel>> streamTandonAirAktif() {
    return _firestore
        .collection(_tandonCollection)
        .where('aktif', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final tandons = snapshot.docs
          .map((doc) => TandonAirModel.fromFirestore(doc))
          .toList();
      
      // Client-side sorting
      tandons.sort((a, b) => a.kodeTandon.compareTo(b.kodeTandon));
      return tandons;
    });
  }

  // ========================================
  // MONITORING NUTRISI OPERATIONS
  // ========================================

  // Get monitoring nutrisi by date range with client-side filtering
  Future<List<MonitoringNutrisiModel>> getMonitoringNutrisiByTanggal(
      DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await _firestore.collection(_monitoringCollection).get();
      final monitorings = querySnapshot.docs
          .map((doc) => MonitoringNutrisiModel.fromFirestore(doc))
          .toList();
      
      // Client-side filtering by date range
      final filtered = monitorings.where((monitoring) {
        final tanggal = monitoring.tanggalMonitoring;
        return tanggal.isAfter(startDate.subtract(const Duration(days: 1))) &&
               tanggal.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
      
      // Sort by date descending
      filtered.sort((a, b) => b.tanggalMonitoring.compareTo(a.tanggalMonitoring));
      return filtered;
    } catch (e) {
      throw Exception('Gagal mengambil data monitoring nutrisi: $e');
    }
  }

  // Get monitoring nutrisi by tandon
  Future<List<MonitoringNutrisiModel>> getMonitoringNutrisiByTandon(String idTandon) async {
    try {
      final querySnapshot = await _firestore
          .collection(_monitoringCollection)
          .where('id_tandon', isEqualTo: idTandon)
          .get();
      
      final monitorings = querySnapshot.docs
          .map((doc) => MonitoringNutrisiModel.fromFirestore(doc))
          .toList();
      
      // Client-side sorting by date descending
      monitorings.sort((a, b) => b.tanggalMonitoring.compareTo(a.tanggalMonitoring));
      return monitorings;
    } catch (e) {
      throw Exception('Gagal mengambil data monitoring nutrisi: $e');
    }
  }

  // Get all monitoring nutrisi
  Future<List<MonitoringNutrisiModel>> getAllMonitoringNutrisi() async {
    try {
      final querySnapshot = await _firestore.collection(_monitoringCollection).get();
      final monitorings = querySnapshot.docs
          .map((doc) => MonitoringNutrisiModel.fromFirestore(doc))
          .toList();
      
      // Client-side sorting by date descending
      monitorings.sort((a, b) => b.tanggalMonitoring.compareTo(a.tanggalMonitoring));
      return monitorings;
    } catch (e) {
      throw Exception('Gagal mengambil data monitoring nutrisi: $e');
    }
  }

  // Add new monitoring nutrisi
  Future<void> tambahMonitoringNutrisi(MonitoringNutrisiModel monitoring) async {
    try {
      await _firestore.collection(_monitoringCollection).add(monitoring.toFirestore());
    } catch (e) {
      throw Exception('Gagal menambah monitoring nutrisi: $e');
    }
  }

  // Update monitoring nutrisi
  Future<void> updateMonitoringNutrisi(MonitoringNutrisiModel monitoring) async {
    try {
      await _firestore
          .collection(_monitoringCollection)
          .doc(monitoring.id)
          .update(monitoring.toFirestore());
    } catch (e) {
      throw Exception('Gagal mengupdate monitoring nutrisi: $e');
    }
  }

  // Delete monitoring nutrisi
  Future<void> hapusMonitoringNutrisi(String id) async {
    try {
      await _firestore.collection(_monitoringCollection).doc(id).delete();
    } catch (e) {
      throw Exception('Gagal menghapus monitoring nutrisi: $e');
    }
  }

  // Get monitoring nutrisi by ID
  Future<MonitoringNutrisiModel?> getMonitoringNutrisiById(String id) async {
    try {
      final doc = await _firestore.collection(_monitoringCollection).doc(id).get();
      if (doc.exists) {
        return MonitoringNutrisiModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil monitoring nutrisi: $e');
    }
  }

  // Stream monitoring nutrisi for real-time updates
  Stream<List<MonitoringNutrisiModel>> streamMonitoringNutrisi() {
    return _firestore
        .collection(_monitoringCollection)
        .snapshots()
        .map((snapshot) {
      final monitorings = snapshot.docs
          .map((doc) => MonitoringNutrisiModel.fromFirestore(doc))
          .toList();
      
      // Client-side sorting by date descending
      monitorings.sort((a, b) => b.tanggalMonitoring.compareTo(a.tanggalMonitoring));
      return monitorings;
    });
  }

  // ========================================
  // INITIALIZATION
  // ========================================

  // Initialize default tandon air data
  Future<void> initializeDefaultTandonAir() async {
    try {
      final existingTandons = await getAllTandonAir();
      if (existingTandons.isNotEmpty) return; // Data already exists

      final defaultTandons = [
        TandonAirModel(
          id: '',
          kodeTandon: 'P1',
          namaTandon: 'Tandon P1',
          kapasitas: 1000,
          lokasi: 'Area Produksi 1',
        ),
        TandonAirModel(
          id: '',
          kodeTandon: 'P2',
          namaTandon: 'Tandon P2',
          kapasitas: 1000,
          lokasi: 'Area Produksi 2',
        ),
        TandonAirModel(
          id: '',
          kodeTandon: 'P3',
          namaTandon: 'Tandon P3',
          kapasitas: 1000,
          lokasi: 'Area Produksi 3',
        ),
        TandonAirModel(
          id: '',
          kodeTandon: 'R1',
          namaTandon: 'Tandon R1',
          kapasitas: 800,
          lokasi: 'Area Romaine 1',
        ),
        TandonAirModel(
          id: '',
          kodeTandon: 'R2',
          namaTandon: 'Tandon R2',
          kapasitas: 800,
          lokasi: 'Area Romaine 2',
        ),
        TandonAirModel(
          id: '',
          kodeTandon: 'R3',
          namaTandon: 'Tandon R3',
          kapasitas: 800,
          lokasi: 'Area Romaine 3',
        ),
        TandonAirModel(
          id: '',
          kodeTandon: 'S1',
          namaTandon: 'Tandon S1',
          kapasitas: 600,
          lokasi: 'Area Semai 1',
        ),
        TandonAirModel(
          id: '',
          kodeTandon: 'S2',
          namaTandon: 'Tandon S2',
          kapasitas: 600,
          lokasi: 'Area Semai 2',
        ),
        TandonAirModel(
          id: '',
          kodeTandon: 'S3',
          namaTandon: 'Tandon S3',
          kapasitas: 600,
          lokasi: 'Area Semai 3',
        ),
        TandonAirModel(
          id: '',
          kodeTandon: '6HA',
          namaTandon: 'Tandon 6HA',
          kapasitas: 1500,
          lokasi: 'Area 6 Hektar',
        ),
      ];

      for (final tandon in defaultTandons) {
        await tambahTandonAir(tandon);
      }
    } catch (e) {
      throw Exception('Gagal menginisialisasi data tandon air: $e');
    }
  }
}