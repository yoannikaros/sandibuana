import 'package:flutter/material.dart';
import '../models/tipe_pupuk_model.dart';
import '../services/tipe_pupuk_service.dart';

class TipePupukProvider with ChangeNotifier {
  final TipePupukService _tipePupukService = TipePupukService();
  
  List<TipePupukModel> _tipePupukList = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<TipePupukModel> get tipePupukList => _tipePupukList;
  List<TipePupukModel> get tipePupukAktif => _tipePupukList.where((tipe) => tipe.aktif).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Get dropdown options
  List<String> get tipePupukOptions {
    return tipePupukAktif.map((tipe) => tipe.kode).toList();
  }
  
  // Get display options for dropdown
  List<String> get tipePupukDisplayOptions {
    return tipePupukAktif.map((tipe) => tipe.nama).toList();
  }
  
  // Load all tipe pupuk
  Future<void> loadTipePupuk() async {
    try {
      _setLoading(true);
      _error = null;
      
      _tipePupukList = await _tipePupukService.getAllTipePupuk();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  // Load only active tipe pupuk
  Future<void> loadTipePupukAktif() async {
    try {
      _setLoading(true);
      _error = null;
      
      _tipePupukList = await _tipePupukService.getTipePupukAktif();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  // Add new tipe pupuk
  Future<bool> tambahTipePupuk(TipePupukModel tipePupuk) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _tipePupukService.tambahTipePupuk(tipePupuk);
      await loadTipePupuk(); // Refresh list
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Update tipe pupuk
  Future<bool> updateTipePupuk(int id, TipePupukModel tipePupuk) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _tipePupukService.updateTipePupuk(id, tipePupuk);
      await loadTipePupuk(); // Refresh list
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Delete tipe pupuk (soft delete)
  Future<bool> hapusTipePupuk(int id) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _tipePupukService.hapusTipePupuk(id);
      await loadTipePupuk(); // Refresh list
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Restore tipe pupuk
  Future<bool> restoreTipePupuk(int id) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _tipePupukService.restoreTipePupuk(id);
      await loadTipePupuk(); // Refresh list
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Delete tipe pupuk permanently
  Future<bool> hapusTipePupukPermanen(int id) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _tipePupukService.hapusTipePupukPermanen(id);
      await loadTipePupuk(); // Refresh list
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Search tipe pupuk
  Future<void> cariTipePupuk(String keyword) async {
    try {
      _setLoading(true);
      _error = null;
      
      if (keyword.isEmpty) {
        await loadTipePupuk();
      } else {
        _tipePupukList = await _tipePupukService.cariTipePupuk(keyword);
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  // Get tipe pupuk by ID
  Future<TipePupukModel?> getTipePupukById(int id) async {
    try {
      return await _tipePupukService.getTipePupukById(id);
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }
  
  // Get tipe pupuk name by code
  String getTipePupukName(String kode) {
    final tipe = _tipePupukList.firstWhere(
      (t) => t.kode == kode,
      orElse: () => TipePupukModel(
        nama: kode,
        kode: kode,
        dibuatPada: DateTime.now(),
      ),
    );
    return tipe.nama;
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Clear all data
  void clearData() {
    _tipePupukList.clear();
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