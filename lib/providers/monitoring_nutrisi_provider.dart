import 'package:flutter/material.dart';
import '../models/monitoring_nutrisi_model.dart';
import '../models/tandon_air_model.dart';
import '../services/monitoring_nutrisi_service.dart';
import '../services/tandon_service.dart';

class MonitoringNutrisiProvider with ChangeNotifier {
  final MonitoringNutrisiService _monitoringService = MonitoringNutrisiService();
  final TandonService _tandonService = TandonService();

  // State variables
  List<MonitoringNutrisiModel> _monitoringList = [];
  List<MonitoringNutrisiModel> _filteredMonitoringList = [];
  List<TandonAirModel> _tandonList = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Filter variables
  String _searchQuery = '';
  String? _selectedTandonId;
  DateTime? _startDate;
  DateTime? _endDate;

  // Getters
  List<MonitoringNutrisiModel> get monitoringList => _filteredMonitoringList;
  List<TandonAirModel> get tandonList => _tandonList;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  // Statistics getters
  int get totalCount => _filteredMonitoringList.length;
  
  double get averagePpm {
    if (_filteredMonitoringList.isEmpty) return 0;
    final total = _filteredMonitoringList.fold<double>(0, (sum, item) => sum + (item.nilaiPpm ?? 0));
    return total / _filteredMonitoringList.length;
  }
  
  double get averagePh {
    if (_filteredMonitoringList.isEmpty) return 0;
    final total = _filteredMonitoringList.fold<double>(0, (sum, item) => sum + (item.tingkatPh ?? 0));
    return total / _filteredMonitoringList.length;
  }
  
  double get averageTemp {
    if (_filteredMonitoringList.isEmpty) return 0;
    final total = _filteredMonitoringList.fold<double>(0, (sum, item) => sum + (item.suhuAir ?? 0));
    return total / _filteredMonitoringList.length;
  }

  // Initialize provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _setLoading(true);
    try {
      await Future.wait([
        loadMonitoring(),
        loadTandonList(),
      ]);
      _isInitialized = true;
    } catch (e) {
      _setError('Gagal menginisialisasi data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load all monitoring data
  Future<void> loadMonitoring() async {
    try {
      _monitoringList = await _monitoringService.getAllMonitoring();
      _applyFilters();
    } catch (e) {
      _setError('Gagal memuat data monitoring: $e');
    }
  }

  // Load tandon list
  Future<void> loadTandonList() async {
    try {
      _tandonList = await _tandonService.getAllTandonAir();
      notifyListeners();
    } catch (e) {
      _setError('Gagal memuat data tandon: $e');
    }
  }

  // Add new monitoring
  Future<bool> tambahMonitoring(MonitoringNutrisiModel monitoring) async {
    _setLoading(true);
    try {
      final id = await _monitoringService.addMonitoring(monitoring);
      if (id.isNotEmpty) {
        await loadMonitoring();
        _setLoading(false);
        return true;
      }
      _setError('Gagal menambah monitoring');
      return false;
    } catch (e) {
      _setError('Gagal menambah monitoring: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update monitoring
  Future<bool> updateMonitoring(MonitoringNutrisiModel monitoring) async {
    _setLoading(true);
    try {
      final success = await _monitoringService.updateMonitoring(monitoring);
      if (success) {
        await loadMonitoring();
        _setLoading(false);
        return true;
      }
      _setError('Gagal mengupdate monitoring');
      return false;
    } catch (e) {
      _setError('Gagal mengupdate monitoring: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete monitoring
  Future<bool> hapusMonitoring(String id) async {
    _setLoading(true);
    try {
      final success = await _monitoringService.deleteMonitoring(id);
      if (success) {
        await loadMonitoring();
        _setLoading(false);
        return true;
      }
      _setError('Gagal menghapus monitoring');
      return false;
    } catch (e) {
      _setError('Gagal menghapus monitoring: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Search monitoring
  void searchMonitoring(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  // Filter by tandon
  void filterByTandon(String? tandonId) {
    _selectedTandonId = tandonId;
    _applyFilters();
  }

  // Filter by date range
  void filterByDateRange(DateTime startDate, DateTime endDate) {
    _startDate = startDate;
    _endDate = endDate;
    _applyFilters();
  }

  // Clear date filter
  void clearDateFilter() {
    _startDate = null;
    _endDate = null;
    _applyFilters();
  }

  // Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedTandonId = null;
    _startDate = null;
    _endDate = null;
    _applyFilters();
  }

  // Apply all filters
  void _applyFilters() {
    _filteredMonitoringList = _monitoringList.where((monitoring) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        final matchesSearch = (monitoring.catatan?.toLowerCase().contains(searchLower) ?? false) ||
                            getTandonName(monitoring.idTandon).toLowerCase().contains(searchLower);
        if (!matchesSearch) return false;
      }

      // Tandon filter
      if (_selectedTandonId != null && monitoring.idTandon != _selectedTandonId) {
        return false;
      }

      // Date range filter
      if (_startDate != null && _endDate != null) {
        final monitoringDate = DateTime(
          monitoring.tanggalMonitoring.year,
          monitoring.tanggalMonitoring.month,
          monitoring.tanggalMonitoring.day,
        );
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
        
        if (monitoringDate.isBefore(start) || monitoringDate.isAfter(end)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort by date (newest first)
    _filteredMonitoringList.sort((a, b) => b.tanggalMonitoring.compareTo(a.tanggalMonitoring));
    
    notifyListeners();
  }

  // Get monitoring by date range
  Future<List<MonitoringNutrisiModel>> getMonitoringByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      return await _monitoringService.getMonitoringByDateRange(startDate, endDate);
    } catch (e) {
      _setError('Gagal memuat monitoring berdasarkan tanggal: $e');
      return [];
    }
  }

  // Get monitoring by tandon
  Future<List<MonitoringNutrisiModel>> getMonitoringByTandon(String tandonId) async {
    try {
      return await _monitoringService.getMonitoringByTandon(tandonId);
    } catch (e) {
      _setError('Gagal memuat monitoring berdasarkan tandon: $e');
      return [];
    }
  }

  // Get monitoring statistics for date range
  Map<String, dynamic> getStatistics(DateTime? startDate, DateTime? endDate) {
    List<MonitoringNutrisiModel> dataToAnalyze;
    
    if (startDate != null && endDate != null) {
      dataToAnalyze = _monitoringList.where((monitoring) {
        final monitoringDate = DateTime(
          monitoring.tanggalMonitoring.year,
          monitoring.tanggalMonitoring.month,
          monitoring.tanggalMonitoring.day,
        );
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        final end = DateTime(endDate.year, endDate.month, endDate.day);
        
        return !monitoringDate.isBefore(start) && !monitoringDate.isAfter(end);
      }).toList();
    } else {
      dataToAnalyze = _monitoringList;
    }

    final ppmValues = dataToAnalyze.map((m) => m.nilaiPpm ?? 0.0).where((val) => val > 0).toList();
    final phValues = dataToAnalyze.map((m) => m.tingkatPh ?? 0.0).where((val) => val > 0).toList();
    final tempValues = dataToAnalyze.map((m) => m.suhuAir ?? 0.0).where((val) => val > 0).toList();

    if (dataToAnalyze.isEmpty) {
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

    return {
      'count': dataToAnalyze.length,
      'averagePpm': ppmValues.isNotEmpty ? ppmValues.fold<double>(0, (sum, val) => sum + val) / ppmValues.length : 0.0,
      'averagePh': phValues.isNotEmpty ? phValues.fold<double>(0, (sum, val) => sum + val) / phValues.length : 0.0,
      'averageTemp': tempValues.isNotEmpty ? tempValues.fold<double>(0, (sum, val) => sum + val) / tempValues.length : 0.0,
      'minPpm': ppmValues.isNotEmpty ? ppmValues.reduce((a, b) => a < b ? a : b) : 0.0,
      'maxPpm': ppmValues.isNotEmpty ? ppmValues.reduce((a, b) => a > b ? a : b) : 0.0,
      'minPh': phValues.isNotEmpty ? phValues.reduce((a, b) => a < b ? a : b) : 0.0,
      'maxPh': phValues.isNotEmpty ? phValues.reduce((a, b) => a > b ? a : b) : 0.0,
      'minTemp': tempValues.isNotEmpty ? tempValues.reduce((a, b) => a < b ? a : b) : 0.0,
      'maxTemp': tempValues.isNotEmpty ? tempValues.reduce((a, b) => a > b ? a : b) : 0.0,
      'totalWaterAdded': dataToAnalyze.fold<double>(0, (sum, m) => sum + (m.airDitambah ?? 0)),
      'totalNutrientAdded': dataToAnalyze.fold<double>(0, (sum, m) => sum + (m.nutrisiDitambah ?? 0)),
    };
  }

  // Get tandon name by ID
  String getTandonName(String tandonId) {
    try {
      final tandon = _tandonList.firstWhere(
        (t) => t.id == tandonId,
        orElse: () => TandonAirModel(
          id: '',
          kodeTandon: '',
          namaTandon: 'Tandon Tidak Ditemukan',
          kapasitas: 0,
          lokasi: '',
          aktif: false,
        ),
      );
      return tandon.namaTandon ?? 'Tandon Tidak Ditemukan';
    } catch (e) {
      return 'Tandon Tidak Diketahui';
    }
  }

  // Get monitoring by ID
  MonitoringNutrisiModel? getMonitoringById(String id) {
    try {
      return _monitoringList.firstWhere((monitoring) => monitoring.id == id);
    } catch (e) {
      return null;
    }
  }

  // Refresh data
  Future<void> refresh() async {
    _setLoading(true);
    try {
      await Future.wait([
        loadMonitoring(),
        loadTandonList(),
      ]);
    } catch (e) {
      _setError('Gagal memuat ulang data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Real-time monitoring stream
  Stream<List<MonitoringNutrisiModel>> getMonitoringStream() {
    return _monitoringService.getMonitoringStream();
  }

  // Listen to real-time updates
  void startListening() {
    getMonitoringStream().listen(
      (monitoringList) {
        _monitoringList = monitoringList;
        _applyFilters();
      },
      onError: (error) {
        _setError('Error dalam real-time update: $error');
      },
    );
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear all data
  void clearData() {
    _monitoringList.clear();
    _filteredMonitoringList.clear();
    _tandonList.clear();
    _searchQuery = '';
    _selectedTandonId = null;
    _startDate = null;
    _endDate = null;
    _error = null;
    _isLoading = false;
    _isInitialized = false;
    notifyListeners();
  }

  @override
  void dispose() {
    clearData();
    super.dispose();
  }
}