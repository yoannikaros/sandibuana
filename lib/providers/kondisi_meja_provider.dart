import 'package:flutter/material.dart';
import '../models/kondisi_meja_model.dart';
import '../services/kondisi_meja_service.dart';
import 'auth_provider.dart';

class KondisiMejaProvider with ChangeNotifier {
  final KondisiMejaService _kondisiMejaService = KondisiMejaService();
  final AuthProvider _authProvider;
  
  List<KondisiMejaModel> _kondisiMejaList = [];
  bool _isLoading = false;
  String? _error;
  
  KondisiMejaProvider(this._authProvider);
  
  // Getters
  List<KondisiMejaModel> get kondisiMejaList => _kondisiMejaList;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Get kondisi meja by kondisi
  List<KondisiMejaModel> getKondisiMejaByKondisi(String kondisi) {
    return _kondisiMejaList
        .where((meja) => meja.kondisi == kondisi)
        .toList();
  }
  
  // Get meja yang siap panen
  List<KondisiMejaModel> get mejaSiapPanen {
    return _kondisiMejaList
        .where((meja) => meja.siapPanen)
        .toList();
  }
  
  // Get meja kosong
  List<KondisiMejaModel> get mejaKosong {
    return getKondisiMejaByKondisi('kosong');
  }
  
  // Get meja sedang tanam
  List<KondisiMejaModel> get mejaSedangTanam {
    return getKondisiMejaByKondisi('tanam');
  }
  
  // Get meja sedang panen
  List<KondisiMejaModel> get mejaSedangPanen {
    return getKondisiMejaByKondisi('panen');
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
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Load all kondisi meja
  Future<void> loadKondisiMeja() async {
    try {
      _setLoading(true);
      _error = null;
      
      final kondisiMejaData = await _kondisiMejaService.getAllKondisiMeja();
      _kondisiMejaList = kondisiMejaData;
      notifyListeners();
    } catch (e) {
      _setError('Gagal memuat data kondisi meja: ${e.toString()}');
      _kondisiMejaList = [];
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  // Search kondisi meja
  Future<void> searchKondisiMeja(String keyword) async {
    try {
      _setLoading(true);
      _error = null;
      
      if (keyword.isEmpty) {
        await loadKondisiMeja();
      } else {
        _kondisiMejaList = await _kondisiMejaService.cariKondisiMeja(keyword);
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  // Add new kondisi meja
  Future<bool> tambahKondisiMeja({
    required String namaMeja,
    required String kondisi,
    DateTime? tanggalTanam,
    String? jenisSayur,
    int? targetHariPanen,
    String? catatan,
  }) async {
    try {
      _setLoading(true);
      _error = null;
      
      final now = DateTime.now();
      final kondisiMeja = KondisiMejaModel(
        id: '', // Will be set by Firestore
        namaMeja: namaMeja,
        kondisi: kondisi,
        tanggalTanam: tanggalTanam,
        jenisSayur: jenisSayur,
        targetHariPanen: targetHariPanen,
        catatan: catatan,
        aktif: true,
        dibuatPada: now,
        diubahPada: now,
      );
      
      await _kondisiMejaService.tambahKondisiMeja(kondisiMeja);
      await loadKondisiMeja(); // Refresh list
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Update kondisi meja
  Future<bool> updateKondisiMeja({
    required String id,
    required String namaMeja,
    required String kondisi,
    DateTime? tanggalTanam,
    String? jenisSayur,
    int? targetHariPanen,
    String? catatan,
  }) async {
    try {
      _setLoading(true);
      _error = null;
      
      // Find existing kondisi meja
      final existingKondisiMeja = _kondisiMejaList.firstWhere(
        (meja) => meja.id == id,
      );
      
      final updatedKondisiMeja = existingKondisiMeja.copyWith(
        namaMeja: namaMeja,
        kondisi: kondisi,
        tanggalTanam: tanggalTanam,
        jenisSayur: jenisSayur,
        targetHariPanen: targetHariPanen,
        catatan: catatan,
        diubahPada: DateTime.now(),
      );
      
      await _kondisiMejaService.updateKondisiMeja(id, updatedKondisiMeja);
      await loadKondisiMeja(); // Refresh list
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Update status kondisi meja saja
  Future<bool> updateStatusKondisiMeja({
    required String id,
    String? kondisi,
    DateTime? tanggalTanam,
    String? jenisSayur,
    int? targetHariPanen,
    String? catatan,
  }) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _kondisiMejaService.updateKondisiMejaStatus(
        id,
        kondisi: kondisi,
        tanggalTanam: tanggalTanam,
        jenisSayur: jenisSayur,
        targetHariPanen: targetHariPanen,
        catatan: catatan,
      );
      
      await loadKondisiMeja(); // Refresh list
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Delete kondisi meja
  Future<bool> hapusKondisiMeja(String id) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _kondisiMejaService.hapusKondisiMeja(id);
      await loadKondisiMeja(); // Refresh list
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Get kondisi meja by ID
  Future<KondisiMejaModel?> getKondisiMejaById(String id) async {
    try {
      return await _kondisiMejaService.getKondisiMejaById(id);
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }
  
  // Refresh data
  Future<void> refresh() async {
    await loadKondisiMeja();
  }
  
  // Get statistics
  Map<String, int> getStatistik() {
    final total = _kondisiMejaList.length;
    final kosong = mejaKosong.length;
    final tanam = mejaSedangTanam.length;
    final panen = mejaSedangPanen.length;
    final siapPanen = mejaSiapPanen.length;
    
    return {
      'total': total,
      'kosong': kosong,
      'tanam': tanam,
      'panen': panen,
      'siap_panen': siapPanen,
    };
  }
}