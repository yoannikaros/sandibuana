import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/jenis_benih_model.dart';
import '../models/pembelian_benih_model.dart';
import '../models/catatan_pembenihan_model.dart';
import '../services/benih_service.dart';

class BenihProvider with ChangeNotifier {
  final BenihService _benihService = BenihService();

  // State variables
  List<JenisBenihModel> _jenisBenihList = [];
  List<PembelianBenihModel> _pembelianBenihList = [];
  List<CatatanPembenihanModel> _catatanPembenihanList = [];
  
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<JenisBenihModel> get jenisBenihList => _jenisBenihList;
  List<PembelianBenihModel> get pembelianBenihList => _pembelianBenihList;
  List<CatatanPembenihanModel> get catatanPembenihanList => _catatanPembenihanList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Clear error
  void clearError() {
    _errorMessage = null;
    // Use post frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Set loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      // Use post frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // Set error message
  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    // Use post frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // ========================================
  // JENIS BENIH METHODS
  // ========================================

  // Load jenis benih aktif
  Future<void> loadJenisBenihAktif() async {
    try {
      _setLoading(true);
      _jenisBenihList = await _benihService.getJenisBenihAktif();
      _errorMessage = null;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load semua jenis benih
  Future<void> loadAllJenisBenih() async {
    try {
      _setLoading(true);
      _jenisBenihList = await _benihService.getAllJenisBenih();
      _errorMessage = null;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Tambah jenis benih baru
  Future<bool> tambahJenisBenih({
    required String namaBenih,
    String? pemasok,
    double? hargaPerSatuan,
    String? jenisSatuan,
    String? ukuranSatuan,
  }) async {
    try {
      _setLoading(true);
      
      final jenisBenih = JenisBenihModel(
        idBenih: '', // Will be set by Firestore
        namaBenih: namaBenih,
        pemasok: pemasok,
        hargaPerSatuan: hargaPerSatuan,
        jenisSatuan: jenisSatuan,
        ukuranSatuan: ukuranSatuan,
        aktif: true,
        dibuatPada: DateTime.now(),
      );

      await _benihService.tambahJenisBenih(jenisBenih);
      
      // Reload data
      await loadJenisBenihAktif();
      
      _errorMessage = null;
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update jenis benih
  Future<bool> updateJenisBenih(String id, Map<String, dynamic> data) async {
    try {
      _setLoading(true);
      await _benihService.updateJenisBenih(id, data);
      
      // Reload data
      await loadJenisBenihAktif();
      
      _errorMessage = null;
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Hapus jenis benih (soft delete)
  Future<bool> hapusJenisBenih(String id) async {
    try {
      _setLoading(true);
      await _benihService.hapusJenisBenih(id);
      
      // Reload data
      await loadJenisBenihAktif();
      
      _errorMessage = null;
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cari jenis benih
  Future<List<JenisBenihModel>> cariJenisBenih(String nama) async {
    try {
      return await _benihService.cariJenisBenih(nama);
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  // ========================================
  // PEMBELIAN BENIH METHODS
  // ========================================

  // Load pembelian benih berdasarkan tanggal
  Future<void> loadPembelianBenihByTanggal(DateTime startDate, DateTime endDate) async {
    try {
      _setLoading(true);
      _pembelianBenihList = await _benihService.getPembelianBenihByTanggal(startDate, endDate);
      _errorMessage = null;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Tambah pembelian benih baru
  Future<bool> tambahPembelianBenih({
    required DateTime tanggalBeli,
    required String idBenih,
    required String pemasok,
    required double jumlah,
    String? satuan,
    required double hargaSatuan,
    required double totalHarga,
    String? nomorFaktur,
    DateTime? tanggalKadaluarsa,
    String? lokasiPenyimpanan,
    String? catatan,
    required String dicatatOleh,
  }) async {
    try {
      _setLoading(true);
      
      final pembelian = PembelianBenihModel(
        idPembelian: '', // Will be set by Firestore
        tanggalBeli: tanggalBeli,
        idBenih: idBenih,
        pemasok: pemasok,
        jumlah: jumlah,
        satuan: satuan,
        hargaSatuan: hargaSatuan,
        totalHarga: totalHarga,
        nomorFaktur: nomorFaktur,
        tanggalKadaluarsa: tanggalKadaluarsa,
        lokasiPenyimpanan: lokasiPenyimpanan,
        catatan: catatan,
        dicatatOleh: dicatatOleh,
        dicatatPada: DateTime.now(),
      );

      await _benihService.tambahPembelianBenih(pembelian);
      
      _errorMessage = null;
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ========================================
  // CATATAN PEMBENIHAN METHODS
  // ========================================

  // Load catatan pembenihan berdasarkan tanggal
  Future<void> loadCatatanPembenihanByTanggal(DateTime startDate, DateTime endDate) async {
    try {
      _setLoading(true);
      _catatanPembenihanList = await _benihService.getCatatanPembenihanByTanggal(startDate, endDate);
      _errorMessage = null;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Tambah catatan pembenihan baru
  Future<bool> tambahCatatanPembenihan({
    required DateTime tanggalPembenihan,
    required DateTime tanggalSemai,
    required String idBenih,
    String? idTandon,
    String? idPupuk,
    String? mediaTanam,
    required int jumlah,
    String? satuan,
    required String kodeBatch,
    required String status,

    String? catatan,
    required String dicatatOleh,
  }) async {
    try {
      _setLoading(true);
      
      final catatanPembenihan = CatatanPembenihanModel(
        idPembenihan: '', // Will be set by Firestore
        tanggalPembenihan: tanggalPembenihan,
        tanggalSemai: tanggalSemai,
        idBenih: idBenih,
        idTandon: idTandon,
        idPupuk: idPupuk,
        mediaTanam: mediaTanam,
        jumlah: jumlah,
        satuan: satuan,
        kodeBatch: kodeBatch,
        status: status,

        catatan: catatan,
        dicatatOleh: dicatatOleh,
        dicatatPada: DateTime.now(),
      );

      await _benihService.tambahCatatanPembenihan(catatanPembenihan);
      
      _errorMessage = null;
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update catatan pembenihan
  Future<bool> updateCatatanPembenihan(String id, Map<String, dynamic> data) async {
    try {
      _setLoading(true);
      await _benihService.updateCatatanPembenihan(id, data);
      
      _errorMessage = null;
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Hapus catatan pembenihan
  Future<bool> hapusCatatanPembenihan(String id) async {
    try {
      _setLoading(true);
      await _benihService.hapusCatatanPembenihan(id);
      
      _errorMessage = null;
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ========================================
  // INITIALIZATION
  // ========================================

  // Inisialisasi data default
  Future<void> initializeDefaultData() async {
    try {
      await _benihService.initializeDefaultJenisBenih();
      await loadJenisBenihAktif();
    } catch (e) {
      _setError('Gagal inisialisasi data: ${e.toString()}');
    }
  }

  // Stream untuk real-time updates
  Stream<List<JenisBenihModel>> get jenisBenihStream {
    return _benihService.streamJenisBenihAktif();
  }
}