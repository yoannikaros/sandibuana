import 'package:flutter/material.dart';
import '../models/jadwal_pemupukan_model.dart';
import '../models/catatan_pembenihan_model.dart';
import '../services/jadwal_pemupukan_service.dart';
import '../services/benih_service.dart';
import '../providers/auth_provider.dart';

class JadwalPemupukanProvider with ChangeNotifier {
  final JadwalPemupukanService _service = JadwalPemupukanService();
  final BenihService _benihService = BenihService();
  final AuthProvider _authProvider;

  JadwalPemupukanProvider(this._authProvider);

  List<JadwalPemupukanModel> _jadwalList = [];
  List<JadwalPemupukanModel> _filteredJadwalList = [];
  List<CatatanPembenihanModel> _catatanPembenihanList = [];
  bool _isLoading = false;
  String? _error;
  DateTime _selectedMonth = DateTime.now();
  String _searchQuery = '';
  String _statusFilter = 'semua'; // semua, selesai, belum_selesai, terlambat
  int _mingguFilter = 0; // 0 = semua, 1-4 = minggu tertentu
  int _hariFilter = 0; // 0 = semua, 1-7 = hari tertentu
  Map<String, dynamic>? _statistik;

  // Getters
  List<JadwalPemupukanModel> get jadwalList => _filteredJadwalList;
  List<CatatanPembenihanModel> get catatanPembenihanList => _catatanPembenihanList;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedMonth => _selectedMonth;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  int get mingguFilter => _mingguFilter;
  int get hariFilter => _hariFilter;
  Map<String, dynamic>? get statistik => _statistik;

  // Load jadwal pemupukan
  Future<void> loadJadwalPemupukan() async {
    _setLoading(true);
    try {
      _jadwalList = await _service.getAllJadwalPemupukan();
      _applyFilters();
      await _loadStatistik();
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load jadwal berdasarkan bulan
  Future<void> loadJadwalByBulan(DateTime bulanTahun) async {
    _setLoading(true);
    try {
      _selectedMonth = bulanTahun;
      _jadwalList = await _service.getJadwalPemupukanByBulan(bulanTahun);
      await _loadCatatanPembenihan();
      _applyFilters();
      await _loadStatistik();
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Tambah jadwal pemupukan
  Future<bool> tambahJadwalPemupukan({
    required DateTime bulanTahun,
    required int mingguKe,
    required int hariDalamMinggu,
    required String perlakuanPupuk,
    String? perlakuanTambahan,
    String? catatan,
    String? idPembenihan,
  }) async {
    try {
      final userId = _authProvider.user?.idPengguna;
      if (userId == null) {
        throw Exception('User tidak terautentikasi');
      }

      await _service.tambahJadwalPemupukan(
        bulanTahun: bulanTahun,
        mingguKe: mingguKe,
        hariDalamMinggu: hariDalamMinggu,
        perlakuanPupuk: perlakuanPupuk,
        perlakuanTambahan: perlakuanTambahan,
        catatan: catatan,
        idPembenihan: idPembenihan,
        dibuatOleh: userId,
      );

      await loadJadwalByBulan(_selectedMonth);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Update jadwal pemupukan
  Future<bool> updateJadwalPemupukan(
    String idJadwal,
    Map<String, dynamic> updateData,
  ) async {
    try {
      await _service.updateJadwalPemupukan(idJadwal, updateData);
      await loadJadwalByBulan(_selectedMonth);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Tandai jadwal sebagai selesai
  Future<bool> tandaiSelesai(String idJadwal) async {
    try {
      final userId = _authProvider.user?.idPengguna;
      if (userId == null) {
        throw Exception('User tidak terautentikasi');
      }

      await _service.tandaiSelesai(idJadwal, userId);
      await loadJadwalByBulan(_selectedMonth);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Batalkan penyelesaian jadwal
  Future<bool> batalkanSelesai(String idJadwal) async {
    try {
      await _service.batalkanSelesai(idJadwal);
      await loadJadwalByBulan(_selectedMonth);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Hapus jadwal pemupukan
  Future<bool> hapusJadwalPemupukan(String idJadwal) async {
    try {
      await _service.hapusJadwalPemupukan(idJadwal);
      await loadJadwalByBulan(_selectedMonth);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Generate jadwal bulanan
  Future<bool> generateJadwalBulanan(DateTime bulanTahun) async {
    try {
      final userId = _authProvider.user?.idPengguna;
      if (userId == null) {
        throw Exception('User tidak terautentikasi');
      }

      await _service.generateJadwalBulanan(bulanTahun, userId);
      await loadJadwalByBulan(bulanTahun);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Load jadwal mendatang
  Future<void> loadJadwalMendatang() async {
    _setLoading(true);
    try {
      _jadwalList = await _service.getJadwalMendatang();
      _applyFilters();
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load jadwal terlambat
  Future<void> loadJadwalTerlambat() async {
    _setLoading(true);
    try {
      _jadwalList = await _service.getJadwalTerlambat();
      _applyFilters();
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load statistik
  Future<void> _loadStatistik() async {
    try {
      _statistik = await _service.getStatistikJadwal(_selectedMonth);
    } catch (e) {
      _statistik = null;
    }
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Set status filter
  void setStatusFilter(String status) {
    _statusFilter = status;
    _applyFilters();
    notifyListeners();
  }

  // Set minggu filter
  void setMingguFilter(int minggu) {
    _mingguFilter = minggu;
    _applyFilters();
    notifyListeners();
  }

  // Set hari filter
  void setHariFilter(int hari) {
    _hariFilter = hari;
    _applyFilters();
    notifyListeners();
  }

  // Set selected month
  void setSelectedMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month, 1);
    loadJadwalByBulan(_selectedMonth);
  }

  // Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _statusFilter = 'semua';
    _mingguFilter = 0;
    _hariFilter = 0;
    _applyFilters();
    notifyListeners();
  }

  // Apply filters
  void _applyFilters() {
    _filteredJadwalList = _jadwalList.where((jadwal) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!jadwal.perlakuanPupuk.toLowerCase().contains(query) &&
            !(jadwal.perlakuanTambahan?.toLowerCase().contains(query) ?? false) &&
            !(jadwal.catatan?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }

      // Status filter
      switch (_statusFilter) {
        case 'selesai':
          if (!jadwal.sudahSelesai) return false;
          break;
        case 'belum_selesai':
          if (jadwal.sudahSelesai) return false;
          break;
        case 'terlambat':
          if (!jadwal.isOverdue()) return false;
          break;
      }

      // Minggu filter
      if (_mingguFilter > 0 && jadwal.mingguKe != _mingguFilter) {
        return false;
      }

      // Hari filter
      if (_hariFilter > 0 && jadwal.hariDalamMinggu != _hariFilter) {
        return false;
      }

      return true;
    }).toList();
  }

  // Get jadwal by priority
  List<JadwalPemupukanModel> getJadwalByPriority() {
    final List<JadwalPemupukanModel> priorityList = List.from(_filteredJadwalList);
    priorityList.sort((a, b) {
      // Urutkan berdasarkan prioritas: terlambat > hari ini > mendatang
      final aPriority = a.getPriority();
      final bPriority = b.getPriority();
      
      if (aPriority != bPriority) {
        return bPriority.compareTo(aPriority); // Descending
      }
      
      // Jika prioritas sama, urutkan berdasarkan tanggal target
      return a.getTanggalTarget().compareTo(b.getTanggalTarget());
    });
    return priorityList;
  }

  // Get count by status
  Map<String, int> getCountByStatus() {
    final total = _jadwalList.length;
    final selesai = _jadwalList.where((j) => j.sudahSelesai).length;
    final belumSelesai = total - selesai;
    final terlambat = _jadwalList.where((j) => j.isOverdue()).length;
    
    return {
      'total': total,
      'selesai': selesai,
      'belum_selesai': belumSelesai,
      'terlambat': terlambat,
    };
  }

  // Get jadwal for today
  List<JadwalPemupukanModel> getJadwalHariIni() {
    final now = DateTime.now();
    return _jadwalList.where((jadwal) {
      final targetDate = jadwal.getTanggalTarget();
      return targetDate.year == now.year &&
             targetDate.month == now.month &&
             targetDate.day == now.day &&
             !jadwal.sudahSelesai;
    }).toList();
  }

  // Get overdue jadwal
  List<JadwalPemupukanModel> getJadwalTerlambat() {
    return _jadwalList.where((jadwal) => jadwal.isOverdue()).toList();
  }

  // Refresh data
  Future<void> refresh() async {
    await loadJadwalByBulan(_selectedMonth);
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

  // Get template perlakuan pupuk
  List<String> getTemplatePerlakuanPupuk() {
    return JadwalPemupukanModel.getPerlakuanPupukTemplates();
  }

  // Get nama hari
  String getNamaHari(int hari) {
    return JadwalPemupukanModel.getNamaHari(hari);
  }

  // Get options hari
  List<Map<String, dynamic>> getOptionsHari() {
    return JadwalPemupukanModel.getOptionsHari()
        .map((hari) => {
              'value': hari,
              'label': JadwalPemupukanModel.getNamaHari(hari),
            })
        .toList();
  }

  // Get options minggu
  List<Map<String, dynamic>> getOptionsMinggu() {
    return JadwalPemupukanModel.getOptionsMinggu()
        .map((minggu) => {
              'value': minggu,
              'label': 'Minggu ke-$minggu',
            })
        .toList();
  }

  // Load catatan pembenihan
  Future<void> _loadCatatanPembenihan() async {
    try {
      _catatanPembenihanList = await _benihService.getAllCatatanPembenihan();
    } catch (e) {
      // Jika gagal load catatan pembenihan, set list kosong
      _catatanPembenihanList = [];
    }
  }

  // Get catatan pembenihan name by ID
  String getCatatanPembenihanName(String? idPembenihan) {
    if (idPembenihan == null || idPembenihan.isEmpty) {
      return 'Tidak terkait';
    }
    
    try {
      final catatan = _catatanPembenihanList.firstWhere(
        (catatan) => catatan.idPembenihan == idPembenihan,
      );
      return '${catatan.kodeBatch} - ${catatan.status}';
    } catch (e) {
      return 'Pembenihan tidak ditemukan';
    }
  }

  // Get active catatan pembenihan (status berjalan)
  List<CatatanPembenihanModel> getActiveCatatanPembenihan() {
    return _catatanPembenihanList
        .where((catatan) => catatan.status == 'berjalan')
        .toList();
  }

  @override
  void dispose() {
    super.dispose();
  }
}