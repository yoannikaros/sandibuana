import 'package:flutter/material.dart';
import '../models/rekap_benih_mingguan_model.dart';
import '../models/catatan_pembenihan_model.dart';
import '../services/rekap_benih_mingguan_service.dart';
import '../services/benih_service.dart';
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
  String? _selectedIdPembenihan;
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Statistics
  Map<String, dynamic> _statistics = {};
  
  // Dropdown options
  List<CatatanPembenihanModel> _pembenihanList = [];
  final BenihService _benihService = BenihService();

  // Getters
  List<RekapBenihMingguanModel> get rekapList => _filteredList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get error => _errorMessage; // Alias for compatibility
  String get searchQuery => _searchQuery;
  String? get selectedIdPembenihan => _selectedIdPembenihan;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  Map<String, dynamic> get statistics => _statistics;
  List<CatatanPembenihanModel> get pembenihanList => _pembenihanList;

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

  // Load catatan pembenihan list
  Future<void> loadPembenihanList() async {
    try {
      _pembenihanList = await _benihService.getAllCatatanPembenihan();
      notifyListeners();
    } catch (e) {
      _setError('Gagal memuat daftar catatan pembenihan: $e');
    }
  }

  // Load all rekap benih mingguan
  Future<void> loadRekapBenihMingguan() async {
    _setLoading(true);
    try {
      _rekapList = await _service.getAllRekapBenihMingguan();
      await loadPembenihanList();
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

  // Filter by catatan pembenihan
  void setSelectedIdPembenihan(String? idPembenihan) {
    _selectedIdPembenihan = idPembenihan;
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
    _selectedIdPembenihan = null;
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
        if (!(rekap.catatan?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }

      // Catatan pembenihan filter
      if (_selectedIdPembenihan != null && rekap.idPembenihan != _selectedIdPembenihan) {
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
      await loadPembenihanList();
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
      await loadPembenihanList();
      _applyFilters();
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Get total nampan by catatan pembenihan
  int getTotalNampanByPembenihan(String idPembenihan) {
    return _filteredList
        .where((rekap) => rekap.idPembenihan == idPembenihan)
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

  // Get most popular catatan pembenihan
  String getMostPopularPembenihan() {
    if (_filteredList.isEmpty) return '';
    
    final Map<String, int> pembenihanCount = {};
    for (final rekap in _filteredList) {
      if (rekap.idPembenihan != null) {
        pembenihanCount[rekap.idPembenihan!] = (pembenihanCount[rekap.idPembenihan!] ?? 0) + rekap.jumlahNampan;
      }
    }
    
    String mostPopular = '';
    int maxCount = 0;
    pembenihanCount.forEach((idPembenihan, count) {
      if (count > maxCount) {
        maxCount = count;
        mostPopular = idPembenihan;
      }
    });
    
    return mostPopular;
  }

  // Get distribution by catatan pembenihan
  Map<String, int> getDistributionByPembenihan() {
    final Map<String, int> distribution = {};
    for (final rekap in _filteredList) {
      if (rekap.idPembenihan != null) {
        distribution[rekap.idPembenihan!] = (distribution[rekap.idPembenihan!] ?? 0) + rekap.jumlahNampan;
      }
    }
    return distribution;
  }

  // Get pembenihan name by ID
  String getPembenihanName(String? idPembenihan) {
    if (idPembenihan == null) return 'Unknown';
    try {
      final pembenihan = _pembenihanList.firstWhere(
        (p) => p.idPembenihan == idPembenihan,
      );
      return pembenihan.kodeBatch;
    } catch (e) {
      return 'Unknown';
    }
  }

  // Initialize with default data
  Future<void> initializeWithDefaultData() async {
    _setLoading(true);
    try {
      // Load pembenihan list first
      await loadPembenihanList();
      
      // Create default data for current week if pembenihan data exists
      if (_pembenihanList.isNotEmpty) {
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        
        final defaultData = [
          RekapBenihMingguanModel(
            tanggalMulai: startOfWeek,
            tanggalSelesai: endOfWeek,
            idPembenihan: _pembenihanList.first.idPembenihan,
            jumlahNampan: 30,
            catatan: 'Rekap benih mingguan default',
            dicatatOleh: _authProvider.currentUser?.idPengguna ?? 'system',
            dicatatPada: DateTime.now(),
          ),
        ];
        
        for (final rekap in defaultData) {
          await addRekapBenihMingguan(rekap);
        }
      }
      
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
}