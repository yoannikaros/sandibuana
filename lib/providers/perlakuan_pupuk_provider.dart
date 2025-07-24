import 'package:flutter/material.dart';
import '../models/perlakuan_pupuk_model.dart';
import '../services/perlakuan_pupuk_service.dart';

class PerlakuanPupukProvider with ChangeNotifier {
  final PerlakuanPupukService _perlakuanPupukService = PerlakuanPupukService();
  
  List<PerlakuanPupukModel> _perlakuanPupukList = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  bool _showActiveOnly = true;

  // Getters
  List<PerlakuanPupukModel> get perlakuanPupukList {
    List<PerlakuanPupukModel> filteredList = _perlakuanPupukList;
    
    // Filter berdasarkan status aktif
    if (_showActiveOnly) {
      filteredList = filteredList.where((perlakuan) => perlakuan.isAktif).toList();
    }
    
    // Filter berdasarkan pencarian
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredList = filteredList.where((perlakuan) {
        return perlakuan.kodePerlakuan.toLowerCase().contains(query) ||
               perlakuan.namaPerlakuan.toLowerCase().contains(query) ||
               (perlakuan.deskripsi?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    return filteredList;
  }
  
  List<PerlakuanPupukModel> get activePerlakuanPupukList {
    return _perlakuanPupukList.where((perlakuan) => perlakuan.isAktif).toList();
  }
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  bool get showActiveOnly => _showActiveOnly;
  
  // Dropdown options
  List<String> get dropdownKodeOptions {
    return activePerlakuanPupukList.map((p) => p.kodePerlakuan).toList();
  }
  
  List<String> get dropdownNamaOptions {
    return activePerlakuanPupukList.map((p) => p.namaPerlakuan).toList();
  }
  
  List<String> get dropdownDisplayOptions {
    return activePerlakuanPupukList.map((p) => p.displayName).toList();
  }

  // Load perlakuan pupuk
  Future<void> loadPerlakuanPupuk() async {
    _setLoading(true);
    try {
      _perlakuanPupukList = await _perlakuanPupukService.getAllPerlakuanPupuk();
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Add perlakuan pupuk
  Future<bool> addPerlakuanPupuk({
    required String kodePerlakuan,
    required String namaPerlakuan,
    String? deskripsi,
    required String dibuatOleh,
  }) async {
    try {
      await _perlakuanPupukService.addPerlakuanPupuk(
        kodePerlakuan: kodePerlakuan,
        namaPerlakuan: namaPerlakuan,
        deskripsi: deskripsi,
        dibuatOleh: dibuatOleh,
      );
      await loadPerlakuanPupuk();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Update perlakuan pupuk
  Future<bool> updatePerlakuanPupuk(
    String id,
    Map<String, dynamic> updateData,
  ) async {
    try {
      await _perlakuanPupukService.updatePerlakuanPupuk(id, updateData);
      await loadPerlakuanPupuk();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Soft delete perlakuan pupuk
  Future<bool> softDeletePerlakuanPupuk(String id, String diupdateOleh) async {
    try {
      await _perlakuanPupukService.softDeletePerlakuanPupuk(id, diupdateOleh);
      await loadPerlakuanPupuk();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Restore perlakuan pupuk
  Future<bool> restorePerlakuanPupuk(String id, String diupdateOleh) async {
    try {
      await _perlakuanPupukService.restorePerlakuanPupuk(id, diupdateOleh);
      await loadPerlakuanPupuk();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Hard delete perlakuan pupuk
  Future<bool> deletePerlakuanPupuk(String id) async {
    try {
      await _perlakuanPupukService.deletePerlakuanPupuk(id);
      await loadPerlakuanPupuk();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Search perlakuan pupuk
  void searchPerlakuanPupuk(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Toggle show active only
  void toggleShowActiveOnly() {
    _showActiveOnly = !_showActiveOnly;
    notifyListeners();
  }

  // Set show active only
  void setShowActiveOnly(bool value) {
    _showActiveOnly = value;
    notifyListeners();
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  // Get perlakuan pupuk by ID
  PerlakuanPupukModel? getPerlakuanPupukById(String id) {
    try {
      return _perlakuanPupukList.firstWhere((perlakuan) => perlakuan.idPerlakuan == id);
    } catch (e) {
      return null;
    }
  }

  // Get perlakuan pupuk by kode
  PerlakuanPupukModel? getPerlakuanPupukByKode(String kode) {
    try {
      return _perlakuanPupukList.firstWhere((perlakuan) => perlakuan.kodePerlakuan == kode);
    } catch (e) {
      return null;
    }
  }

  // Check if kode exists
  Future<bool> isKodeExists(String kode, {String? excludeId}) async {
    return await _perlakuanPupukService.isKodeExists(kode, excludeId: excludeId);
  }

  // Get count by status
  Future<Map<String, int>> getCountByStatus() async {
    return await _perlakuanPupukService.getCountByStatus();
  }

  // Refresh data
  Future<void> refresh() async {
    await loadPerlakuanPupuk();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}