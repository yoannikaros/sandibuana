import 'package:flutter/foundation.dart';
import '../models/transaksi_model.dart';
import '../models/cart_item_model.dart';
import '../services/transaksi_service.dart';

class TransaksiProvider with ChangeNotifier {
  final TransaksiService _transaksiService = TransaksiService();
  
  List<TransaksiModel> _transaksiList = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<TransaksiModel> get transaksiList => _transaksiList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Create new transaction
  Future<bool> createTransaksi({
    required String idPelanggan,
    required String namaPelanggan,
    required List<CartItemModel> cartItems,
    String? informasiLain,
    DateTime? tanggalTransaksi,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final success = await _transaksiService.createTransaksi(
        idPelanggan: idPelanggan,
        namaPelanggan: namaPelanggan,
        cartItems: cartItems,
        informasiLain: informasiLain,
        tanggalTransaksi: tanggalTransaksi,
      );

      // Don't reload here to avoid setState during build
      // The calling screen should handle reloading if needed
      
      return success;
    } catch (e) {
      _setError('Gagal membuat transaksi: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Load all transactions
  Future<void> loadAllTransaksi() async {
    try {
      _setLoading(true);
      _setError(null);

      _transaksiList = await _transaksiService.getAllTransaksi();
      notifyListeners();
    } catch (e) {
      _setError('Gagal memuat transaksi: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load transactions by date range
  Future<void> loadTransaksiByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      _setLoading(true);
      _setError(null);

      _transaksiList = await _transaksiService.getTransaksiByDateRange(startDate, endDate);
      notifyListeners();
    } catch (e) {
      _setError('Gagal memuat transaksi: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load transactions by customer
  Future<void> loadTransaksiByPelanggan(String idPelanggan) async {
    try {
      _setLoading(true);
      _setError(null);

      _transaksiList = await _transaksiService.getTransaksiByPelanggan(idPelanggan);
      notifyListeners();
    } catch (e) {
      _setError('Gagal memuat transaksi: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get transaction by ID
  Future<TransaksiModel?> getTransaksiById(String id) async {
    try {
      return await _transaksiService.getTransaksiById(id);
    } catch (e) {
      _setError('Gagal memuat transaksi: $e');
      return null;
    }
  }

  // Delete transaction
  Future<bool> deleteTransaksi(String id) async {
    try {
      _setLoading(true);
      _setError(null);

      final success = await _transaksiService.deleteTransaksi(id);
      
      if (success) {
        _transaksiList.removeWhere((transaksi) => transaksi.id == id);
        notifyListeners();
      }

      return success;
    } catch (e) {
      _setError('Gagal menghapus transaksi: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get daily sales summary
  Future<Map<String, dynamic>> getDailySalesSummary(DateTime date) async {
    try {
      return await _transaksiService.getDailySalesSummary(date);
    } catch (e) {
      _setError('Gagal memuat ringkasan penjualan: $e');
      return {
        'total_revenue': 0.0,
        'total_transactions': 0,
        'total_items': 0,
        'transactions': <TransaksiModel>[],
      };
    }
  }

  // Get transactions for today
  Future<void> loadTodayTransaksi() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    
    await loadTransaksiByDateRange(startOfDay, endOfDay);
  }

  // Get total revenue for a specific period
  double getTotalRevenue() {
    return _transaksiList.fold(0.0, (sum, transaksi) => sum + transaksi.totalHarga);
  }

  // Get total transactions count
  int getTotalTransactionsCount() {
    return _transaksiList.length;
  }

  // Get total items sold
  double getTotalItemsSold() {
    return _transaksiList.fold(0.0, (sum, transaksi) {
      return sum + transaksi.items.fold(0.0, (itemSum, item) => itemSum + item.jumlah);
    });
  }

  // Clear error
  void clearError() {
    _setError(null);
  }

  // Safe reload method that can be called from UI without causing setState during build
  void safeReloadTransaksi() {
    Future.microtask(() => loadAllTransaksi());
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
}