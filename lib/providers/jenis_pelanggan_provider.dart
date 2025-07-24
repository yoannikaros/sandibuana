import 'package:flutter/material.dart';
import '../models/jenis_pelanggan_model.dart';
import '../services/jenis_pelanggan_service.dart';

class JenisPelangganProvider with ChangeNotifier {
  final JenisPelangganService _jenisPelangganService = JenisPelangganService();
  
  List<JenisPelangganModel> _jenisPelangganList = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<JenisPelangganModel> get jenisPelangganList => _jenisPelangganList;
  List<JenisPelangganModel> get jenisPelangganAktif => _jenisPelangganList.where((jenis) => jenis.aktif).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Get dropdown options
  List<String> get jenisPelangganOptions {
    return jenisPelangganAktif.map((jenis) => jenis.kode).toList();
  }
  
  // Get display options for dropdown
  List<String> get jenisPelangganDisplayOptions {
    return jenisPelangganAktif.map((jenis) => jenis.nama).toList();
  }
  
  // Load all jenis pelanggan
  Future<void> loadJenisPelanggan() async {
    try {
      _setLoading(true);
      _error = null;
      
      _jenisPelangganList = await _jenisPelangganService.getAllJenisPelanggan();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  // Load only active jenis pelanggan
  Future<void> loadJenisPelangganAktif() async {
    try {
      _setLoading(true);
      _error = null;
      
      _jenisPelangganList = await _jenisPelangganService.getJenisPelangganAktif();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  // Add new jenis pelanggan
  Future<bool> tambahJenisPelanggan(JenisPelangganModel jenisPelanggan) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _jenisPelangganService.tambahJenisPelanggan(jenisPelanggan);
      await loadJenisPelanggan(); // Refresh list
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Update jenis pelanggan
  Future<bool> updateJenisPelanggan(int id, JenisPelangganModel jenisPelanggan) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _jenisPelangganService.updateJenisPelanggan(id, jenisPelanggan);
      await loadJenisPelanggan(); // Refresh list
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Delete jenis pelanggan (soft delete)
  Future<bool> hapusJenisPelanggan(int id) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _jenisPelangganService.hapusJenisPelanggan(id);
      await loadJenisPelanggan(); // Refresh list
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Restore jenis pelanggan
  Future<bool> restoreJenisPelanggan(int id) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _jenisPelangganService.restoreJenisPelanggan(id);
      await loadJenisPelanggan(); // Refresh list
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Delete jenis pelanggan permanently
  Future<bool> hapusJenisPelangganPermanen(int id) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _jenisPelangganService.hapusJenisPelangganPermanen(id);
      await loadJenisPelanggan(); // Refresh list
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Search jenis pelanggan
  Future<void> cariJenisPelanggan(String keyword) async {
    try {
      _setLoading(true);
      _error = null;
      
      if (keyword.isEmpty) {
        await loadJenisPelanggan();
      } else {
        _jenisPelangganList = await _jenisPelangganService.cariJenisPelanggan(keyword);
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  // Get jenis pelanggan by ID
  Future<JenisPelangganModel?> getJenisPelangganById(int id) async {
    try {
      return await _jenisPelangganService.getJenisPelangganById(id);
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }
  
  // Get jenis pelanggan name by code
  String getJenisPelangganName(String kode) {
    final jenis = _jenisPelangganList.firstWhere(
      (j) => j.kode == kode,
      orElse: () => JenisPelangganModel(
        nama: kode,
        kode: kode,
        dibuatPada: DateTime.now(),
      ),
    );
    return jenis.nama;
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Clear all data
  void clearData() {
    _jenisPelangganList.clear();
    _error = null;
    notifyListeners();
  }
  
  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // Set error state
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
}