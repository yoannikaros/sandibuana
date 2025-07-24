import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/monitoring_nutrisi_model.dart';

class MonitoringNutrisiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'monitoring_nutrisi_harian';

  // Get all monitoring data
  Future<List<MonitoringNutrisiModel>> getAllMonitoring() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('tanggal_monitoring', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MonitoringNutrisiModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data monitoring: $e');
    }
  }

  // Get monitoring by date range
  Future<List<MonitoringNutrisiModel>> getMonitoringByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('tanggal_monitoring', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('tanggal_monitoring', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('tanggal_monitoring', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MonitoringNutrisiModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil monitoring berdasarkan tanggal: $e');
    }
  }

  // Get monitoring by tandon
  Future<List<MonitoringNutrisiModel>> getMonitoringByTandon(String tandonId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('id_tandon', isEqualTo: tandonId)
          .orderBy('tanggal_monitoring', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MonitoringNutrisiModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil monitoring berdasarkan tandon: $e');
    }
  }

  // Search monitoring by notes
  Future<List<MonitoringNutrisiModel>> searchMonitoring(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('tanggal_monitoring', descending: true)
          .get();

      final allMonitoring = querySnapshot.docs
          .map((doc) => MonitoringNutrisiModel.fromFirestore(doc))
          .toList();

      // Filter by search query (case-insensitive)
      final searchLower = query.toLowerCase();
      return allMonitoring.where((monitoring) {
        return monitoring.catatan?.toLowerCase().contains(searchLower) ?? false;
      }).toList();
    } catch (e) {
      throw Exception('Gagal mencari monitoring: $e');
    }
  }

  // Get monitoring by ID
  Future<MonitoringNutrisiModel?> getMonitoringById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return MonitoringNutrisiModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil monitoring: $e');
    }
  }

  // Add new monitoring
  Future<String> addMonitoring(MonitoringNutrisiModel monitoring) async {
    try {
      final docRef = await _firestore.collection(_collection).add(monitoring.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Gagal menambah monitoring: $e');
    }
  }

  // Update monitoring
  Future<bool> updateMonitoring(MonitoringNutrisiModel monitoring) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(monitoring.id)
          .update(monitoring.toFirestore());
      return true;
    } catch (e) {
      throw Exception('Gagal mengupdate monitoring: $e');
    }
  }

  // Delete monitoring
  Future<bool> deleteMonitoring(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      throw Exception('Gagal menghapus monitoring: $e');
    }
  }

  // Get monitoring statistics for date range
  Future<Map<String, dynamic>> getStatistics(DateTime? startDate, DateTime? endDate) async {
    try {
      Query query = _firestore.collection(_collection);

      if (startDate != null && endDate != null) {
        query = query
            .where('tanggal_monitoring', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('tanggal_monitoring', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final querySnapshot = await query.get();
      final monitoringList = querySnapshot.docs
          .map((doc) => MonitoringNutrisiModel.fromFirestore(doc))
          .toList();

      if (monitoringList.isEmpty) {
        return {
          'count': 0,
          'averagePpm': 0.0,
          'averagePh': 0.0,
          'averageTemp': 0.0,
          'minPpm': 0.0,
          'maxPpm': 0.0,
          'minPh': 0.0,
          'maxPh': 0.0,
          'minTemp': 0.0,
          'maxTemp': 0.0,
          'totalWaterAdded': 0.0,
          'totalNutrientAdded': 0.0,
        };
      }

      final ppmValues = monitoringList.map((m) => m.nilaiPpm ?? 0.0).where((val) => val > 0).toList();
      final phValues = monitoringList.map((m) => m.tingkatPh ?? 0.0).where((val) => val > 0).toList();
      final tempValues = monitoringList.map((m) => m.suhuAir ?? 0.0).where((val) => val > 0).toList();

      return {
        'count': monitoringList.length,
        'averagePpm': ppmValues.isNotEmpty ? ppmValues.fold<double>(0, (sum, val) => sum + val) / ppmValues.length : 0.0,
        'averagePh': phValues.isNotEmpty ? phValues.fold<double>(0, (sum, val) => sum + val) / phValues.length : 0.0,
        'averageTemp': tempValues.isNotEmpty ? tempValues.fold<double>(0, (sum, val) => sum + val) / tempValues.length : 0.0,
        'minPpm': ppmValues.isNotEmpty ? ppmValues.reduce((a, b) => a < b ? a : b) : 0.0,
        'maxPpm': ppmValues.isNotEmpty ? ppmValues.reduce((a, b) => a > b ? a : b) : 0.0,
        'minPh': phValues.isNotEmpty ? phValues.reduce((a, b) => a < b ? a : b) : 0.0,
        'maxPh': phValues.isNotEmpty ? phValues.reduce((a, b) => a > b ? a : b) : 0.0,
        'minTemp': tempValues.isNotEmpty ? tempValues.reduce((a, b) => a < b ? a : b) : 0.0,
        'maxTemp': tempValues.isNotEmpty ? tempValues.reduce((a, b) => a > b ? a : b) : 0.0,
        'totalWaterAdded': monitoringList.fold<double>(0, (sum, m) => sum + (m.airDitambah ?? 0)),
        'totalNutrientAdded': monitoringList.fold<double>(0, (sum, m) => sum + (m.nutrisiDitambah ?? 0)),
      };
    } catch (e) {
      throw Exception('Gagal mengambil statistik monitoring: $e');
    }
  }

  // Get monitoring count by tandon
  Future<Map<String, int>> getMonitoringCountByTandon(DateTime? startDate, DateTime? endDate) async {
    try {
      Query query = _firestore.collection(_collection);

      if (startDate != null && endDate != null) {
        query = query
            .where('tanggal_monitoring', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('tanggal_monitoring', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final querySnapshot = await query.get();
      final monitoringList = querySnapshot.docs
          .map((doc) => MonitoringNutrisiModel.fromFirestore(doc))
          .toList();

      final countByTandon = <String, int>{};
      for (final monitoring in monitoringList) {
        countByTandon[monitoring.idTandon] = (countByTandon[monitoring.idTandon] ?? 0) + 1;
      }

      return countByTandon;
    } catch (e) {
      throw Exception('Gagal mengambil jumlah monitoring per tandon: $e');
    }
  }

  // Get average values by tandon
  Future<Map<String, Map<String, double>>> getAverageValuesByTandon(
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      Query query = _firestore.collection(_collection);

      if (startDate != null && endDate != null) {
        query = query
            .where('tanggal_monitoring', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('tanggal_monitoring', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final querySnapshot = await query.get();
      final monitoringList = querySnapshot.docs
          .map((doc) => MonitoringNutrisiModel.fromFirestore(doc))
          .toList();

      final groupedByTandon = <String, List<MonitoringNutrisiModel>>{};
      for (final monitoring in monitoringList) {
        groupedByTandon.putIfAbsent(monitoring.idTandon, () => []).add(monitoring);
      }

      final averagesByTandon = <String, Map<String, double>>{};
      groupedByTandon.forEach((tandonId, monitoringList) {
        if (monitoringList.isNotEmpty) {
          final avgPpm = monitoringList.fold<double>(0, (sum, m) => sum + (m.nilaiPpm ?? 0)) / monitoringList.length;
          final avgPh = monitoringList.fold<double>(0, (sum, m) => sum + (m.tingkatPh ?? 0)) / monitoringList.length;
          final avgTemp = monitoringList.fold<double>(0, (sum, m) => sum + (m.suhuAir ?? 0)) / monitoringList.length;

          averagesByTandon[tandonId] = {
            'averagePpm': avgPpm,
            'averagePh': avgPh,
            'averageTemp': avgTemp,
          };
        }
      });

      return averagesByTandon;
    } catch (e) {
      throw Exception('Gagal mengambil rata-rata nilai per tandon: $e');
    }
  }

  // Get latest monitoring for each tandon
  Future<Map<String, MonitoringNutrisiModel>> getLatestMonitoringByTandon() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('tanggal_monitoring', descending: true)
          .get();

      final monitoringList = querySnapshot.docs
          .map((doc) => MonitoringNutrisiModel.fromFirestore(doc))
          .toList();

      final latestByTandon = <String, MonitoringNutrisiModel>{};
      for (final monitoring in monitoringList) {
        if (!latestByTandon.containsKey(monitoring.idTandon)) {
          latestByTandon[monitoring.idTandon] = monitoring;
        }
      }

      return latestByTandon;
    } catch (e) {
      throw Exception('Gagal mengambil monitoring terbaru per tandon: $e');
    }
  }

  // Real-time monitoring stream
  Stream<List<MonitoringNutrisiModel>> getMonitoringStream() {
    return _firestore
        .collection(_collection)
        .orderBy('tanggal_monitoring', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MonitoringNutrisiModel.fromFirestore(doc))
            .toList());
  }

  // Real-time monitoring stream by tandon
  Stream<List<MonitoringNutrisiModel>> getMonitoringStreamByTandon(String tandonId) {
    return _firestore
        .collection(_collection)
        .where('id_tandon', isEqualTo: tandonId)
        .orderBy('tanggal_monitoring', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MonitoringNutrisiModel.fromFirestore(doc))
            .toList());
  }

  // Real-time monitoring stream by date range
  Stream<List<MonitoringNutrisiModel>> getMonitoringStreamByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _firestore
        .collection(_collection)
        .where('tanggal_monitoring', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('tanggal_monitoring', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('tanggal_monitoring', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MonitoringNutrisiModel.fromFirestore(doc))
            .toList());
  }

  // Batch operations
  Future<bool> addMultipleMonitoring(List<MonitoringNutrisiModel> monitoringList) async {
    try {
      final batch = _firestore.batch();
      
      for (final monitoring in monitoringList) {
        final docRef = _firestore.collection(_collection).doc();
        batch.set(docRef, monitoring.toFirestore());
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      throw Exception('Gagal menambah multiple monitoring: $e');
    }
  }

  Future<bool> deleteMultipleMonitoring(List<String> ids) async {
    try {
      final batch = _firestore.batch();
      
      for (final id in ids) {
        final docRef = _firestore.collection(_collection).doc(id);
        batch.delete(docRef);
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      throw Exception('Gagal menghapus multiple monitoring: $e');
    }
  }
}