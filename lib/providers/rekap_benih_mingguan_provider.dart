import 'package:flutter/material.dart';
import '../models/rekap_benih_mingguan_model.dart';
import '../services/rekap_benih_mingguan_service.dart';
import 'auth_provider.dart';

class RekapBenihMingguanProvider extends ChangeNotifier {
  final RekapBenihMingguanService _service = RekapBenihMingguanService();
  final AuthProvider _authProvider;

  RekapBenihMingguanProvider(this._authProvider);

  // State variables
  List<RekapBenihMingguanModel> _rekapList = [];
  List<RekapBenihMingguanModel> _filteredList = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Filter variables
  String _searchQuery = '';
  String? _selectedJenisBenih;
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Statistics
  Map<String, dynamic> _statistics = {};
  
  // Dropdown options
  List<String> _jenisBenihOptions = [];

  // Getters
  List<RekapBenihMingguanModel> get rekapList => _filteredList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get error => _errorMessage; // Alias for compatibility
  String get searchQuery => _searchQuery;
  String? get selectedJenisBenih => _selectedJenisBenih;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  Map<String, dynamic> get statistics => _statistics;
  List<String> get jenisBenihOptions => _jenisBenihOptions;

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Public method to clear error
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Load all rekap benih mingguan
  Future<void> loadRekapBenihMingguan() async {
    _setLoading(true);
    try {
      _rekapList = await _service.getAllRekapBenihMingguan();
      _updateJenisBenihOptions();
      _applyFilters();
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Add new rekap benih mingguan
  Future<bool> addRekapBenihMingguan(RekapBenihMingguanModel rekap) async {
    try {
      final newRekap = rekap.copyWith(
        dicatatOleh: _authProvider.currentUser?.idPengguna ?? '',
        dicatatPada: DateTime.now(),
      );
      
      final id = await _service.addRekapBenihMingguan(newRekap);
      final addedRekap = newRekap.copyWith(idRekap: id);
      
      _rekapList.insert(0, addedRekap);
      _updateJenisBenihOptions();
      _applyFilters();
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Update rekap benih mingguan
  Future<bool> updateRekapBenihMingguan(String id, RekapBenihMingguanModel rekap) async {
    try {
      await _service.updateRekapBenihMingguan(id, rekap);
      
      final index = _rekapList.indexWhere((r) => r.idRekap == id);
      if (index != -1) {
        _rekapList[index] = rekap.copyWith(idRekap: id);
        _updateJenisBenihOptions();
        _applyFilters();
      }
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Delete rekap benih mingguan
  Future<bool> deleteRekapBenihMingguan(String id) async {
    try {
      await _service.deleteRekapBenihMingguan(id);
      _rekapList.removeWhere((r) => r.idRekap == id);
      _updateJenisBenihOptions();
      _applyFilters();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Get rekap benih mingguan by ID
  RekapBenihMingguanModel? getRekapBenihMingguanById(String id) {
    try {
      return _rekapList.firstWhere((r) => r.idRekap == id);
    } catch (e) {
      return null;
    }
  }

  // Search functionality
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  // Filter by jenis benih
  void setSelectedJenisBenih(String? jenisBenih) {
    _selectedJenisBenih = jenisBenih;
    _applyFilters();
  }

  // Filter by date range
  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    _applyFilters();
  }

  // Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedJenisBenih = null;
    _startDate = null;
    _endDate = null;
    _applyFilters();
  }

  // Apply filters to the list
  void _applyFilters() {
    _filteredList = _rekapList.where((rekap) {
      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!rekap.jenisBenih.toLowerCase().contains(query) &&
            !(rekap.catatan?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }

      // Jenis benih filter
      if (_selectedJenisBenih != null && rekap.jenisBenih != _selectedJenisBenih) {
        return false;
      }

      // Date range filter
      if (_startDate != null && rekap.tanggalMulai.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && rekap.tanggalMulai.isAfter(_endDate!)) {
        return false;
      }

      return true;
    }).toList();

    notifyListeners();
  }

  // Update jenis benih options from current data
  void _updateJenisBenihOptions() {
    final Set<String> uniqueJenis = _rekapList.map((r) => r.jenisBenih).toSet();
    _jenisBenihOptions = uniqueJenis.toList()..sort();
  }

  // Load statistics
  Future<void> loadStatistics() async {
    try {
      _statistics = await _service.getStatistikRekapBenihMingguan();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Load statistics by period
  Future<void> loadStatisticsByPeriod(DateTime startDate, DateTime endDate) async {
    try {
      _statistics = await _service.getStatistikRekapBenihMingguanByPeriode(startDate, endDate);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Get rekap this week
  Future<void> loadRekapThisWeek() async {
    _setLoading(true);
    try {
      _rekapList = await _service.getRekapBenihMingguanThisWeek();
      _updateJenisBenihOptions();
      _applyFilters();
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Get rekap this month
  Future<void> loadRekapThisMonth() async {
    _setLoading(true);
    try {
      _rekapList = await _service.getRekapBenihMingguanThisMonth();
      _updateJenisBenihOptions();
      _applyFilters();
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Get total nampan by jenis benih
  int getTotalNampanByJenis(String jenisBenih) {
    return _filteredList
        .where((rekap) => rekap.jenisBenih == jenisBenih)
        .fold<int>(0, (sum, rekap) => sum + rekap.jumlahNampan);
  }

  // Get total nampan all
  int getTotalNampan() {
    return _filteredList.fold<int>(0, (sum, rekap) => sum + rekap.jumlahNampan);
  }

  // Get average nampan per rekap
  double getAverageNampanPerRekap() {
    if (_filteredList.isEmpty) return 0.0;
    return getTotalNampan() / _filteredList.length;
  }

  // Get most popular jenis benih
  String getMostPopularJenisBenih() {
    if (_filteredList.isEmpty) return '';
    
    final Map<String, int> jenisCount = {};
    for (final rekap in _filteredList) {
      jenisCount[rekap.jenisBenih] = (jenisCount[rekap.jenisBenih] ?? 0) + rekap.jumlahNampan;
    }
    
    String mostPopular = '';
    int maxCount = 0;
    jenisCount.forEach((jenis, count) {
      if (count > maxCount) {
        maxCount = count;
        mostPopular = jenis;
      }
    });
    
    return mostPopular;
  }

  // Get distribution by jenis benih
  Map<String, int> getDistributionByJenisBenih() {
    final Map<String, int> distribution = {};
    for (final rekap in _filteredList) {
      distribution[rekap.jenisBenih] = (distribution[rekap.jenisBenih] ?? 0) + rekap.jumlahNampan;
    }
    return distribution;
  }

  // Initialize with default data
  Future<void> initializeWithDefaultData() async {
    _setLoading(true);
    try {
      // Create default data for current week
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      
      final defaultData = [
        RekapBenihMingguanModel(
          tanggalMulai: startOfWeek,
          tanggalSelesai: endOfWeek,
          jenisBenih: 'Selada',
          jumlahNampan: 30,
          catatan: 'Rekap benih mingguan selada',
          dicatatOleh: _authProvider.currentUser?.idPengguna ?? 'system',
          dicatatPada: DateTime.now(),
        ),
        RekapBenihMingguanModel(
          tanggalMulai: startOfWeek,
          tanggalSelesai: endOfWeek,
          jenisBenih: 'Romaine',
          jumlahNampan: 15,
          catatan: 'Rekap benih mingguan romaine',
          dicatatOleh: _authProvider.currentUser?.idPengguna ?? 'system',
          dicatatPada: DateTime.now(),
        ),
      ];
      
      for (final rekap in defaultData) {
        await addRekapBenihMingguan(rekap);
      }
      
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
}