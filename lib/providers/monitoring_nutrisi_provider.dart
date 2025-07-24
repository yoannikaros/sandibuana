import 'package:flutter/foundation.dart';
import '../models/monitoring_nutrisi_model.dart';
import '../models/catatan_pembenihan_model.dart';
import '../models/penanaman_sayur_model.dart';
import '../models/tandon_air_model.dart';
import '../services/monitoring_nutrisi_service.dart';
import '../services/auth_service.dart';
import '../services/benih_service.dart';
import '../services/penanaman_sayur_service.dart';
import '../services/tandon_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

class MonitoringNutrisiProvider with ChangeNotifier {
  final MonitoringNutrisiService _monitoringService = MonitoringNutrisiService();
  final AuthService _authService = AuthService();

  // State variables
  List<MonitoringNutrisiModel> _monitoringList = [];
  List<MonitoringNutrisiModel> _filteredMonitoringList = [];
  List<CatatanPembenihanModel> _pembenihanList = [];
  List<PenanamanSayurModel> _penanamanList = [];
  List<TandonAirModel> _tandonList = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Filter variables
  String _searchQuery = '';
  String? _selectedPembenihanId;
  String? _selectedPenanamanId;
  String? _selectedTandonId;
  DateTime? _startDate;
  DateTime? _endDate;

  // Getters
  List<MonitoringNutrisiModel> get monitoringList => _filteredMonitoringList;
  List<MonitoringNutrisiModel> get filteredMonitoringList => _filteredMonitoringList;
  List<CatatanPembenihanModel> get pembenihanList => _pembenihanList;
  List<PenanamanSayurModel> get penanamanList => _penanamanList;
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
        loadPembenihanList(),
        loadPenanamanList(),
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

  // Load pembenihan list
  Future<void> loadPembenihanList() async {
    try {
      _setLoading(true);
      final benihService = BenihService();
      _pembenihanList = await benihService.getAllCatatanPembenihan();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load penanaman list
  Future<void> loadPenanamanList() async {
    try {
      _setLoading(true);
      final penanamanService = PenanamanSayurService();
      _penanamanList = await penanamanService.getAllPenanamanSayur();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load tandon list
  Future<void> loadTandonList() async {
    try {
      _setLoading(true);
      final tandonService = TandonService();
      _tandonList = await tandonService.getAllTandon();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Add new monitoring
  Future<bool> tambahMonitoring(MonitoringNutrisiModel monitoring) async {
    _setLoading(true);
    try {
      final success = await _monitoringService.addMonitoring(monitoring);
      if (success) {
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

  // Search method (alias for searchMonitoring)
  void search(String query) {
    searchMonitoring(query);
  }

  // Filter by pembenihan
  void filterByPembenihan(String? pembenihanId) {
    _selectedPembenihanId = pembenihanId;
    _selectedPenanamanId = null; // Clear penanaman filter
    _applyFilters();
  }

  // Filter by penanaman
  void filterByPenanaman(String? penanamanId) {
    _selectedPenanamanId = penanamanId;
    _selectedPembenihanId = null; // Clear pembenihan filter
    _applyFilters();
  }

  // Filter by tandon
  void filterByTandon(String? tandonId) {
    _selectedTandonId = tandonId;
    _applyFilters();
    notifyListeners();
  }

  // Filter by date range
  void filterByDate(DateTime? date) {
    _startDate = date;
    _endDate = date;
    _applyFilters();
    notifyListeners();
  }

  // Filter by date range
  void filterByDateRange(DateTime startDate, DateTime endDate) {
    _startDate = startDate;
    _endDate = endDate;
    _applyFilters();
    notifyListeners();
  }

  // Delete monitoring
  Future<bool> deleteMonitoring(String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await _monitoringService.deleteMonitoring(id);
      
      if (success) {
         _monitoringList.removeWhere((monitoring) => monitoring.id == id);
         _applyFilters();
       }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
       _error = e.toString();
       _isLoading = false;
       notifyListeners();
       return false;
     }
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
    _selectedPembenihanId = null;
    _selectedPenanamanId = null;
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
                            getPembenihanName(monitoring.idPembenihan).toLowerCase().contains(searchLower) ||
                            getPenanamanName(monitoring.idPenanaman).toLowerCase().contains(searchLower);
        if (!matchesSearch) return false;
      }

      // Pembenihan filter
      if (_selectedPembenihanId != null && monitoring.idPembenihan != _selectedPembenihanId) {
        return false;
      }

      // Penanaman filter
      if (_selectedPenanamanId != null && monitoring.idPenanaman != _selectedPenanamanId) {
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

  // Get monitoring by pembenihan
  Future<List<MonitoringNutrisiModel>> getMonitoringByPembenihan(String pembenihanId) async {
    try {
      return await _monitoringService.getMonitoringByPembenihan(pembenihanId);
    } catch (e) {
      _setError('Gagal memuat monitoring berdasarkan pembenihan: $e');
      return [];
    }
  }

  // Get monitoring by penanaman
  Future<List<MonitoringNutrisiModel>> getMonitoringByPenanaman(String penanamanId) async {
    try {
      return await _monitoringService.getMonitoringByPenanaman(penanamanId);
    } catch (e) {
      _setError('Gagal memuat monitoring berdasarkan penanaman: $e');
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

  // Get pembenihan name by ID
  String getPembenihanName(String? pembenihanId) {
    if (pembenihanId == null) return '';
    try {
      final pembenihan = _pembenihanList.firstWhere(
        (p) => p.idPembenihan == pembenihanId,
        orElse: () => CatatanPembenihanModel(
          idPembenihan: '',
          tanggalPembenihan: DateTime.now(),
          tanggalSemai: DateTime.now(),
          idBenih: '',
          jumlah: 0,
          kodeBatch: 'Tidak Ditemukan',
          status: '',
          dicatatOleh: '',
          dicatatPada: DateTime.now(),
        ),
      );
      return pembenihan.kodeBatch;
    } catch (e) {
      return 'Pembenihan Tidak Diketahui';
    }
  }

  // Get penanaman name by ID
  String getPenanamanName(String? penanamanId) {
    if (penanamanId == null) return '';
    try {
      final penanaman = _penanamanList.firstWhere(
        (p) => p.idPenanaman == penanamanId,
        orElse: () => PenanamanSayurModel(
          idPenanaman: '',
          tanggalTanam: DateTime.now(),
          jenisSayur: 'Tidak Ditemukan',
          jumlahDitanam: 0,
          dicatatOleh: '',
          dicatatPada: DateTime.now(),
          diubahPada: DateTime.now(),
        ),
      );
      return penanaman.jenisSayur;
    } catch (e) {
      return 'Penanaman Tidak Diketahui';
    }
  }

  // Get tandon name by ID
  String getTandonName(String? tandonId) {
    if (tandonId == null) return '';
    try {
      final tandon = _tandonList.firstWhere(
        (t) => t.id == tandonId,
        orElse: () => TandonAirModel(
          id: '',
          kodeTandon: 'TDN000',
          namaTandon: 'Tidak Ditemukan',
          kapasitas: 0,
        ),
      );
      return tandon.namaTandon ?? 'Tandon ${tandon.kodeTandon}';
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
        loadPembenihanList(),
        loadPenanamanList(),
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
    _pembenihanList.clear();
    _penanamanList.clear();
    _tandonList.clear();
    _searchQuery = '';
    _selectedPembenihanId = null;
    _selectedPenanamanId = null;
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