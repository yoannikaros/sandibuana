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

  // Get monitoring by pembenihan
  Future<List<MonitoringNutrisiModel>> getMonitoringByPembenihan(String pembenihanId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('id_pembenihan', isEqualTo: pembenihanId)
          .orderBy('tanggal_monitoring', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MonitoringNutrisiModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil monitoring berdasarkan pembenihan: $e');
    }
  }

  // Get monitoring by penanaman
  Future<List<MonitoringNutrisiModel>> getMonitoringByPenanaman(String penanamanId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('id_penanaman', isEqualTo: penanamanId)
          .orderBy('tanggal_monitoring', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MonitoringNutrisiModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil monitoring berdasarkan penanaman: $e');
    }
  }

  // Get monitoring by tandon (supports multiple tandon)
  Future<List<MonitoringNutrisiModel>> getMonitoringByTandon(String tandonId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('id_tandon', arrayContains: tandonId)
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
        // Search in tandon data catatan
        if (monitoring.tandonData != null) {
          for (final tandon in monitoring.tandonData!) {
            if (tandon.catatan?.toLowerCase().contains(searchLower) ?? false) {
              return true;
            }
          }
        }
        return false;
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
  Future<bool> addMonitoring(MonitoringNutrisiModel monitoring) async {
    try {
      await _firestore.collection(_collection).add(monitoring.toFirestore());
      return true;
    } catch (e) {
      throw Exception('Gagal menambah monitoring: $e');
    }
  }

  // Add new monitoring with auto-filled user (legacy method)
  Future<String> addMonitoringWithUser(MonitoringNutrisiModel monitoring, String currentUserId) async {
    try {
      // Auto-fill dicatatOleh with current user
      final monitoringWithUser = monitoring.copyWith(
        dicatatOleh: currentUserId,
        dicatatPada: DateTime.now(),
      );
      
      final docRef = await _firestore.collection(_collection).add(monitoringWithUser.toFirestore());
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

      // Extract values from tandon data
      final ppmValues = <double>[];
      final phValues = <double>[];
      final tempValues = <double>[];
      
      for (final monitoring in monitoringList) {
        if (monitoring.tandonData != null) {
          for (final tandon in monitoring.tandonData!) {
            if (tandon.nilaiPpm != null && tandon.nilaiPpm! > 0) ppmValues.add(tandon.nilaiPpm!);
            if (tandon.tingkatPh != null && tandon.tingkatPh! > 0) phValues.add(tandon.tingkatPh!);
            if (tandon.suhuAir != null && tandon.suhuAir! > 0) tempValues.add(tandon.suhuAir!);
          }
        }
      }

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
        'totalWaterAdded': monitoringList.fold<double>(0, (sum, m) => sum + (m.tandonData?.fold<double>(0, (tandonSum, tandon) => tandonSum + (tandon.airDitambah ?? 0)) ?? 0)),
        'totalNutrientAdded': monitoringList.fold<double>(0, (sum, m) => sum + (m.tandonData?.fold<double>(0, (tandonSum, tandon) => tandonSum + (tandon.nutrisiDitambah ?? 0)) ?? 0)),
      };
    } catch (e) {
      throw Exception('Gagal mengambil statistik monitoring: $e');
    }
  }

  // Get monitoring count by pembenihan
  Future<Map<String, int>> getMonitoringCountByPembenihan(DateTime? startDate, DateTime? endDate) async {
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

      final countByPembenihan = <String, int>{};
      for (final monitoring in monitoringList) {
        if (monitoring.idPembenihan != null) {
          countByPembenihan[monitoring.idPembenihan!] = (countByPembenihan[monitoring.idPembenihan!] ?? 0) + 1;
        }
      }

      return countByPembenihan;
    } catch (e) {
      throw Exception('Gagal mengambil jumlah monitoring per pembenihan: $e');
    }
  }

  // Get monitoring count by penanaman
  Future<Map<String, int>> getMonitoringCountByPenanaman(DateTime? startDate, DateTime? endDate) async {
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

      final countByPenanaman = <String, int>{};
      for (final monitoring in monitoringList) {
        if (monitoring.idPenanaman != null) {
          countByPenanaman[monitoring.idPenanaman!] = (countByPenanaman[monitoring.idPenanaman!] ?? 0) + 1;
        }
      }

      return countByPenanaman;
    } catch (e) {
      throw Exception('Gagal mengambil jumlah monitoring per penanaman: $e');
    }
  }

  // Get average values by pembenihan
  Future<Map<String, Map<String, double>>> getAverageValuesByPembenihan(
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

      final groupedByPembenihan = <String, List<MonitoringNutrisiModel>>{};
      for (final monitoring in monitoringList) {
        if (monitoring.idPembenihan != null) {
          groupedByPembenihan.putIfAbsent(monitoring.idPembenihan!, () => []).add(monitoring);
        }
      }

      final averagesByPembenihan = <String, Map<String, double>>{};
      groupedByPembenihan.forEach((pembenihanId, monitoringList) {
        if (monitoringList.isNotEmpty) {
          // Calculate averages from tandon data
          final allPpmValues = <double>[];
          final allPhValues = <double>[];
          final allTempValues = <double>[];
          
          for (final monitoring in monitoringList) {
            if (monitoring.tandonData != null) {
              for (final tandon in monitoring.tandonData!) {
                if (tandon.nilaiPpm != null) allPpmValues.add(tandon.nilaiPpm!);
                if (tandon.tingkatPh != null) allPhValues.add(tandon.tingkatPh!);
                if (tandon.suhuAir != null) allTempValues.add(tandon.suhuAir!);
              }
            }
          }
          
          final avgPpm = allPpmValues.isNotEmpty ? allPpmValues.fold<double>(0, (sum, val) => sum + val) / allPpmValues.length : 0.0;
          final avgPh = allPhValues.isNotEmpty ? allPhValues.fold<double>(0, (sum, val) => sum + val) / allPhValues.length : 0.0;
          final avgTemp = allTempValues.isNotEmpty ? allTempValues.fold<double>(0, (sum, val) => sum + val) / allTempValues.length : 0.0;

          averagesByPembenihan[pembenihanId] = {
            'averagePpm': avgPpm,
            'averagePh': avgPh,
            'averageTemp': avgTemp,
          };
        }
      });

      return averagesByPembenihan;
    } catch (e) {
      throw Exception('Gagal mengambil rata-rata nilai per pembenihan: $e');
    }
  }

  // Get average values by penanaman
  Future<Map<String, Map<String, double>>> getAverageValuesByPenanaman(
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

      final groupedByPenanaman = <String, List<MonitoringNutrisiModel>>{};
      for (final monitoring in monitoringList) {
        if (monitoring.idPenanaman != null) {
          groupedByPenanaman.putIfAbsent(monitoring.idPenanaman!, () => []).add(monitoring);
        }
      }

      final averagesByPenanaman = <String, Map<String, double>>{};
      groupedByPenanaman.forEach((penanamanId, monitoringList) {
        if (monitoringList.isNotEmpty) {
          // Calculate averages from tandon data
          final allPpmValues = <double>[];
          final allPhValues = <double>[];
          final allTempValues = <double>[];
          
          for (final monitoring in monitoringList) {
            if (monitoring.tandonData != null) {
              for (final tandon in monitoring.tandonData!) {
                if (tandon.nilaiPpm != null) allPpmValues.add(tandon.nilaiPpm!);
                if (tandon.tingkatPh != null) allPhValues.add(tandon.tingkatPh!);
                if (tandon.suhuAir != null) allTempValues.add(tandon.suhuAir!);
              }
            }
          }
          
          final avgPpm = allPpmValues.isNotEmpty ? allPpmValues.fold<double>(0, (sum, val) => sum + val) / allPpmValues.length : 0.0;
          final avgPh = allPhValues.isNotEmpty ? allPhValues.fold<double>(0, (sum, val) => sum + val) / allPhValues.length : 0.0;
          final avgTemp = allTempValues.isNotEmpty ? allTempValues.fold<double>(0, (sum, val) => sum + val) / allTempValues.length : 0.0;

          averagesByPenanaman[penanamanId] = {
            'averagePpm': avgPpm,
            'averagePh': avgPh,
            'averageTemp': avgTemp,
          };
        }
      });

      return averagesByPenanaman;
    } catch (e) {
      throw Exception('Gagal mengambil rata-rata nilai per penanaman: $e');
    }
  }

  // Get latest monitoring for each pembenihan
  Future<Map<String, MonitoringNutrisiModel>> getLatestMonitoringByPembenihan() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('tanggal_monitoring', descending: true)
          .get();

      final monitoringList = querySnapshot.docs
          .map((doc) => MonitoringNutrisiModel.fromFirestore(doc))
          .toList();

      final latestByPembenihan = <String, MonitoringNutrisiModel>{};
      for (final monitoring in monitoringList) {
        if (monitoring.idPembenihan != null && !latestByPembenihan.containsKey(monitoring.idPembenihan!)) {
          latestByPembenihan[monitoring.idPembenihan!] = monitoring;
        }
      }

      return latestByPembenihan;
    } catch (e) {
      throw Exception('Gagal mengambil monitoring terbaru per pembenihan: $e');
    }
  }

  // Get latest monitoring for each penanaman
  Future<Map<String, MonitoringNutrisiModel>> getLatestMonitoringByPenanaman() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('tanggal_monitoring', descending: true)
          .get();

      final monitoringList = querySnapshot.docs
          .map((doc) => MonitoringNutrisiModel.fromFirestore(doc))
          .toList();

      final latestByPenanaman = <String, MonitoringNutrisiModel>{};
      for (final monitoring in monitoringList) {
        if (monitoring.idPenanaman != null && !latestByPenanaman.containsKey(monitoring.idPenanaman!)) {
          latestByPenanaman[monitoring.idPenanaman!] = monitoring;
        }
      }

      return latestByPenanaman;
    } catch (e) {
      throw Exception('Gagal mengambil monitoring terbaru per penanaman: $e');
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

  // Real-time monitoring stream by pembenihan
  Stream<List<MonitoringNutrisiModel>> getMonitoringStreamByPembenihan(String pembenihanId) {
    return _firestore
        .collection(_collection)
        .where('id_pembenihan', isEqualTo: pembenihanId)
        .orderBy('tanggal_monitoring', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MonitoringNutrisiModel.fromFirestore(doc))
            .toList());
  }

  // Real-time monitoring stream by penanaman
  Stream<List<MonitoringNutrisiModel>> getMonitoringStreamByPenanaman(String penanamanId) {
    return _firestore
        .collection(_collection)
        .where('id_penanaman', isEqualTo: penanamanId)
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