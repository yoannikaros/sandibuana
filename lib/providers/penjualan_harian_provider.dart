import 'package:flutter/material.dart';
import '../models/penjualan_harian_model.dart';
import '../models/pelanggan_model.dart';
import '../services/penjualan_harian_service.dart';
import '../services/pelanggan_service.dart';

class PenjualanHarianProvider with ChangeNotifier {
  final PenjualanHarianService _penjualanService = PenjualanHarianService();
  final PelangganService _pelangganService = PelangganService();
  
  // State variables
  List<PenjualanHarianModel> _penjualanList = [];
  List<PelangganModel> _pelangganList = [];
  List<PenjualanHarianModel> _filteredPenjualanList = [];
  bool _isLoading = false;
  bool _isLoadingPelanggan = false;
  String? _error;
  String _searchQuery = '';
  String? _selectedPelangganId;
  String? _selectedJenisSayur;
  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;

  // Getters
  List<PenjualanHarianModel> get penjualanList => _filteredPenjualanList;
  List<PelangganModel> get pelangganList => _pelangganList;
  bool get isLoading => _isLoading;
  bool get isLoadingPelanggan => _isLoadingPelanggan;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get selectedPelangganId => _selectedPelangganId;
  String? get selectedJenisSayur => _selectedJenisSayur;
  String? get selectedStatus => _selectedStatus;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  // Initialize data
  Future<void> initialize() async {
    await loadPelanggan();
    await loadPenjualan();
  }

  // ========================================
  // PELANGGAN METHODS
  // ========================================

  // Load all customers
  Future<void> loadPelanggan() async {
    _isLoadingPelanggan = true;
    _error = null;
    notifyListeners();

    try {
      _pelangganList = await _pelangganService.getAllPelanggan();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingPelanggan = false;
      notifyListeners();
    }
  }

  // Get customer by ID
  PelangganModel? getPelangganById(String id) {
    try {
      return _pelangganList.firstWhere((pelanggan) => pelanggan.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get customer name by ID
  String getPelangganName(String id) {
    final pelanggan = getPelangganById(id);
    return pelanggan?.namaPelanggan ?? 'Pelanggan tidak ditemukan';
  }

  // ========================================
  // PENJUALAN METHODS
  // ========================================

  // Load all sales
  Future<void> loadPenjualan() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _penjualanList = await _penjualanService.getAllPenjualan();
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load sales by date range
  Future<void> loadPenjualanByTanggal(DateTime startDate, DateTime endDate) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _penjualanList = await _penjualanService.getPenjualanByDateRange(startDate, endDate);
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load sales by customer
  Future<void> loadPenjualanByPelanggan(String idPelanggan) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _penjualanList = await _penjualanService.getPenjualanByPelanggan(idPelanggan);
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add new sale
  Future<bool> tambahPenjualan({
    required DateTime tanggalJual,
    required String idPelanggan,
    required String jenisSayur,
    required double jumlah,
    String? satuan,
    double? hargaPerSatuan,
    required double totalHarga,
    String statusKirim = 'pending',
    String? catatan,
    required String dicatatOleh,
  }) async {
    try {
      await _penjualanService.tambahPenjualan(
        tanggalJual: tanggalJual,
        idPelanggan: idPelanggan,
        jenisSayur: jenisSayur,
        jumlah: jumlah,
        satuan: satuan,
        hargaPerSatuan: hargaPerSatuan,
        totalHarga: totalHarga,
        statusKirim: statusKirim,
        catatan: catatan,
        dicatatOleh: dicatatOleh,
      );
      await loadPenjualan();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update sale
  Future<bool> updatePenjualan(
    String idPenjualan,
    Map<String, dynamic> updateData,
  ) async {
    try {
      await _penjualanService.updatePenjualan(idPenjualan, updateData);
      await loadPenjualan();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update delivery status
  Future<bool> updateStatusKirim(String idPenjualan, String statusBaru) async {
    try {
      await _penjualanService.updateStatusKirim(idPenjualan, statusBaru);
      await loadPenjualan();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete sale
  Future<bool> hapusPenjualan(String id) async {
    try {
      await _penjualanService.hapusPenjualan(id);
      await loadPenjualan();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ========================================
  // FILTER & SEARCH METHODS
  // ========================================

  // Apply all filters
  void _applyFilters() {
    _filteredPenjualanList = _penjualanList.where((penjualan) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final jenisSayur = penjualan.jenisSayur.toLowerCase();
        final catatan = penjualan.catatan?.toLowerCase() ?? '';
        final pelangganName = getPelangganName(penjualan.idPelanggan).toLowerCase();
        
        if (!jenisSayur.contains(query) && 
            !catatan.contains(query) && 
            !pelangganName.contains(query)) {
          return false;
        }
      }

      // Customer filter
      if (_selectedPelangganId != null && _selectedPelangganId!.isNotEmpty) {
        if (penjualan.idPelanggan != _selectedPelangganId) {
          return false;
        }
      }

      // Vegetable type filter
      if (_selectedJenisSayur != null && _selectedJenisSayur!.isNotEmpty) {
        if (penjualan.jenisSayur != _selectedJenisSayur) {
          return false;
        }
      }

      // Status filter
      if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
        if (penjualan.statusKirim != _selectedStatus) {
          return false;
        }
      }

      // Date range filter
      if (_startDate != null && _endDate != null) {
        if (penjualan.tanggalJual.isBefore(_startDate!) || 
            penjualan.tanggalJual.isAfter(_endDate!)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Filter by customer
  void filterByPelanggan(String? idPelanggan) {
    _selectedPelangganId = idPelanggan;
    _applyFilters();
    notifyListeners();
  }

  // Filter by vegetable type
  void filterByJenisSayur(String? jenisSayur) {
    _selectedJenisSayur = jenisSayur;
    _applyFilters();
    notifyListeners();
  }

  // Filter by status
  void filterByStatus(String? status) {
    _selectedStatus = status;
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
    _selectedPelangganId = null;
    _selectedJenisSayur = null;
    _selectedStatus = null;
    _startDate = null;
    _endDate = null;
    _applyFilters();
    notifyListeners();
  }

  // ========================================
  // STATISTICS & ANALYTICS
  // ========================================

  // Get today's sales
  List<PenjualanHarianModel> getTodaySales() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return _penjualanList.where((penjualan) {
      return penjualan.tanggalJual.isAfter(startOfDay) && 
             penjualan.tanggalJual.isBefore(endOfDay) &&
             penjualan.statusKirim != 'batal';
    }).toList();
  }

  // Get this month's sales
  List<PenjualanHarianModel> getThisMonthSales() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    return _penjualanList.where((penjualan) {
      return penjualan.tanggalJual.isAfter(startOfMonth) && 
             penjualan.tanggalJual.isBefore(endOfMonth) &&
             penjualan.statusKirim != 'batal';
    }).toList();
  }

  // Get pending deliveries
  List<PenjualanHarianModel> getPendingDeliveries() {
    return _penjualanList.where((penjualan) => penjualan.statusKirim == 'pending').toList();
  }

  // Get total revenue for period
  double getTotalRevenue(List<PenjualanHarianModel> salesList) {
    return salesList
        .where((penjualan) => penjualan.statusKirim != 'batal')
        .fold(0.0, (sum, penjualan) => sum + penjualan.totalHarga);
  }

  // Get total transactions for period
  int getTotalTransactions(List<PenjualanHarianModel> salesList) {
    return salesList.where((penjualan) => penjualan.statusKirim != 'batal').length;
  }

  // Get average transaction value
  double getAverageTransactionValue(List<PenjualanHarianModel> salesList) {
    final validSales = salesList.where((penjualan) => penjualan.statusKirim != 'batal').toList();
    if (validSales.isEmpty) return 0.0;
    
    final totalRevenue = getTotalRevenue(validSales);
    return totalRevenue / validSales.length;
  }

  // Get top selling products
  Map<String, double> getTopSellingProducts(List<PenjualanHarianModel> salesList) {
    final Map<String, double> productSales = {};
    
    for (final penjualan in salesList) {
      if (penjualan.statusKirim != 'batal') {
        productSales[penjualan.jenisSayur] = 
            (productSales[penjualan.jenisSayur] ?? 0) + penjualan.totalHarga;
      }
    }
    
    // Sort by revenue
    final sortedEntries = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sortedEntries);
  }

  // Get top customers
  Map<String, double> getTopCustomers(List<PenjualanHarianModel> salesList) {
    final Map<String, double> customerSales = {};
    
    for (final penjualan in salesList) {
      if (penjualan.statusKirim != 'batal') {
        customerSales[penjualan.idPelanggan] = 
            (customerSales[penjualan.idPelanggan] ?? 0) + penjualan.totalHarga;
      }
    }
    
    // Sort by revenue
    final sortedEntries = customerSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sortedEntries);
  }

  // Get unique vegetable types
  List<String> getUniqueVegetableTypes() {
    final Set<String> uniqueTypes = {};
    for (final penjualan in _penjualanList) {
      uniqueTypes.add(penjualan.jenisSayur);
    }
    return uniqueTypes.toList()..sort();
  }

  // Get available status options
  List<String> getStatusOptions() {
    return ['pending', 'terkirim', 'batal'];
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}