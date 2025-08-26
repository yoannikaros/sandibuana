import 'package:flutter/material.dart';
import '../models/jenis_pupuk_model.dart';
import '../models/penggunaan_pupuk_model.dart';
import '../services/pupuk_service.dart';
import 'tipe_pupuk_provider.dart';

class PupukProvider with ChangeNotifier {
  final PupukService _pupukService = PupukService();
  TipePupukProvider? _tipePupukProvider;
  
  List<JenisPupukModel> _jenisPupukList = [];
  List<PenggunaanPupukModel> _penggunaanPupukList = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<JenisPupukModel> get jenisPupukList => _jenisPupukList;
  List<PenggunaanPupukModel> get penggunaanPupukList => _penggunaanPupukList;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Get active jenis pupuk only
  List<JenisPupukModel> get jenisPupukAktif => 
      _jenisPupukList.where((pupuk) => pupuk.aktif).toList();
  
  // ========================================
  // JENIS PUPUK METHODS
  // ========================================
  
  // Load all jenis pupuk
  Future<void> loadJenisPupuk() async {
    try {
      _setLoading(true);
      _error = null;
      
      _jenisPupukList = await _pupukService.getAllJenisPupuk();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
  
  // Load active jenis pupuk only
  Future<void> loadJenisPupukAktif() async {
    try {
      _setLoading(true);
      _error = null;
      
      _jenisPupukList = await _pupukService.getJenisPupukAktif();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
  
  // Search jenis pupuk
  Future<void> searchJenisPupuk(String keyword) async {
    try {
      _setLoading(true);
      _error = null;
      
      _jenisPupukList = await _pupukService.cariJenisPupuk(keyword);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
  
  // Add new jenis pupuk
  Future<bool> tambahJenisPupuk(JenisPupukModel pupuk) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _pupukService.tambahJenisPupuk(pupuk);
      await loadJenisPupukAktif(); // Refresh list
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Update jenis pupuk
  Future<bool> updateJenisPupuk(String id, JenisPupukModel pupuk) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _pupukService.updateJenisPupuk(id, pupuk);
      await loadJenisPupukAktif(); // Refresh list
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Delete jenis pupuk (soft delete)
  Future<bool> hapusJenisPupuk(String id) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _pupukService.hapusJenisPupuk(id);
      await loadJenisPupukAktif(); // Refresh list
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Get jenis pupuk by ID
  Future<JenisPupukModel?> getJenisPupukById(String id) async {
    try {
      return await _pupukService.getJenisPupukById(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ========================================
  // STOK PUPUK METHODS
  // ========================================

  // Update stok pupuk
  Future<bool> updateStokPupuk(String id, double stokBaru) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _pupukService.updateStokPupuk(id, stokBaru);
      await loadJenisPupukAktif(); // Refresh list
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Tambah stok pupuk
  Future<bool> tambahStokPupuk(String id, double jumlahTambah) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _pupukService.tambahStokPupuk(id, jumlahTambah);
      await loadJenisPupukAktif(); // Refresh list
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Kurangi stok pupuk
  Future<bool> kurangiStokPupuk(String id, double jumlahKurang) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _pupukService.kurangiStokPupuk(id, jumlahKurang);
      await loadJenisPupukAktif(); // Refresh list
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get pupuk dengan stok rendah
  Future<List<JenisPupukModel>> getPupukStokRendah({double batasMinimum = 10.0}) async {
    try {
      return await _pupukService.getPupukStokRendah(batasMinimum: batasMinimum);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }
  
  // ========================================
  // PENGGUNAAN PUPUK METHODS
  // ========================================
  
  // Load all penggunaan pupuk
  Future<void> loadPenggunaanPupuk() async {
    try {
      _setLoading(true);
      _error = null;
      
      _penggunaanPupukList = await _pupukService.getAllPenggunaanPupuk();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
  
  // Add penggunaan pupuk
  Future<bool> tambahPenggunaanPupuk(PenggunaanPupukModel penggunaan) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _pupukService.tambahPenggunaanPupuk(penggunaan);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Load penggunaan pupuk by date range
  Future<void> loadPenggunaanPupukByTanggal(DateTime startDate, DateTime endDate) async {
    try {
      _setLoading(true);
      _error = null;
      
      _penggunaanPupukList = await _pupukService.getPenggunaanPupukByTanggal(startDate, endDate);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
  
  // Load penggunaan pupuk by jenis pupuk
  Future<void> loadPenggunaanPupukByJenis(String idPupuk) async {
    try {
      _setLoading(true);
      _error = null;
      
      _penggunaanPupukList = await _pupukService.getPenggunaanPupukByJenis(idPupuk);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
  
  // Update penggunaan pupuk
  Future<bool> updatePenggunaanPupuk(String id, PenggunaanPupukModel penggunaan) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _pupukService.updatePenggunaanPupuk(id, penggunaan);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Delete penggunaan pupuk
  Future<bool> hapusPenggunaanPupuk(String id) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _pupukService.hapusPenggunaanPupuk(id);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // ========================================
  // UTILITY METHODS
  // ========================================
  
  // Initialize default data
  Future<void> initializeData() async {
    try {
      await _pupukService.initializeJenisPupukData();
      await loadJenisPupukAktif();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Clear all data
  void clearData() {
    _jenisPupukList.clear();
    _penggunaanPupukList.clear();
    _error = null;
    notifyListeners();
  }
  
  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // Set tipe pupuk provider
  void setTipePupukProvider(TipePupukProvider tipePupukProvider) {
    _tipePupukProvider = tipePupukProvider;
  }
  
  // Get pupuk types for dropdown from SQLite
  List<String> get tipePupukList {
    return _tipePupukProvider?.tipePupukOptions ?? ['makro', 'mikro', 'organik', 'kimia'];
  }
  
  // Get pupuk types display names for dropdown
  List<String> get tipePupukDisplayList {
    return _tipePupukProvider?.tipePupukDisplayOptions ?? ['Makro', 'Mikro', 'Organik', 'Kimia'];
  }
  
  // Get satuan options for penggunaan pupuk
  List<String> get satuanPupukList => ['kg', 'liter', 'gram', 'ml'];
}