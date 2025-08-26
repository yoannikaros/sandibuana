import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaksi_model.dart';
import '../models/cart_item_model.dart';

class TransaksiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create new transaction
  Future<bool> createTransaksi({
    required String idPelanggan,
    required String namaPelanggan,
    required List<CartItemModel> cartItems,
    String? informasiLain,
    DateTime? tanggalTransaksi,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User tidak terautentikasi');
      }

      // Generate transaction ID
      final transactionId = _firestore.collection('transaksi').doc().id;
      final now = DateTime.now();
      final tanggalBeli = tanggalTransaksi ?? now;

      // Convert cart items to transaction items
      final transactionItems = cartItems.map((cartItem) {
        return TransaksiItemModel(
          idPenanaman: cartItem.idPenanaman,
          jenisSayur: cartItem.jenisSayur,
          harga: cartItem.harga,
          jumlah: cartItem.jumlah,
          satuan: cartItem.satuan,
          totalHarga: cartItem.totalHarga,
        );
      }).toList();

      // Calculate total
      final totalHarga = cartItems.fold(0.0, (sum, item) => sum + item.totalHarga);

      // Create transaction model
      final transaksi = TransaksiModel(
        id: transactionId,
        idPelanggan: idPelanggan,
        namaPelanggan: namaPelanggan,
        tanggalBeli: tanggalBeli,
        items: transactionItems,
        totalHarga: totalHarga,
        informasiLain: informasiLain,
        dicatatPada: now,
        dicatatOleh: user.uid,
      );

      // Save to Firestore
      await _firestore
          .collection('transaksi')
          .doc(transactionId)
          .set(transaksi.toMap());

      return true;
    } catch (e) {
      print('Error creating transaction: $e');
      return false;
    }
  }

  // Get all transactions
  Future<List<TransaksiModel>> getAllTransaksi() async {
    try {
      final querySnapshot = await _firestore
          .collection('transaksi')
          .orderBy('dicatat_pada', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TransaksiModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting transactions: $e');
      return [];
    }
  }

  // Get transactions by date range
  Future<List<TransaksiModel>> getTransaksiByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await _firestore
          .collection('transaksi')
          .where('tanggal_beli', isGreaterThanOrEqualTo: startDate)
          .where('tanggal_beli', isLessThanOrEqualTo: endDate)
          .orderBy('tanggal_beli', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TransaksiModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting transactions by date range: $e');
      return [];
    }
  }

  // Get transactions by customer
  Future<List<TransaksiModel>> getTransaksiByPelanggan(String idPelanggan) async {
    try {
      final querySnapshot = await _firestore
          .collection('transaksi')
          .where('id_pelanggan', isEqualTo: idPelanggan)
          .orderBy('dicatat_pada', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TransaksiModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting transactions by customer: $e');
      return [];
    }
  }

  // Get transaction by ID
  Future<TransaksiModel?> getTransaksiById(String id) async {
    try {
      final doc = await _firestore.collection('transaksi').doc(id).get();
      
      if (doc.exists && doc.data() != null) {
        return TransaksiModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting transaction by ID: $e');
      return null;
    }
  }

  // Delete transaction
  Future<bool> deleteTransaksi(String id) async {
    try {
      await _firestore.collection('transaksi').doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting transaction: $e');
      return false;
    }
  }

  // Get daily sales summary
  Future<Map<String, dynamic>> getDailySalesSummary(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection('transaksi')
          .where('tanggal_beli', isGreaterThanOrEqualTo: startOfDay)
          .where('tanggal_beli', isLessThanOrEqualTo: endOfDay)
          .get();

      final transactions = querySnapshot.docs
          .map((doc) => TransaksiModel.fromMap(doc.data()))
          .toList();

      double totalRevenue = 0;
      int totalTransactions = transactions.length;
      double totalItems = 0.0;

      for (var transaction in transactions) {
        totalRevenue += transaction.totalHarga;
        totalItems += transaction.items.fold(0.0, (sum, item) => sum + item.jumlah);
      }

      return {
        'total_revenue': totalRevenue,
        'total_transactions': totalTransactions,
        'total_items': totalItems,
        'transactions': transactions,
      };
    } catch (e) {
      print('Error getting daily sales summary: $e');
      return {
        'total_revenue': 0.0,
        'total_transactions': 0,
        'total_items': 0,
        'transactions': <TransaksiModel>[],
      };
    }
  }
}