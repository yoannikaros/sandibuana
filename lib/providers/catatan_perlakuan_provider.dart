import 'package:flutter/material.dart';
import '../models/catatan_perlakuan_model.dart';
import '../services/catatan_perlakuan_service.dart';
import '../services/dropdown_service.dart';
import '../models/dropdown_option_model.dart';
import '../models/penanaman_sayur_model.dart';
import '../services/penanaman_sayur_service.dart';
import 'auth_provider.dart';

class CatatanPerlakuanProvider with ChangeNotifier {
  final CatatanPerlakuanService _service = CatatanPerlakuanService();
  final DropdownService _dropdownService = DropdownService();
  final PenanamanSayurService _penanamanSayurService = PenanamanSayurService();
  final AuthProvider _authProvider;

  CatatanPerlakuanProvider(this._authProvider);

  List<CatatanPerlakuanModel> _catatanPerlakuan = [];
  List<CatatanPerlakuanModel> _filteredCatatanPerlakuan = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedJenis = 'Semua';
  // Removed _selectedArea - no longer needed
  int? _selectedRating;
  DateTime? _selectedDate;
  DateTime? _startDate;
  DateTime? _endDate;

  // Dropdown options from SQLite
  List<DropdownOptionModel> _jenisPerlakuanOptions = [];
  // Removed _areaTanamanOptions - no longer needed
  List<DropdownOptionModel> _metodeOptions = [];
  
  // Penanaman Sayur data from Firebase
  List<PenanamanSayurModel> _penanamanSayurList = [];

  // Getters
  List<CatatanPerlakuanModel> get catatanPerlakuan => _filteredCatatanPerlakuan;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedJenis => _selectedJenis;
  // Removed selectedArea getter - no longer needed
  int? get selectedRating => _selectedRating;
  DateTime? get selectedDate => _selectedDate;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  // Dropdown options getters
  List<DropdownOptionModel> get jenisPerlakuanOptions => _jenisPerlakuanOptions;
  // Removed areaTanamanOptions getter - no longer needed
  List<DropdownOptionModel> get metodeOptions => _metodeOptions;
  
  // Penanaman Sayur getters
  List<PenanamanSayurModel> get penanamanSayurList => _penanamanSayurList;

  // Get dropdown values as strings for compatibility
  List<String> get jenisPerlakuanValues => _jenisPerlakuanOptions.map((e) => e.value).toList();
  List<String> get metodeValues => _metodeOptions.map((e) => e.value).toList();

  // Load dropdown options from SQLite
  Future<void> loadDropdownOptions() async {
    try {
      _jenisPerlakuanOptions = await _dropdownService.getOptions(DropdownCategories.jenisPerlakuan);
      // Removed areaTanamanOptions - no longer needed
      _metodeOptions = await _dropdownService.getOptions(DropdownCategories.metode);
      notifyListeners();
    } catch (e) {
      _setError('Error loading dropdown options: ${e.toString()}');
    }
  }
  
  // Load penanaman sayur data from Firebase
  Future<void> loadPenanamanSayurData() async {
    try {
      _penanamanSayurList = await _penanamanSayurService.getAllPenanamanSayur();
      notifyListeners();
    } catch (e) {
      _setError('Error loading penanaman sayur data: ${e.toString()}');
    }
  }

  // Load semua catatan perlakuan
  Future<void> loadCatatanPerlakuan() async {
    _setLoading(true);
    _setError(null);

    try {
      // Load dropdown options and penanaman sayur data first
      await loadDropdownOptions();
      await loadPenanamanSayurData();
      
      _catatanPerlakuan = await _service.getAllCatatanPerlakuan();
      _applyFilters();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load catatan perlakuan berdasarkan tanggal
  Future<void> loadCatatanPerlakuanByTanggal(DateTime tanggal) async {
    _setLoading(true);
    _setError(null);

    try {
      _catatanPerlakuan = await _service.getCatatanPerlakuanByTanggal(tanggal);
      _selectedDate = tanggal;
      _applyFilters();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load catatan perlakuan berdasarkan range tanggal
  Future<void> loadCatatanPerlakuanByDateRange(DateTime startDate, DateTime endDate) async {
    _setLoading(true);
    _setError(null);

    try {
      _catatanPerlakuan = await _service.getCatatanPerlakuanByDateRange(startDate, endDate);
      _startDate = startDate;
      _endDate = endDate;
      _applyFilters();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Tambah catatan perlakuan
  Future<bool> tambahCatatanPerlakuan({
    required DateTime tanggalPerlakuan,
    String? idJadwal,
    required String jenisPerlakuan,
    String? idPenanaman,
    String? idPembenihan,
    double? jumlahDigunakan,
    String? satuan,
    String? metode,
    String? kondisiCuaca,
    int? ratingEfektivitas,
    String? catatan,
  }) async {
    if (_authProvider.user?.idPengguna == null) {
      _setError('User tidak terautentikasi');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      await _service.tambahCatatanPerlakuan(
        tanggalPerlakuan: tanggalPerlakuan,
        idJadwal: idJadwal,
        jenisPerlakuan: jenisPerlakuan,
        idPenanaman: idPenanaman,
        idPembenihan: idPembenihan,
        jumlahDigunakan: jumlahDigunakan,
        satuan: satuan,
        metode: metode,
        kondisiCuaca: kondisiCuaca,
        ratingEfektivitas: ratingEfektivitas,
        catatan: catatan,
        dicatatOleh: _authProvider.user!.idPengguna!,
        namaUser: _authProvider.user!.namaLengkap ?? 'Unknown',
      );

      await loadCatatanPerlakuan();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update catatan perlakuan
  Future<bool> updateCatatanPerlakuan(String idPerlakuan, {
    required DateTime tanggalPerlakuan,
    required String jenisPerlakuan,
    String? idPenanaman,
    String? idPembenihan,
    required String namaUser,
    double? jumlahDigunakan,
    String? satuan,
    String? metode,
    String? kondisiCuaca,
    int? ratingEfektivitas,
    String? catatan,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      await _service.updateCatatanPerlakuan(
        idPerlakuan,
        tanggalPerlakuan: tanggalPerlakuan,
        jenisPerlakuan: jenisPerlakuan,
        idPenanaman: idPenanaman,
        idPembenihan: idPembenihan,
        namaUser: namaUser,
        jumlahDigunakan: jumlahDigunakan,
        satuan: satuan,
        metode: metode,
        kondisiCuaca: kondisiCuaca,
        ratingEfektivitas: ratingEfektivitas,
        catatan: catatan,
      );
      await loadCatatanPerlakuan();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Hapus catatan perlakuan
  Future<bool> hapusCatatanPerlakuan(String idPerlakuan) async {
    _setLoading(true);
    _setError(null);

    try {
      await _service.hapusCatatanPerlakuan(idPerlakuan);
      await loadCatatanPerlakuan();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Set filter jenis perlakuan
  void setJenisFilter(String jenis) {
    _selectedJenis = jenis;
    _applyFilters();
    notifyListeners();
  }

  // Removed setAreaFilter - no longer needed

  // Set filter rating
  void setRatingFilter(int? rating) {
    _selectedRating = rating;
    _applyFilters();
    notifyListeners();
  }

  // Clear semua filter
  void clearFilters() {
    _searchQuery = '';
    _selectedJenis = 'Semua';
    _selectedRating = null;
    _selectedDate = null;
    _startDate = null;
    _endDate = null;
    _applyFilters();
    notifyListeners();
  }

  // Apply filters
  void _applyFilters() {
    _filteredCatatanPerlakuan = _catatanPerlakuan.where((perlakuan) {
      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesSearch = perlakuan.jenisPerlakuan.toLowerCase().contains(query) ||
            (perlakuan.namaUser?.toLowerCase().contains(query) ?? false) ||
            (perlakuan.catatan?.toLowerCase().contains(query) ?? false) ||
            (perlakuan.displayRelasi.toLowerCase().contains(query));
        if (!matchesSearch) return false;
      }

      // Jenis perlakuan filter
      if (_selectedJenis != 'Semua' && perlakuan.jenisPerlakuan != _selectedJenis) {
        return false;
      }

      // Rating filter
      if (_selectedRating != null && perlakuan.ratingEfektivitas != _selectedRating) {
        return false;
      }

      return true;
    }).toList();
  }

  // Get statistik
  Future<Map<String, dynamic>> getStatistikByJenis() async {
    try {
      return await _service.getStatistikByJenis();
    } catch (e) {
      _setError(e.toString());
      return {};
    }
  }

  Future<Map<String, dynamic>> getStatistikByRelasi() async {
    try {
      return await _service.getStatistikByRelasi();
    } catch (e) {
      _setError(e.toString());
      return {};
    }
  }

  Future<Map<String, dynamic>> getStatistikBulanan(DateTime bulanTahun) async {
    try {
      return await _service.getStatistikBulanan(bulanTahun);
    } catch (e) {
      _setError(e.toString());
      return {};
    }
  }

  Future<Map<String, dynamic>> getLaporanEfektivitas() async {
    try {
      return await _service.getLaporanEfektivitas();
    } catch (e) {
      _setError(e.toString());
      return {};
    }
  }

  // Get unique values untuk filter (using SQLite data)
  List<String> getUniqueJenisPerlakuan() {
    final activeOptions = _jenisPerlakuanOptions
        .where((option) => option.isActive)
        .map((option) => option.value)
        .toList()..sort();
    return ['Semua', ...activeOptions];
  }

  // Removed getUniqueAreaTanaman - no longer needed

  List<String> getUniqueMetode() {
    final activeOptions = _metodeOptions
        .where((option) => option.isActive)
        .map((option) => option.value)
        .toList()..sort();
    return activeOptions;
  }

  List<int> getUniqueRatings() {
    final ratingSet = _catatanPerlakuan
        .where((p) => p.ratingEfektivitas != null)
        .map((p) => p.ratingEfektivitas!)
        .toSet();
    final ratingList = ratingSet.toList()..sort();
    return ratingList;
  }

  // Get catatan perlakuan berdasarkan ID
  CatatanPerlakuanModel? getCatatanPerlakuanById(String idPerlakuan) {
    try {
      return _catatanPerlakuan.firstWhere((p) => p.idPerlakuan == idPerlakuan);
    } catch (e) {
      return null;
    }
  }

  // Get catatan perlakuan terbaru
  List<CatatanPerlakuanModel> getCatatanPerlakuanTerbaru({int limit = 5}) {
    final sortedList = List<CatatanPerlakuanModel>.from(_catatanPerlakuan)
      ..sort((a, b) => b.dicatatPada.compareTo(a.dicatatPada));
    return sortedList.take(limit).toList();
  }

  // Get catatan perlakuan dengan rating tinggi
  List<CatatanPerlakuanModel> getCatatanPerlakuanRatingTinggi({int minRating = 4}) {
    return _catatanPerlakuan
        .where((p) => p.ratingEfektivitas != null && p.ratingEfektivitas! >= minRating)
        .toList();
  }

  // Get catatan perlakuan minggu ini
  List<CatatanPerlakuanModel> getCatatanPerlakuanMingguIni() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return _catatanPerlakuan
        .where((p) => p.tanggalPerlakuan.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
                     p.tanggalPerlakuan.isBefore(endOfWeek.add(const Duration(days: 1))))
        .toList();
  }

  // Get catatan perlakuan bulan ini
  List<CatatanPerlakuanModel> getCatatanPerlakuanBulanIni() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));

    return _catatanPerlakuan
        .where((p) => p.tanggalPerlakuan.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
                     p.tanggalPerlakuan.isBefore(endOfMonth.add(const Duration(days: 1))))
        .toList();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    await loadCatatanPerlakuan();
  }

  @override
  void dispose() {
    super.dispose();
  }
}