import 'package:flutter/material.dart';
import '../models/rekap_pupuk_mingguan_model.dart';
import '../models/tandon_air_model.dart';
import '../models/jenis_pupuk_model.dart';
import '../services/rekap_pupuk_mingguan_service.dart';
import '../services/tandon_service.dart';
import '../services/pupuk_service.dart';
import '../providers/auth_provider.dart';

class RekapPupukMingguanProvider with ChangeNotifier {
  final RekapPupukMingguanService _rekapService = RekapPupukMingguanService();
  final TandonService _tandonService = TandonService();
  final PupukService _pupukService = PupukService();
  final AuthProvider _authProvider;

  RekapPupukMingguanProvider(this._authProvider);

  // State variables
  List<RekapPupukMingguanModel> _rekapList = [];
  List<RekapPupukMingguanModel> _filteredRekapList = [];
  List<TandonAirModel> _tandonList = [];
  List<JenisPupukModel> _pupukList = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Filter variables
  String _searchQuery = '';
  String _selectedTandonId = '';
  String _selectedPupukId = '';
  DateTime? _startDate;
  DateTime? _endDate;
  bool? _filterLeakOnly;

  // Analytics data
  Map<String, dynamic> _statistik = {};
  bool _isLoadingStatistik = false;

  // Getters
  List<RekapPupukMingguanModel> get rekapList => _filteredRekapList;
  List<TandonAirModel> get tandonList => _tandonList;
  List<JenisPupukModel> get pupukList => _pupukList;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  String get searchQuery => _searchQuery;
  String get selectedTandonId => _selectedTandonId;
  String get selectedPupukId => _selectedPupukId;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  bool? get filterLeakOnly => _filterLeakOnly;
  Map<String, dynamic> get statistik => _statistik;
  bool get isLoadingStatistik => _isLoadingStatistik;

  // Initialize provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await Future.wait([
      loadRekapPupukMingguan(),
      loadTandonList(),
      loadPupukList(),
    ]);
    
    _isInitialized = true;
  }

  // Load all rekap pupuk mingguan
  Future<void> loadRekapPupukMingguan() async {
    _setLoading(true);
    try {
      _rekapList = await _rekapService.getAllRekapPupukMingguan();
      _applyFilters();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Load tandon list
  Future<void> loadTandonList() async {
    try {
      _tandonList = await _tandonService.getAllTandonAir();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load pupuk list
  Future<void> loadPupukList() async {
    try {
      _pupukList = await _pupukService.getAllJenisPupuk();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Add new rekap
  Future<bool> tambahRekapPupukMingguan(RekapPupukMingguanModel rekap) async {
    try {
      await _rekapService.tambahRekapPupukMingguan(rekap);
      await loadRekapPupukMingguan();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update rekap
  Future<bool> updateRekapPupukMingguan(String id, RekapPupukMingguanModel rekap) async {
    try {
      await _rekapService.updateRekapPupukMingguan(id, rekap);
      await loadRekapPupukMingguan();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete rekap
  Future<bool> hapusRekapPupukMingguan(String id) async {
    try {
      await _rekapService.hapusRekapPupukMingguan(id);
      await loadRekapPupukMingguan();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get rekap by ID
  RekapPupukMingguanModel? getRekapById(String id) {
    try {
      return _rekapList.firstWhere((rekap) => rekap.id == id);
    } catch (e) {
      return null;
    }
  }

  // Search functionality
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  // Filter by tandon
  void setTandonFilter(String tandonId) {
    _selectedTandonId = tandonId;
    _applyFilters();
  }

  // Filter by pupuk
  void setPupukFilter(String pupukId) {
    _selectedPupukId = pupukId;
    _applyFilters();
  }

  // Filter by date range
  void setDateRangeFilter(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    _applyFilters();
  }

  // Filter by leak indication
  void setLeakFilter(bool? leakOnly) {
    _filterLeakOnly = leakOnly;
    _applyFilters();
  }

  // Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedTandonId = '';
    _selectedPupukId = '';
    _startDate = null;
    _endDate = null;
    _filterLeakOnly = null;
    _applyFilters();
  }

  // Apply filters
  void _applyFilters() {
    _filteredRekapList = _rekapList.where((rekap) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final tandonName = getTandonName(rekap.idTandon).toLowerCase();
        final pupukName = getPupukName(rekap.idPupuk).toLowerCase();
        final query = _searchQuery.toLowerCase();
        
        if (!tandonName.contains(query) && 
            !pupukName.contains(query) &&
            !rekap.catatan.toString().toLowerCase().contains(query)) {
          return false;
        }
      }

      // Tandon filter
      if (_selectedTandonId.isNotEmpty && rekap.idTandon != _selectedTandonId) {
        return false;
      }

      // Pupuk filter
      if (_selectedPupukId.isNotEmpty && rekap.idPupuk != _selectedPupukId) {
        return false;
      }

      // Date range filter
      if (_startDate != null && rekap.tanggalMulai.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && rekap.tanggalSelesai.isAfter(_endDate!)) {
        return false;
      }

      // Leak filter
      if (_filterLeakOnly == true && rekap.indikasiBocor != true) {
        return false;
      }
      if (_filterLeakOnly == false && rekap.indikasiBocor == true) {
        return false;
      }

      return true;
    }).toList();

    notifyListeners();
  }

  // Get tandon name by ID
  String getTandonName(String tandonId) {
    try {
      final tandon = _tandonList.firstWhere((t) => t.id == tandonId);
      return tandon.namaTandon ?? 'Tandon Tidak Ditemukan';
    } catch (e) {
      return 'Tandon Tidak Diketahui';
    }
  }

  // Get pupuk name by ID
  String getPupukName(String pupukId) {
    try {
      final pupuk = _pupukList.firstWhere((p) => p.id == pupukId);
      return pupuk.namaPupuk;
    } catch (e) {
      return 'Pupuk Tidak Diketahui';
    }
  }

  // Load statistics
  Future<void> loadStatistik() async {
    _isLoadingStatistik = true;
    notifyListeners();
    
    try {
      _statistik = await _rekapService.getStatistik();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingStatistik = false;
      notifyListeners();
    }
  }

  // Analyze leak for specific tandon
  Future<Map<String, dynamic>?> analyzeLeakForTandon(String tandonId) async {
    try {
      return await _rekapService.analyzeLeakForTandon(tandonId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Get this week's recaps
  Future<List<RekapPupukMingguanModel>> getRekapMingguIni() async {
    try {
      return await _rekapService.getRekapMingguIni();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Get recaps with leak indication
  Future<List<RekapPupukMingguanModel>> getRekapWithLeakIndication() async {
    try {
      return await _rekapService.getRekapWithLeakIndication();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Calculate expected usage
  double calculateExpectedUsage(String tandonId, String pupukId) {
    try {
      final tandon = _tandonList.firstWhere((t) => t.id == tandonId);
      final pupuk = _pupukList.firstWhere((p) => p.id == pupukId);
      
      return _rekapService.calculateExpectedUsage(
        (tandon.kapasitas ?? 1000).toDouble(), 
        pupuk.kodePupuk ?? ''
      );
    } catch (e) {
      return 0.0;
    }
  }

  // Create rekap with calculated values
  RekapPupukMingguanModel createRekapWithCalculations({
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
    required String idTandon,
    required String idPupuk,
    required double jumlahDigunakan,
    required String satuan,
    String? catatan,
  }) {
    final expectedUsage = calculateExpectedUsage(idTandon, idPupuk);
    final selisih = jumlahDigunakan - expectedUsage;
    final indikasiBocor = expectedUsage > 0 && (selisih.abs() / expectedUsage * 100) > 15;

    return RekapPupukMingguanModel(
      id: '',
      tanggalMulai: tanggalMulai,
      tanggalSelesai: tanggalSelesai,
      idTandon: idTandon,
      idPupuk: idPupuk,
      jumlahDigunakan: jumlahDigunakan,
      satuan: satuan,
      jumlahSeharusnya: expectedUsage,
      selisih: selisih,
      indikasiBocor: indikasiBocor,
      catatan: catatan,
      dicatatOleh: _authProvider.user?.idPengguna ?? '',
      dicatatPada: DateTime.now(),
    );
  }

  // Initialize with sample data
  Future<void> initializeWithSampleData() async {
    if (_rekapList.isNotEmpty) return;

    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      // Sample data for different tandons and fertilizers
      final sampleData = [
        {
          'tanggalMulai': startOfWeek,
          'tanggalSelesai': endOfWeek,
          'tandonIndex': 0, // P1
          'pupukIndex': 0, // CEF
          'jumlahDigunakan': 2.5,
          'catatan': 'Penggunaan normal minggu ini',
        },
        {
          'tanggalMulai': startOfWeek,
          'tanggalSelesai': endOfWeek,
          'tandonIndex': 1, // P2
          'pupukIndex': 1, // COKLAT
          'jumlahDigunakan': 3.2,
          'catatan': 'Sedikit lebih tinggi dari biasanya',
        },
        {
          'tanggalMulai': startOfWeek,
          'tanggalSelesai': endOfWeek,
          'tandonIndex': 2, // P3
          'pupukIndex': 0, // CEF
          'jumlahDigunakan': 4.8,
          'catatan': 'Perlu perhatian - penggunaan tinggi',
        },
      ];

      for (final data in sampleData) {
        if (_tandonList.length > (data['tandonIndex'] as int) &&
            _pupukList.length > (data['pupukIndex'] as int)) {
          
          final tandon = _tandonList[data['tandonIndex'] as int];
          final pupuk = _pupukList[data['pupukIndex'] as int];
          
          final rekap = createRekapWithCalculations(
            tanggalMulai: data['tanggalMulai'] as DateTime,
            tanggalSelesai: data['tanggalSelesai'] as DateTime,
            idTandon: tandon.id,
            idPupuk: pupuk.id,
            jumlahDigunakan: data['jumlahDigunakan'] as double,
            satuan: 'liter',
            catatan: data['catatan'] as String,
          );

          await tambahRekapPupukMingguan(rekap);
        }
      }
    } catch (e) {
      _error = 'Gagal menginisialisasi data sampel: $e';
      notifyListeners();
    }
  }

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    await loadRekapPupukMingguan();
    await loadStatistik();
  }
}