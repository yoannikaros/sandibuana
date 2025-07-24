import 'package:flutter/material.dart';
import '../models/pengeluaran_harian_model.dart';
import '../services/pengeluaran_service.dart';

class PengeluaranProvider with ChangeNotifier {
  final PengeluaranService _pengeluaranService = PengeluaranService();
  
  // State variables
  List<PengeluaranHarianModel> _pengeluaranList = [];
  List<PengeluaranHarianModel> _filteredPengeluaranList = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _selectedKategoriId;
  DateTime? _startDate;
  DateTime? _endDate;

  // Getters
  List<PengeluaranHarianModel> get pengeluaranList => _filteredPengeluaranList;
  List<String> get kategoriList => _pengeluaranService.getAllKategori();
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get selectedKategoriId => _selectedKategoriId;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  // Initialize data
  Future<void> initialize() async {
    await loadPengeluaran();
  }



  // ========================================
  // PENGELUARAN METHODS
  // ========================================

  // Load all expenses
  Future<void> loadPengeluaran() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pengeluaranList = await _pengeluaranService.getAllPengeluaran();
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load expenses by date range
  Future<void> loadPengeluaranByTanggal(DateTime startDate, DateTime endDate) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pengeluaranList = await _pengeluaranService.getPengeluaranByTanggal(startDate, endDate);
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load expenses by category
  Future<void> loadPengeluaranByKategori(String kategori) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pengeluaranList = await _pengeluaranService.getPengeluaranByKategori(kategori);
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add new expense
  Future<bool> tambahPengeluaran(PengeluaranHarianModel pengeluaran) async {
    try {
      await _pengeluaranService.tambahPengeluaran(pengeluaran);
      await loadPengeluaran();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update expense
  Future<bool> updatePengeluaran(PengeluaranHarianModel pengeluaran) async {
    try {
      await _pengeluaranService.updatePengeluaran(pengeluaran.id, pengeluaran);
      await loadPengeluaran();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete expense
  Future<bool> hapusPengeluaran(String id) async {
    try {
      await _pengeluaranService.hapusPengeluaran(id);
      await loadPengeluaran();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ========================================
  // FILTER AND SEARCH METHODS
  // ========================================

  // Search expenses
  void searchPengeluaran(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Filter by category
  void filterByKategori(String? kategoriId) {
    _selectedKategoriId = kategoriId;
    _applyFilters();
    notifyListeners();
  }

  // Filter by date range
  void filterByDateRange(DateTime? startDate, DateTime? endDate) {
    _startDate = startDate;
    _endDate = endDate;
    _applyFilters();
    notifyListeners();
  }

  // Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedKategoriId = null;
    _startDate = null;
    _endDate = null;
    _applyFilters();
    notifyListeners();
  }

  // Apply all filters
  void _applyFilters() {
    _filteredPengeluaranList = _pengeluaranList.where((pengeluaran) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final keterangan = pengeluaran.keterangan.toLowerCase();
        final pemasok = pengeluaran.pemasok?.toLowerCase() ?? '';
        final searchQuery = _searchQuery.toLowerCase();
        if (!keterangan.contains(searchQuery) && !pemasok.contains(searchQuery)) {
          return false;
        }
      }

      // Category filter
      if (_selectedKategoriId != null && pengeluaran.kategori != _selectedKategoriId) {
        return false;
      }

      // Date range filter
      if (_startDate != null && pengeluaran.tanggalPengeluaran.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && pengeluaran.tanggalPengeluaran.isAfter(_endDate!)) {
        return false;
      }

      return true;
    }).toList();
  }

  // ========================================
  // STATISTICS METHODS
  // ========================================

  // Get total expenses
  double get totalPengeluaran {
    return _filteredPengeluaranList.fold(0.0, (sum, item) => sum + item.jumlah);
  }

  // Get total expenses by category
  double getTotalByKategori(String kategori) {
    return _filteredPengeluaranList
        .where((pengeluaran) => pengeluaran.kategori == kategori)
        .fold(0.0, (sum, item) => sum + item.jumlah);
  }

  // Get expenses count
  int get totalCount => _filteredPengeluaranList.length;

  // Get expenses by month
  Map<String, double> getPengeluaranByMonth() {
    final Map<String, double> monthlyData = {};
    
    for (final pengeluaran in _filteredPengeluaranList) {
      final monthKey = '${pengeluaran.tanggalPengeluaran.year}-${pengeluaran.tanggalPengeluaran.month.toString().padLeft(2, '0')}';
      monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + pengeluaran.jumlah;
    }
    
    return monthlyData;
  }

  // Get expenses by category summary
  Map<String, double> getPengeluaranByKategoriSummary() {
    final Map<String, double> categoryData = {};
    
    for (final pengeluaran in _filteredPengeluaranList) {
      final kategoriName = pengeluaran.kategori;
      categoryData[kategoriName] = (categoryData[kategoriName] ?? 0) + pengeluaran.jumlah;
    }
    
    return categoryData;
  }



  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    await initialize();
  }
}