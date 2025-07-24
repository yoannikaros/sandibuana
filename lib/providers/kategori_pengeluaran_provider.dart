import 'package:flutter/material.dart';
import '../models/kategori_pengeluaran_model.dart';
import '../services/kategori_pengeluaran_service.dart';
import 'auth_provider.dart';

class KategoriPengeluaranProvider extends ChangeNotifier {
  final KategoriPengeluaranService _service = KategoriPengeluaranService();
  final AuthProvider _authProvider;

  KategoriPengeluaranProvider(this._authProvider);

  // State variables
  List<KategoriPengeluaranModel> _kategoriList = [];
  List<KategoriPengeluaranModel> _filteredKategoriList = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  bool _showActiveOnly = false;
  Map<String, int> _usageStats = {};

  // Getters
  List<KategoriPengeluaranModel> get kategoriList => _filteredKategoriList;
  List<KategoriPengeluaranModel> get allKategoriList => _kategoriList;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  bool get showActiveOnly => _showActiveOnly;
  Map<String, int> get usageStats => _usageStats;

  // Get active categories only
  List<KategoriPengeluaranModel> get activeKategoriList {
    return _kategoriList.where((kategori) => kategori.aktif).toList();
  }

  // Get inactive categories only
  List<KategoriPengeluaranModel> get inactiveKategoriList {
    return _kategoriList.where((kategori) => !kategori.aktif).toList();
  }

  // Statistics
  int get totalKategori => _kategoriList.length;
  int get activeKategoriCount => activeKategoriList.length;
  int get inactiveKategoriCount => inactiveKategoriList.length;

  // Load all categories
  Future<void> loadKategori() async {
    _setLoading(true);
    _setError(null);

    try {
      _kategoriList = await _service.getAllKategori();
      _applyFilters();
      await _loadUsageStats();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load usage statistics
  Future<void> _loadUsageStats() async {
    try {
      _usageStats = await _service.getKategoriUsageStats();
    } catch (e) {
      // Don't throw error for usage stats, just log it
      debugPrint('Error loading usage stats: $e');
    }
  }

  // Add new category
  Future<bool> addKategori(KategoriPengeluaranModel kategori) async {
    _setLoading(true);
    _setError(null);

    try {
      // Validate
      final validationError = kategori.validate();
      if (validationError != null) {
        _setError(validationError);
        return false;
      }

      // Check if name already exists
      final nameExists = await _service.isKategoriNameExists(kategori.namaKategori);
      if (nameExists) {
        _setError('Nama kategori sudah ada');
        return false;
      }

      final id = await _service.addKategori(kategori);
      if (id != null) {
        final newKategori = kategori.copyWith(id: id);
        _kategoriList.add(newKategori);
        _applyFilters();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update category
  Future<bool> updateKategori(String id, KategoriPengeluaranModel kategori) async {
    _setLoading(true);
    _setError(null);

    try {
      // Validate
      final validationError = kategori.validate();
      if (validationError != null) {
        _setError(validationError);
        return false;
      }

      // Check if name already exists (excluding current category)
      final nameExists = await _service.isKategoriNameExists(
        kategori.namaKategori,
        excludeId: id,
      );
      if (nameExists) {
        _setError('Nama kategori sudah ada');
        return false;
      }

      await _service.updateKategori(id, kategori);
      
      final index = _kategoriList.indexWhere((k) => k.id == id);
      if (index != -1) {
        _kategoriList[index] = kategori.copyWith(id: id);
        _applyFilters();
      }
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete category (soft delete)
  Future<bool> deleteKategori(String id) async {
    _setLoading(true);
    _setError(null);

    try {
      // Check if category can be deleted
      final canDelete = await _service.canDeleteKategori(id);
      if (!canDelete) {
        _setError('Kategori tidak dapat dihapus karena masih digunakan');
        return false;
      }

      await _service.deleteKategori(id);
      
      final index = _kategoriList.indexWhere((k) => k.id == id);
      if (index != -1) {
        _kategoriList[index] = _kategoriList[index].copyWith(aktif: false);
        _applyFilters();
      }
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Hard delete category
  Future<bool> hardDeleteKategori(String id) async {
    _setLoading(true);
    _setError(null);

    try {
      // Check if category can be deleted
      final canDelete = await _service.canDeleteKategori(id);
      if (!canDelete) {
        _setError('Kategori tidak dapat dihapus karena masih digunakan');
        return false;
      }

      await _service.hardDeleteKategori(id);
      _kategoriList.removeWhere((k) => k.id == id);
      _applyFilters();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Activate category
  Future<bool> activateKategori(String id) async {
    final kategori = _kategoriList.firstWhere((k) => k.id == id);
    return await updateKategori(id, kategori.copyWith(aktif: true));
  }

  // Deactivate category
  Future<bool> deactivateKategori(String id) async {
    final kategori = _kategoriList.firstWhere((k) => k.id == id);
    return await updateKategori(id, kategori.copyWith(aktif: false));
  }

  // Get category by ID
  KategoriPengeluaranModel? getKategoriById(String id) {
    try {
      return _kategoriList.firstWhere((kategori) => kategori.id == id);
    } catch (e) {
      return null;
    }
  }

  // Search categories
  void searchKategori(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  // Toggle show active only
  void toggleShowActiveOnly() {
    _showActiveOnly = !_showActiveOnly;
    _applyFilters();
  }

  // Set show active only
  void setShowActiveOnly(bool value) {
    _showActiveOnly = value;
    _applyFilters();
  }

  // Apply filters
  void _applyFilters() {
    List<KategoriPengeluaranModel> filtered = List.from(_kategoriList);

    // Filter by active status
    if (_showActiveOnly) {
      filtered = filtered.where((kategori) => kategori.aktif).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final searchLower = _searchQuery.toLowerCase();
      filtered = filtered.where((kategori) {
        return kategori.namaKategori.toLowerCase().contains(searchLower) ||
               (kategori.keterangan?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    }

    _filteredKategoriList = filtered;
    notifyListeners();
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
  }

  // Clear error
  void clearError() {
    _setError(null);
  }

  // Initialize default categories
  Future<void> initializeDefaultKategori() async {
    try {
      await _service.initializeDefaultKategori();
      await loadKategori();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Get categories with usage statistics
  Future<List<Map<String, dynamic>>> getKategoriWithUsage() async {
    try {
      return await _service.getKategoriWithUsage();
    } catch (e) {
      throw Exception('Gagal mengambil kategori dengan statistik: $e');
    }
  }

  // Check if category name exists
  Future<bool> isKategoriNameExists(String namaKategori, {String? excludeId}) async {
    try {
      return await _service.isKategoriNameExists(namaKategori, excludeId: excludeId);
    } catch (e) {
      return false;
    }
  }

  // Get usage count for category
  int getUsageCount(String id) {
    return _usageStats[id] ?? 0;
  }

  // Check if category can be deleted
  Future<bool> canDeleteKategori(String id) async {
    try {
      return await _service.canDeleteKategori(id);
    } catch (e) {
      return false;
    }
  }

  // Refresh data
  Future<void> refresh() async {
    await loadKategori();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}