import 'package:flutter/material.dart';
import '../models/pembelian_benih_model.dart';
import '../services/pembelian_benih_service.dart';
import 'auth_provider.dart';

class PembelianBenihProvider extends ChangeNotifier {
  final PembelianBenihService _service = PembelianBenihService();
  final AuthProvider _authProvider;

  PembelianBenihProvider(this._authProvider);

  // State variables
  List<PembelianBenihModel> _pembelianList = [];
  List<PembelianBenihModel> _filteredList = [];
  bool _isLoading = false;
  String? _error;
  
  // Filter variables
  String _searchQuery = '';
  String? _selectedBenih;
  String? _selectedPemasok;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showExpiredOnly = false;
  bool _showExpiringSoonOnly = false;
  
  // Statistics
  Map<String, dynamic> _statistics = {};
  
  // Dropdown options
  List<String> _pemasokOptions = [];
  List<String> _satuanOptions = [];

  // Getters
  List<PembelianBenihModel> get pembelianList => _filteredList;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get selectedBenih => _selectedBenih;
  String? get selectedPemasok => _selectedPemasok;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  bool get showExpiredOnly => _showExpiredOnly;
  bool get showExpiringSoonOnly => _showExpiringSoonOnly;
  Map<String, dynamic> get statistics => _statistics;
  List<String> get pemasokOptions => _pemasokOptions;
  List<String> get satuanOptions => _satuanOptions;

  // Load all pembelian benih
  Future<void> loadPembelianBenih() async {
    _setLoading(true);
    try {
      _pembelianList = await _service.getAllPembelianBenih();
      _applyFilters();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Add new pembelian benih
  Future<bool> addPembelianBenih(PembelianBenihModel pembelian) async {
    try {
      final newPembelian = pembelian.copyWith(
        dicatatOleh: _authProvider.currentUser?.idPengguna ?? '',
        dicatatPada: DateTime.now(),
      );
      
      final id = await _service.addPembelianBenih(newPembelian);
      final addedPembelian = newPembelian.copyWith(idPembelian: id);
      
      _pembelianList.insert(0, addedPembelian);
      _applyFilters();
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update pembelian benih
  Future<bool> updatePembelianBenih(String id, PembelianBenihModel pembelian) async {
    try {
      await _service.updatePembelianBenih(id, pembelian);
      
      final index = _pembelianList.indexWhere((p) => p.idPembelian == id);
      if (index != -1) {
        _pembelianList[index] = pembelian.copyWith(idPembelian: id);
        _applyFilters();
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete pembelian benih
  Future<bool> deletePembelianBenih(String id) async {
    try {
      await _service.deletePembelianBenih(id);
      _pembelianList.removeWhere((p) => p.idPembelian == id);
      _applyFilters();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get pembelian benih by ID
  PembelianBenihModel? getPembelianBenihById(String id) {
    try {
      return _pembelianList.firstWhere((p) => p.idPembelian == id);
    } catch (e) {
      return null;
    }
  }

  // Search functionality
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  // Filter by benih
  void setSelectedBenih(String? benihId) {
    _selectedBenih = benihId;
    _applyFilters();
  }

  // Filter by pemasok
  void setSelectedPemasok(String? pemasok) {
    _selectedPemasok = pemasok;
    _applyFilters();
  }

  // Filter by date range
  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    _applyFilters();
  }

  // Filter expired items
  void setShowExpiredOnly(bool show) {
    _showExpiredOnly = show;
    if (show) _showExpiringSoonOnly = false;
    _applyFilters();
  }

  // Filter expiring soon items
  void setShowExpiringSoonOnly(bool show) {
    _showExpiringSoonOnly = show;
    if (show) _showExpiredOnly = false;
    _applyFilters();
  }

  // Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedBenih = null;
    _selectedPemasok = null;
    _startDate = null;
    _endDate = null;
    _showExpiredOnly = false;
    _showExpiringSoonOnly = false;
    _applyFilters();
  }

  // Apply filters to the list
  void _applyFilters() {
    _filteredList = _pembelianList.where((pembelian) {
      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!pembelian.pemasok.toLowerCase().contains(query) &&
            !(pembelian.nomorFaktur?.toLowerCase().contains(query) ?? false) &&
            !(pembelian.catatan?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }

      // Benih filter
      if (_selectedBenih != null && pembelian.idBenih != _selectedBenih) {
        return false;
      }

      // Pemasok filter
      if (_selectedPemasok != null && pembelian.pemasok != _selectedPemasok) {
        return false;
      }

      // Date range filter
      if (_startDate != null && pembelian.tanggalBeli.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && pembelian.tanggalBeli.isAfter(_endDate!)) {
        return false;
      }

      // Expired filter
      if (_showExpiredOnly && !pembelian.isExpired) {
        return false;
      }

      // Expiring soon filter
      if (_showExpiringSoonOnly && !pembelian.isExpiringSoon) {
        return false;
      }

      return true;
    }).toList();

    notifyListeners();
  }

  // Load statistics
  Future<void> loadStatistics({DateTime? startDate, DateTime? endDate}) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();
      
      _statistics = await _service.getTotalPembelianByPeriod(start, end);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load dropdown options
  Future<void> loadDropdownOptions() async {
    try {
      _pemasokOptions = await _service.getUniquePemasok();
      _satuanOptions = await _service.getUniqueSatuan();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Get pembelian by date
  Future<List<PembelianBenihModel>> getPembelianByDate(DateTime date) async {
    try {
      return await _service.getPembelianBenihByDate(date);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Get expired items
  List<PembelianBenihModel> getExpiredItems() {
    return _pembelianList.where((p) => p.isExpired).toList();
  }

  // Get expiring soon items
  List<PembelianBenihModel> getExpiringSoonItems() {
    return _pembelianList.where((p) => p.isExpiringSoon).toList();
  }

  // Get items that need attention
  List<PembelianBenihModel> getItemsNeedingAttention() {
    return _pembelianList.where((p) => p.needsAttention).toList();
  }

  // Get recent purchases (last 7 days)
  List<PembelianBenihModel> getRecentPurchases() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return _pembelianList
        .where((p) => p.tanggalBeli.isAfter(sevenDaysAgo))
        .toList();
  }

  // Get purchases this month
  List<PembelianBenihModel> getThisMonthPurchases() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    return _pembelianList
        .where((p) => 
            p.tanggalBeli.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            p.tanggalBeli.isBefore(endOfMonth.add(const Duration(days: 1))))
        .toList();
  }

  // Get total spending this month
  double getThisMonthSpending() {
    return getThisMonthPurchases()
        .fold(0.0, (sum, p) => sum + p.totalHarga);
  }

  // Get average purchase value
  double getAveragePurchaseValue() {
    if (_pembelianList.isEmpty) return 0.0;
    final total = _pembelianList.fold(0.0, (sum, p) => sum + p.totalHarga);
    return total / _pembelianList.length;
  }

  // Get most frequent supplier
  String? getMostFrequentSupplier() {
    if (_pembelianList.isEmpty) return null;
    
    final supplierCount = <String, int>{};
    for (final pembelian in _pembelianList) {
      supplierCount[pembelian.pemasok] = (supplierCount[pembelian.pemasok] ?? 0) + 1;
    }
    
    return supplierCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // Get unique benih IDs from purchases
  List<String> getUniqueBenihIds() {
    return _pembelianList.map((p) => p.idBenih).toSet().toList();
  }

  // Get unique pemasok from purchases
  List<String> getUniquePemasokFromPurchases() {
    return _pembelianList.map((p) => p.pemasok).toSet().toList();
  }

  // Refresh data
  Future<void> refresh() async {
    await loadPembelianBenih();
    await loadDropdownOptions();
    await loadStatistics();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}