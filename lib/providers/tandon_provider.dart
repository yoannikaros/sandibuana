import 'package:flutter/material.dart';
import '../models/tandon_air_model.dart';
import '../models/monitoring_nutrisi_model.dart';
import '../services/tandon_service.dart';

class TandonProvider with ChangeNotifier {
  final TandonService _tandonService = TandonService();

  // ========================================
  // TANDON AIR STATE
  // ========================================
  
  List<TandonAirModel> _tandonAirList = [];
  List<TandonAirModel> _filteredTandonAirList = [];
  bool _isLoadingTandonAir = false;
  String? _tandonAirError;
  String _tandonAirSearchQuery = '';

  // Getters for tandon air
  List<TandonAirModel> get tandonAirList => _filteredTandonAirList;
  bool get isLoadingTandonAir => _isLoadingTandonAir;
  String? get tandonAirError => _tandonAirError;
  String get tandonAirSearchQuery => _tandonAirSearchQuery;

  // ========================================
  // MONITORING NUTRISI STATE
  // ========================================
  
  List<MonitoringNutrisiModel> _monitoringNutrisiList = [];
  List<MonitoringNutrisiModel> _filteredMonitoringNutrisiList = [];
  bool _isLoadingMonitoringNutrisi = false;
  String? _monitoringNutrisiError;
  String _selectedTandonId = '';
  DateTime? _startDate;
  DateTime? _endDate;

  // Getters for monitoring nutrisi
  List<MonitoringNutrisiModel> get monitoringNutrisiList => _filteredMonitoringNutrisiList;
  bool get isLoadingMonitoringNutrisi => _isLoadingMonitoringNutrisi;
  String? get monitoringNutrisiError => _monitoringNutrisiError;
  String get selectedTandonId => _selectedTandonId;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  // ========================================
  // TANDON AIR METHODS
  // ========================================

  // Load all tandon air
  Future<void> loadTandonAir() async {
    _isLoadingTandonAir = true;
    _tandonAirError = null;
    notifyListeners();

    try {
      _tandonAirList = await _tandonService.getAllTandonAir();
      _applyTandonAirFilter();
    } catch (e) {
      _tandonAirError = e.toString();
    } finally {
      _isLoadingTandonAir = false;
      notifyListeners();
    }
  }

  // Load active tandon air only
  Future<void> loadTandonAirAktif() async {
    _isLoadingTandonAir = true;
    _tandonAirError = null;
    notifyListeners();

    try {
      _tandonAirList = await _tandonService.getTandonAirAktif();
      _applyTandonAirFilter();
    } catch (e) {
      _tandonAirError = e.toString();
    } finally {
      _isLoadingTandonAir = false;
      notifyListeners();
    }
  }

  // Search tandon air
  void searchTandonAir(String query) {
    _tandonAirSearchQuery = query;
    _applyTandonAirFilter();
    notifyListeners();
  }

  // Apply filter to tandon air list
  void _applyTandonAirFilter() {
    if (_tandonAirSearchQuery.isEmpty) {
      _filteredTandonAirList = List.from(_tandonAirList);
    } else {
      final searchQuery = _tandonAirSearchQuery.toLowerCase();
      _filteredTandonAirList = _tandonAirList.where((tandon) {
        return tandon.kodeTandon.toLowerCase().contains(searchQuery) ||
               (tandon.namaTandon?.toLowerCase().contains(searchQuery) ?? false) ||
               (tandon.lokasi?.toLowerCase().contains(searchQuery) ?? false);
      }).toList();
    }
  }

  // Add new tandon air
  Future<bool> tambahTandonAir(TandonAirModel tandon) async {
    try {
      await _tandonService.tambahTandonAir(tandon);
      await loadTandonAir(); // Reload data
      return true;
    } catch (e) {
      _tandonAirError = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update tandon air
  Future<bool> updateTandonAir(TandonAirModel tandon) async {
    try {
      await _tandonService.updateTandonAir(tandon);
      await loadTandonAir(); // Reload data
      return true;
    } catch (e) {
      _tandonAirError = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete tandon air
  Future<bool> hapusTandonAir(String id) async {
    try {
      await _tandonService.hapusTandonAir(id);
      await loadTandonAir(); // Reload data
      return true;
    } catch (e) {
      _tandonAirError = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get tandon air by ID
  Future<TandonAirModel?> getTandonAirById(String id) async {
    try {
      return await _tandonService.getTandonAirById(id);
    } catch (e) {
      _tandonAirError = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Initialize default tandon air data
  Future<void> initializeDefaultTandonAir() async {
    try {
      await _tandonService.initializeDefaultTandonAir();
      await loadTandonAir();
    } catch (e) {
      _tandonAirError = e.toString();
      notifyListeners();
    }
  }

  // ========================================
  // MONITORING NUTRISI METHODS
  // ========================================

  // Load all monitoring nutrisi
  Future<void> loadMonitoringNutrisi() async {
    _isLoadingMonitoringNutrisi = true;
    _monitoringNutrisiError = null;
    notifyListeners();

    try {
      _monitoringNutrisiList = await _tandonService.getAllMonitoringNutrisi();
      _applyMonitoringNutrisiFilter();
    } catch (e) {
      _monitoringNutrisiError = e.toString();
    } finally {
      _isLoadingMonitoringNutrisi = false;
      notifyListeners();
    }
  }

  // Load monitoring nutrisi by date range
  Future<void> loadMonitoringNutrisiByTanggal(DateTime startDate, DateTime endDate) async {
    _isLoadingMonitoringNutrisi = true;
    _monitoringNutrisiError = null;
    _startDate = startDate;
    _endDate = endDate;
    notifyListeners();

    try {
      _monitoringNutrisiList = await _tandonService.getMonitoringNutrisiByTanggal(startDate, endDate);
      _applyMonitoringNutrisiFilter();
    } catch (e) {
      _monitoringNutrisiError = e.toString();
    } finally {
      _isLoadingMonitoringNutrisi = false;
      notifyListeners();
    }
  }

  // Load monitoring nutrisi by tandon
  Future<void> loadMonitoringNutrisiByTandon(String idTandon) async {
    _isLoadingMonitoringNutrisi = true;
    _monitoringNutrisiError = null;
    _selectedTandonId = idTandon;
    notifyListeners();

    try {
      _monitoringNutrisiList = await _tandonService.getMonitoringNutrisiByTandon(idTandon);
      _applyMonitoringNutrisiFilter();
    } catch (e) {
      _monitoringNutrisiError = e.toString();
    } finally {
      _isLoadingMonitoringNutrisi = false;
      notifyListeners();
    }
  }

  // Search monitoring nutrisi
  void searchMonitoringNutrisi(String query) {
    // For now, we'll just reload the data
    // In a real implementation, you might want to add search functionality
    loadMonitoringNutrisi();
  }

  // Filter monitoring nutrisi
  void filterMonitoringNutrisi({String? idTandon, DateTime? tanggal}) {
    if (idTandon != null) _selectedTandonId = idTandon;
    if (tanggal != null) {
      _startDate = tanggal;
      _endDate = tanggal;
    }
    
    _applyMonitoringNutrisiFilter();
    notifyListeners();
  }

  // Apply filter to monitoring nutrisi list
  void _applyMonitoringNutrisiFilter() {
    _filteredMonitoringNutrisiList = List.from(_monitoringNutrisiList);
    
    // Filter by tandon - MonitoringNutrisiModel doesn't have idTandon property
    // This filter is not applicable for this model
    // if (_selectedTandonId.isNotEmpty) {
    //   _filteredMonitoringNutrisiList = _filteredMonitoringNutrisiList
    //       .where((monitoring) => monitoring.idTandon == _selectedTandonId)
    //       .toList();
    // }
    
    // Filter by date range
    if (_startDate != null && _endDate != null) {
      _filteredMonitoringNutrisiList = _filteredMonitoringNutrisiList
          .where((monitoring) {
        final tanggal = monitoring.tanggalMonitoring;
        return tanggal.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
               tanggal.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    }
  }

  // Clear monitoring nutrisi filters
  void clearMonitoringNutrisiFilters() {
    _selectedTandonId = '';
    _startDate = null;
    _endDate = null;
    _applyMonitoringNutrisiFilter();
    notifyListeners();
  }

  // Add new monitoring nutrisi
  Future<bool> tambahMonitoringNutrisi(MonitoringNutrisiModel monitoring) async {
    try {
      await _tandonService.tambahMonitoringNutrisi(monitoring);
      await loadMonitoringNutrisi(); // Reload data
      return true;
    } catch (e) {
      _monitoringNutrisiError = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update monitoring nutrisi
  Future<bool> updateMonitoringNutrisi(MonitoringNutrisiModel monitoring) async {
    try {
      await _tandonService.updateMonitoringNutrisi(monitoring);
      await loadMonitoringNutrisi(); // Reload data
      return true;
    } catch (e) {
      _monitoringNutrisiError = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete monitoring nutrisi
  Future<bool> hapusMonitoringNutrisi(String id) async {
    try {
      await _tandonService.hapusMonitoringNutrisi(id);
      await loadMonitoringNutrisi(); // Reload data
      return true;
    } catch (e) {
      _monitoringNutrisiError = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get monitoring nutrisi by ID
  Future<MonitoringNutrisiModel?> getMonitoringNutrisiById(String id) async {
    try {
      return await _tandonService.getMonitoringNutrisiById(id);
    } catch (e) {
      _monitoringNutrisiError = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

  // Clear all errors
  void clearErrors() {
    _tandonAirError = null;
    _monitoringNutrisiError = null;
    notifyListeners();
  }

  // Get tandon air name by ID
  String getTandonAirName(String id) {
    final tandon = _tandonAirList.firstWhere(
      (t) => t.id == id,
      orElse: () => TandonAirModel(id: '', kodeTandon: 'Unknown'),
    );
    return tandon.namaTandon ?? tandon.kodeTandon;
  }

  // Get tandon name by ID (alias for getTandonAirName)
  String getTandonName(String id) {
    return getTandonAirName(id);
  }

  // Get tandon air kode by ID
  String getTandonAirKode(String id) {
    final tandon = _tandonAirList.firstWhere(
      (t) => t.id == id,
      orElse: () => TandonAirModel(id: '', kodeTandon: 'Unknown'),
    );
    return tandon.kodeTandon;
  }
}