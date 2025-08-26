import 'package:flutter/material.dart';
import '../models/kegagalan_panen_model.dart';
import '../models/penanaman_sayur_model.dart';
import '../services/kegagalan_panen_service.dart';
import '../services/penanaman_sayur_service.dart';

class KegagalanPanenProvider with ChangeNotifier {
  final KegagalanPanenService _kegagalanPanenService = KegagalanPanenService();
  final PenanamanSayurService _penanamanSayurService = PenanamanSayurService();

  List<KegagalanPanenModel> _kegagalanPanenList = [];
  List<PenanamanSayurModel> _penanamanSayurList = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<KegagalanPanenModel> get kegagalanPanenList => _kegagalanPanenList;
  List<PenanamanSayurModel> get penanamanSayurList => _penanamanSayurList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  KegagalanPanenService get kegagalanPanenService => _kegagalanPanenService;

  // Initialize provider
  Future<void> initialize() async {
    await loadKegagalanPanen();
    await loadPenanamanSayur();
  }

  // Load semua data kegagalan panen
  Future<void> loadKegagalanPanen() async {
    _setLoading(true);
    try {
      _kegagalanPanenList = await _kegagalanPanenService.getAllKegagalanPanen();
      _clearError();
    } catch (e) {
      _setError('Gagal memuat data kegagalan panen: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load data penanaman sayur untuk dropdown
  Future<void> loadPenanamanSayur() async {
    try {
      _penanamanSayurList = await _penanamanSayurService.getAllPenanamanSayur();
      notifyListeners();
    } catch (e) {
      print('Error loading penanaman sayur: $e');
    }
  }

  // Load kegagalan panen berdasarkan rentang tanggal
  Future<void> loadKegagalanPanenByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    _setLoading(true);
    try {
      _kegagalanPanenList = await _kegagalanPanenService.getKegagalanPanenByDateRange(
        startDate,
        endDate,
      );
      _clearError();
    } catch (e) {
      _setError('Gagal memuat data kegagalan panen: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Tambah kegagalan panen baru
  Future<bool> tambahKegagalanPanen({
    required DateTime tanggalGagal,
    required String idPenanaman,
    required int jumlahGagal,
    required String jenisKegagalan,
    String? penyebabGagal,
    String? lokasi,
    String? tindakanDiambil,
    required String dicatatOleh,
  }) async {
    _setLoading(true);
    try {
      final result = await _kegagalanPanenService.tambahKegagalanPanen(
        tanggalGagal: tanggalGagal,
        idPenanaman: idPenanaman,
        jumlahGagal: jumlahGagal,
        jenisKegagalan: jenisKegagalan,
        penyebabGagal: penyebabGagal,
        lokasi: lokasi,
        tindakanDiambil: tindakanDiambil,
        dicatatOleh: dicatatOleh,
      );
      
      if (result != null) {
        await loadKegagalanPanen();
        _clearError();
        return true;
      } else {
        _setError('Gagal menambah data kegagalan panen');
        return false;
      }
    } catch (e) {
      _setError('Gagal menambah data kegagalan panen: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update kegagalan panen
  Future<bool> updateKegagalanPanen(
    String idKegagalan,
    Map<String, dynamic> updateData,
  ) async {
    _setLoading(true);
    try {
      final success = await _kegagalanPanenService.updateKegagalanPanen(
        idKegagalan,
        updateData,
      );
      
      if (success) {
        await loadKegagalanPanen();
        _clearError();
        return true;
      } else {
        _setError('Gagal mengupdate data kegagalan panen');
        return false;
      }
    } catch (e) {
      _setError('Gagal mengupdate data kegagalan panen: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Hapus kegagalan panen
  Future<bool> hapusKegagalanPanen(String idKegagalan) async {
    _setLoading(true);
    try {
      final success = await _kegagalanPanenService.hapusKegagalanPanen(idKegagalan);
      
      if (success) {
        await loadKegagalanPanen();
        _clearError();
        return true;
      } else {
        _setError('Gagal menghapus data kegagalan panen');
        return false;
      }
    } catch (e) {
      _setError('Gagal menghapus data kegagalan panen: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Search kegagalan panen
  List<KegagalanPanenModel> searchKegagalanPanen(String query) {
    if (query.isEmpty) return _kegagalanPanenList;
    
    final lowerQuery = query.toLowerCase();
    return _kegagalanPanenList.where((kegagalan) {
      final jenisKegagalan = kegagalan.jenisKegagalan.toLowerCase();
      final penyebabGagal = (kegagalan.penyebabGagal ?? '').toLowerCase();
      final lokasi = (kegagalan.lokasi ?? '').toLowerCase();
      final tindakanDiambil = (kegagalan.tindakanDiambil ?? '').toLowerCase();
      
      return jenisKegagalan.contains(lowerQuery) ||
             penyebabGagal.contains(lowerQuery) ||
             lokasi.contains(lowerQuery) ||
             tindakanDiambil.contains(lowerQuery);
    }).toList();
  }

  // Filter berdasarkan jenis kegagalan
  List<KegagalanPanenModel> filterByJenisKegagalan(String jenisKegagalan) {
    if (jenisKegagalan == 'Semua') return _kegagalanPanenList;
    
    return _kegagalanPanenList.where((kegagalan) {
      return kegagalan.jenisKegagalan == jenisKegagalan;
    }).toList();
  }

  // Filter berdasarkan penanaman
  List<KegagalanPanenModel> filterByPenanaman(String idPenanaman) {
    if (idPenanaman == 'Semua') return _kegagalanPanenList;
    
    return _kegagalanPanenList.where((kegagalan) {
      return kegagalan.idPenanaman == idPenanaman;
    }).toList();
  }

  // Filter berdasarkan lokasi
  List<KegagalanPanenModel> filterByLokasi(String lokasi) {
    if (lokasi == 'Semua') return _kegagalanPanenList;
    
    return _kegagalanPanenList.where((kegagalan) {
      return kegagalan.lokasi == lokasi;
    }).toList();
  }

  // Get statistik kegagalan berdasarkan jenis
  Future<Map<String, int>> getStatistikKegagalanByJenis(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _kegagalanPanenService.getStatistikKegagalanByJenis(
        startDate,
        endDate,
      );
    } catch (e) {
      print('Error getting statistik kegagalan by jenis: $e');
      return {};
    }
  }

  // Get total kegagalan per bulan
  Future<Map<String, int>> getTotalKegagalanPerBulan(int tahun) async {
    try {
      return await _kegagalanPanenService.getTotalKegagalanPerBulan(tahun);
    } catch (e) {
      print('Error getting total kegagalan per bulan: $e');
      return {};
    }
  }

  // Get ringkasan kegagalan panen
  Future<Map<String, dynamic>> getRingkasanKegagalanPanen(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _kegagalanPanenService.getRingkasanKegagalanPanen(
        startDate,
        endDate,
      );
    } catch (e) {
      print('Error getting ringkasan kegagalan panen: $e');
      return {
        'total_kegagalan': 0,
        'total_jumlah_gagal': 0,
        'jenis_kegagalan': {},
        'lokasi_kegagalan': {},
        'rata_rata_per_kejadian': 0,
      };
    }
  }

  // Get unique jenis kegagalan options
  List<String> getJenisKegagalanOptions() {
    List<String> options = ['Semua'];
    options.addAll(KegagalanPanenModel.getJenisKegagalanOptions());
    return options;
  }

  // Get display name untuk jenis kegagalan
  String getJenisKegagalanDisplayName(String jenis) {
    if (jenis == 'Semua') return 'Semua';
    return KegagalanPanenModel.getJenisKegagalanDisplayName(jenis);
  }

  // Get unique penanaman options
  List<String> getPenanamanOptions() {
    List<String> options = ['Semua'];
    Set<String> uniqueIds = _kegagalanPanenList.map((k) => k.idPenanaman).toSet();
    options.addAll(uniqueIds.toList());
    return options;
  }

  // Get unique lokasi options
  List<String> getLokasiOptions() {
    List<String> options = ['Semua'];
    Set<String> uniqueLokasi = _kegagalanPanenList
        .where((k) => k.lokasi != null && k.lokasi!.isNotEmpty)
        .map((k) => k.lokasi!)
        .toSet();
    options.addAll(uniqueLokasi.toList());
    return options;
  }

  // Get penanaman name by ID
  String getPenanamanName(String? idPenanaman) {
    if (idPenanaman == null || idPenanaman.isEmpty) return 'Tidak diketahui';
    
    final penanaman = _penanamanSayurList.firstWhere(
      (p) => p.idPenanaman == idPenanaman,
      orElse: () => PenanamanSayurModel(
        idPenanaman: '',
        tanggalTanam: DateTime.now(),
        jenisSayur: 'Tidak diketahui',
        jumlahDitanam: 0,
        tahapPertumbuhan: 'semai',
        tingkatKeberhasilan: 0,
        dicatatOleh: '',
        dicatatPada: DateTime.now(),
        diubahPada: DateTime.now(),
      ),
    );
    
    final displayId = penanaman.idPenanaman.length > 8 
        ? penanaman.idPenanaman.substring(0, 8) + '...'
        : penanaman.idPenanaman;
    return '${penanaman.jenisSayur} ($displayId)';
  }

  // Refresh data
  Future<void> refresh() async {
    await initialize();
  }

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
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}