import 'package:flutter/foundation.dart';
import '../models/penanaman_sayur_model.dart';
import '../models/catatan_pembenihan_model.dart';
import '../services/penanaman_sayur_service.dart';
import '../services/benih_service.dart';

class PenanamanSayurProvider with ChangeNotifier {
  final PenanamanSayurService _penanamanSayurService = PenanamanSayurService();
  final BenihService _benihService = BenihService();

  // State variables
  List<PenanamanSayurModel> _penanamanSayurList = [];
  List<CatatanPembenihanModel> _catatanPembenihanList = [];
  List<String> _availableJenisSayur = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _summaryStatistics;
  Map<String, double>? _tingkatKeberhasilanByJenis;
  Map<String, int>? _totalProduksiByPeriode;

  // Getters
  List<PenanamanSayurModel> get penanamanSayurList => _penanamanSayurList;
  List<CatatanPembenihanModel> get catatanPembenihanList => _catatanPembenihanList;
  List<String> get availableJenisSayur => _availableJenisSayur;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get error => _errorMessage; // Alias for compatibility
  Map<String, dynamic>? get summaryStatistics => _summaryStatistics;
  Map<String, double>? get tingkatKeberhasilanByJenis => _tingkatKeberhasilanByJenis;
  Map<String, int>? get totalProduksiByPeriode => _totalProduksiByPeriode;

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Public method to clear error
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // ========================================
  // PENANAMAN SAYUR OPERATIONS
  // ========================================

  // Load all penanaman sayur
  Future<void> loadAllPenanamanSayur() async {
    try {
      _setLoading(true);
      _clearError();
      _penanamanSayurList = await _penanamanSayurService.getAllPenanamanSayur();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load penanaman sayur by tanggal range
  Future<void> loadPenanamanSayurByTanggal(DateTime startDate, DateTime endDate) async {
    try {
      _setLoading(true);
      _clearError();
      _penanamanSayurList = await _penanamanSayurService.getPenanamanSayurByTanggal(startDate, endDate);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load penanaman sayur by jenis
  Future<void> loadPenanamanSayurByJenis(String jenisSayur) async {
    try {
      _setLoading(true);
      _clearError();
      _penanamanSayurList = await _penanamanSayurService.getPenanamanSayurByJenis(jenisSayur);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load penanaman sayur by tahap
  Future<void> loadPenanamanSayurByTahap(String tahapPertumbuhan) async {
    try {
      _setLoading(true);
      _clearError();
      _penanamanSayurList = await _penanamanSayurService.getPenanamanSayurByTahap(tahapPertumbuhan);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load penanaman sayur by lokasi
  Future<void> loadPenanamanSayurByLokasi(String lokasi) async {
    try {
      _setLoading(true);
      _clearError();
      _penanamanSayurList = await _penanamanSayurService.getPenanamanSayurByLokasi(lokasi);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load catatan pembenihan for dropdown
  Future<void> loadCatatanPembenihanForDropdown() async {
    try {
      _clearError();
      _catatanPembenihanList = await _benihService.getAllCatatanPembenihan();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Load available jenis sayur for dropdown
  Future<void> loadAvailableJenisSayur() async {
    try {
      _clearError();
      _availableJenisSayur = await _penanamanSayurService.getAvailableJenisSayur();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Tambah penanaman sayur baru
  Future<bool> tambahPenanamanSayur({
    String? idPembenihan,
    required DateTime tanggalTanam,
    required String jenisSayur,
    required int jumlahDitanam,
    double? harga,
    String? lokasi,
    String? catatan,
    required String dicatatOleh,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final penanamanSayur = PenanamanSayurModel(
        idPenanaman: '', // Will be set by Firestore
        idPembenihan: idPembenihan,
        tanggalTanam: tanggalTanam,
        jenisSayur: jenisSayur,
        jumlahDitanam: jumlahDitanam,
        lokasi: lokasi,
        tahapPertumbuhan: 'semai',
        jumlahDipanen: 0,
        jumlahGagal: 0,
        tingkatKeberhasilan: 0.0,
        harga: harga,
        catatan: catatan,
        dicatatOleh: dicatatOleh,
        dicatatPada: DateTime.now(),
        diubahPada: DateTime.now(),
      );

      await _penanamanSayurService.tambahPenanamanSayur(penanamanSayur);
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update penanaman sayur
  Future<bool> updatePenanamanSayur(String id, Map<String, dynamic> data) async {
    try {
      _setLoading(true);
      _clearError();
      await _penanamanSayurService.updatePenanamanSayur(id, data);
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update tahap pertumbuhan
  Future<bool> updateTahapPertumbuhan(String id, String tahapBaru) async {
    try {
      _setLoading(true);
      _clearError();
      await _penanamanSayurService.updateTahapPertumbuhan(id, tahapBaru);
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update data panen
  Future<bool> updateDataPanen(String id, {
    required DateTime tanggalPanen,
    required int jumlahDipanen,
    int? jumlahGagal,
    String? alasanGagal,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      await _penanamanSayurService.updateDataPanen(
        id,
        tanggalPanen: tanggalPanen,
        jumlahDipanen: jumlahDipanen,
        jumlahGagal: jumlahGagal,
        alasanGagal: alasanGagal,
      );
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Hapus penanaman sayur
  Future<bool> hapusPenanamanSayur(String id) async {
    try {
      _setLoading(true);
      _clearError();
      await _penanamanSayurService.hapusPenanamanSayur(id);
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ========================================
  // STATISTICS & REPORTS
  // ========================================

  // Load tingkat keberhasilan by jenis
  Future<void> loadTingkatKeberhasilanByJenis() async {
    try {
      _clearError();
      _tingkatKeberhasilanByJenis = await _penanamanSayurService.getTingkatKeberhasilanByJenis();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Load total produksi by periode
  Future<void> loadTotalProduksiByPeriode(DateTime startDate, DateTime endDate) async {
    try {
      _clearError();
      _totalProduksiByPeriode = await _penanamanSayurService.getTotalProduksiByPeriode(startDate, endDate);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Load summary statistics
  Future<void> loadSummaryStatistics() async {
    try {
      _clearError();
      _summaryStatistics = await _penanamanSayurService.getSummaryStatistics();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ========================================
  // SEARCH & FILTER METHODS
  // ========================================

  // Search penanaman sayur
  List<PenanamanSayurModel> searchPenanamanSayur(String query) {
    if (query.isEmpty) {
      return _penanamanSayurList;
    }

    final lowerQuery = query.toLowerCase();
    return _penanamanSayurList.where((penanaman) {
      return penanaman.jenisSayur.toLowerCase().contains(lowerQuery) ||
             (penanaman.lokasi?.toLowerCase().contains(lowerQuery) ?? false) ||
             penanaman.tahapPertumbuhan.toLowerCase().contains(lowerQuery) ||
             (penanaman.catatan?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  // Filter by tahap pertumbuhan
  List<PenanamanSayurModel> filterByTahapPertumbuhan(String? tahap) {
    if (tahap == null || tahap.isEmpty || tahap == 'Semua') {
      return _penanamanSayurList;
    }
    return _penanamanSayurList.where((penanaman) => penanaman.tahapPertumbuhan == tahap).toList();
  }

  // Filter by jenis sayur
  List<PenanamanSayurModel> filterByJenisSayur(String? jenis) {
    if (jenis == null || jenis.isEmpty || jenis == 'Semua') {
      return _penanamanSayurList;
    }
    return _penanamanSayurList.where((penanaman) => penanaman.jenisSayur == jenis).toList();
  }

  // Get unique jenis sayur for filter dropdown
  List<String> getUniqueJenisSayur() {
    final Set<String> uniqueJenis = _penanamanSayurList.map((penanaman) => penanaman.jenisSayur).toSet();
    return ['Semua', ...uniqueJenis.toList()..sort()];
  }

  // Get unique lokasi for filter dropdown
  List<String> getUniqueLokasi() {
    final Set<String> uniqueLokasi = _penanamanSayurList
        .where((penanaman) => penanaman.lokasi != null && penanaman.lokasi!.isNotEmpty)
        .map((penanaman) => penanaman.lokasi!)
        .toSet();
    return ['Semua', ...uniqueLokasi.toList()..sort()];
  }

  // Get tahap pertumbuhan options
  List<String> getTahapPertumbuhanOptions() {
    return ['Semua', 'semai', 'vegetatif', 'siap_panen', 'panen', 'gagal'];
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

  // Get catatan pembenihan name by ID
  String getCatatanPembenihanName(String? idPembenihan) {
    if (idPembenihan == null || idPembenihan.isEmpty) {
      return 'Tidak terkait';
    }
    
    try {
      final catatan = _catatanPembenihanList.firstWhere(
        (catatan) => catatan.idPembenihan == idPembenihan,
      );
      return 'Batch: ${catatan.kodeBatch ?? 'N/A'} - ${catatan.tanggalSemai.day}/${catatan.tanggalSemai.month}/${catatan.tanggalSemai.year}';
    } catch (e) {
      return 'Batch tidak ditemukan';
    }
  }

  // Get tahap pertumbuhan display name
  String getTahapPertumbuhanDisplayName(String tahap) {
    switch (tahap) {
      case 'semai':
        return 'Semai';
      case 'vegetatif':
        return 'Vegetatif';
      case 'siap_panen':
        return 'Siap Panen';
      case 'panen':
        return 'Panen';
      case 'gagal':
        return 'Gagal';
      default:
        return tahap;
    }
  }

  // Get color for tahap pertumbuhan
  String getTahapPertumbuhanColor(String tahap) {
    switch (tahap) {
      case 'semai':
        return 'blue';
      case 'vegetatif':
        return 'green';
      case 'siap_panen':
        return 'orange';
      case 'panen':
        return 'purple';
      case 'gagal':
        return 'red';
      default:
        return 'grey';
    }
  }

  // Get latest price for jenis sayur
  double? getLatestPriceByJenisSayur(String jenisSayur) {
    try {
      // Filter penanaman sayur by jenis and sort by tanggal_tanam descending
      final filteredList = _penanamanSayurList
          .where((penanaman) => 
              penanaman.jenisSayur.toLowerCase() == jenisSayur.toLowerCase() &&
              penanaman.harga != null && 
              penanaman.harga! > 0)
          .toList();
      
      if (filteredList.isEmpty) return null;
      
      // Sort by tanggal_tanam descending to get the latest
      filteredList.sort((a, b) => b.tanggalTanam.compareTo(a.tanggalTanam));
      
      return filteredList.first.harga;
    } catch (e) {
      return null;
    }
  }

  // Get average price for jenis sayur
  double? getAveragePriceByJenisSayur(String jenisSayur) {
    try {
      final filteredList = _penanamanSayurList
          .where((penanaman) => 
              penanaman.jenisSayur.toLowerCase() == jenisSayur.toLowerCase() &&
              penanaman.harga != null && 
              penanaman.harga! > 0)
          .toList();
      
      if (filteredList.isEmpty) return null;
      
      final totalHarga = filteredList.fold<double>(0, (sum, penanaman) => sum + penanaman.harga!);
      return totalHarga / filteredList.length;
    } catch (e) {
      return null;
    }
  }

  // Refresh data
  Future<void> refreshData() async {
    await loadAllPenanamanSayur();
    await loadCatatanPembenihanForDropdown();
  }

  // ========================================
  // INITIALIZATION
  // ========================================

  // Initialize provider
  Future<void> initialize() async {
    await refreshData();
  }
}