import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/penanaman_sayur_model.dart';

class CartProvider with ChangeNotifier {
  List<CartItemModel> _cartItems = [];
  String? _selectedPelangganId;
  String? _selectedPelangganName;

  // Getters
  List<CartItemModel> get cartItems => _cartItems;
  String? get selectedPelangganId => _selectedPelangganId;
  String? get selectedPelangganName => _selectedPelangganName;
  
  double get totalItems => _cartItems.fold(0.0, (sum, item) => sum + item.jumlah);
  double get totalHarga => _cartItems.fold(0.0, (sum, item) => sum + item.totalHarga);
  bool get isCartEmpty => _cartItems.isEmpty;

  // Set selected pelanggan
  void setSelectedPelanggan(String? pelangganId, String? pelangganName) {
    _selectedPelangganId = pelangganId;
    _selectedPelangganName = pelangganName;
    notifyListeners();
  }

  // Add item to cart
  void addToCart(PenanamanSayurModel penanaman, double jumlah, String satuan) {
    if (penanaman.harga == null || penanaman.harga! <= 0) {
      throw Exception('Harga sayur belum ditentukan');
    }

    final existingIndex = _cartItems.indexWhere(
      (item) => item.idPenanaman == penanaman.idPenanaman,
    );

    if (existingIndex >= 0) {
      // Update existing item
      final existingItem = _cartItems[existingIndex];
      final newJumlah = existingItem.jumlah + jumlah;
      final newTotalHarga = newJumlah * penanaman.harga!;
      
      _cartItems[existingIndex] = existingItem.copyWith(
        jumlah: newJumlah,
        totalHarga: newTotalHarga,
      );
    } else {
      // Add new item
      final cartItem = CartItemModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        idPenanaman: penanaman.idPenanaman,
        jenisSayur: penanaman.jenisSayur,
        harga: penanaman.harga!,
        jumlah: jumlah,
        satuan: satuan,
        totalHarga: jumlah * penanaman.harga!,
      );
      _cartItems.add(cartItem);
    }
    
    notifyListeners();
  }

  // Update item quantity
  void updateItemQuantity(String cartItemId, double newJumlah) {
    if (newJumlah <= 0) {
      removeFromCart(cartItemId);
      return;
    }

    final index = _cartItems.indexWhere((item) => item.id == cartItemId);
    if (index >= 0) {
      final item = _cartItems[index];
      _cartItems[index] = item.copyWith(
        jumlah: newJumlah,
        totalHarga: newJumlah * item.harga,
      );
      notifyListeners();
    }
  }

  // Remove item from cart
  void removeFromCart(String cartItemId) {
    _cartItems.removeWhere((item) => item.id == cartItemId);
    notifyListeners();
  }

  // Clear cart
  void clearCart() {
    _cartItems.clear();
    _selectedPelangganId = null;
    _selectedPelangganName = null;
    notifyListeners();
  }

  // Get cart item by ID
  CartItemModel? getCartItemById(String cartItemId) {
    try {
      return _cartItems.firstWhere((item) => item.id == cartItemId);
    } catch (e) {
      return null;
    }
  }

  // Check if item exists in cart
  bool isItemInCart(String idPenanaman) {
    return _cartItems.any((item) => item.idPenanaman == idPenanaman);
  }

  // Get item quantity in cart
  double getItemQuantity(String idPenanaman) {
    try {
      final item = _cartItems.firstWhere(
        (item) => item.idPenanaman == idPenanaman,
      );
      return item.jumlah;
    } catch (e) {
      return 0.0;
    }
  }
}