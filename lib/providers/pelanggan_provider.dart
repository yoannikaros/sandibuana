import 'package:flutter/material.dart';
import '../models/pelanggan_model.dart';
import '../services/pelanggan_service.dart';

class PelangganProvider with ChangeNotifier {
  final PelangganService _pelangganService = PelangganService();
  
  List<PelangganModel> _pelangganList = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<PelangganModel> get pelangganList => _pelangganList;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Get active pelanggan only
  List<PelangganModel> get pelangganAktif => 
      _pelangganList.where((pelanggan) => pelanggan.aktif).toList();
  
  // Get pelanggan by jenis
  List<PelangganModel> getPelangganByJenis(String jenis) {
    return _pelangganList
        .where((pelanggan) => pelanggan.aktif && pelanggan.jenisPelanggan == jenis)
        .toList();
  }
  
  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  // Load all pelanggan
  Future<void> loadPelanggan() async {
    try {
      _setLoading(true);
      _error = null;
      
      _pelangganList = await _pelangganService.getAllPelanggan();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  // Load active pelanggan only
  Future<void> loadPelangganAktif() async {
    try {
      _setLoading(true);
      _error = null;
      
      _pelangganList = await _pelangganService.getPelangganAktif();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  // Search pelanggan
  Future<void> searchPelanggan(String keyword) async {
    try {
      _setLoading(true);
      _error = null;
      
      _pelangganList = await _pelangganService.cariPelanggan(keyword);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  // Add new pelanggan
  Future<bool> tambahPelanggan(PelangganModel pelanggan) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _pelangganService.tambahPelanggan(pelanggan);
      await loadPelanggan(); // Refresh list
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Update pelanggan
  Future<bool> updatePelanggan(String id, PelangganModel pelanggan) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _pelangganService.updatePelanggan(id, pelanggan);
      await loadPelanggan(); // Refresh list
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Delete pelanggan (soft delete)
  Future<bool> hapusPelanggan(String id) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _pelangganService.hapusPelanggan(id);
      await loadPelanggan(); // Refresh list
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Get pelanggan by ID
  Future<PelangganModel?> getPelangganById(String id) async {
    try {
      return await _pelangganService.getPelangganById(id);
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }
  
  // Filter pelanggan by jenis
  Future<void> filterPelangganByJenis(String jenis) async {
    try {
      _setLoading(true);
      _error = null;
      
      _pelangganList = await _pelangganService.getPelangganByJenis(jenis);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  // Clear filters and load all active pelanggan
  Future<void> clearFilters() async {
    await loadPelangganAktif();
  }
  
  // Initialize default data
  Future<void> initializeData() async {
    try {
      _setLoading(true);
      _error = null;
      
      await _pelangganService.initializePelangganData();
      await loadPelangganAktif();
    } catch (e) {
      _setError('Gagal inisialisasi data: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  // Stream untuk real-time updates
  Stream<List<PelangganModel>> get pelangganStream {
    return _pelangganService.streamPelangganAktif();
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Get pelanggan name by ID (helper method)
  String getPelangganName(String id) {
    try {
      final pelanggan = _pelangganList.firstWhere((p) => p.id == id);
      return pelanggan.namaPelanggan;
    } catch (e) {
      return 'Pelanggan tidak ditemukan';
    }
  }
  
  // Get statistics
  Map<String, int> getStatistics() {
    final total = _pelangganList.length;
    final aktif = _pelangganList.where((p) => p.aktif).length;
    final restoran = _pelangganList.where((p) => p.aktif && p.jenisPelanggan == 'restoran').length;
    final hotel = _pelangganList.where((p) => p.aktif && p.jenisPelanggan == 'hotel').length;
    final individu = _pelangganList.where((p) => p.aktif && p.jenisPelanggan == 'individu').length;
    
    return {
      'total': total,
      'aktif': aktif,
      'restoran': restoran,
      'hotel': hotel,
      'individu': individu,
    };
  }
}