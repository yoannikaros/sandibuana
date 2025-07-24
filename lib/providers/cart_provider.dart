import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../services/cart_service.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();
  List<CartItem> _cartItems = [];
  bool _isLoading = false;

  List<CartItem> get items => _cartItems;
  List<CartItem> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  
  double get totalAmount => _cartItems.fold(0.0, (sum, item) => sum + item.total);
  int get itemCount => _cartItems.length;
  int get totalQuantity => _cartItems.fold(0, (sum, item) => sum + item.jumlah.toInt());

  // Load cart items from database
  Future<void> loadCartItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      _cartItems = await _cartService.getCartItems();
    } catch (e) {
      debugPrint('Error loading cart items: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add item to cart
  Future<void> addToCart({
    required String jenisSayur,
    required double harga,
    required double jumlah,
    required String satuan,
  }) async {
    try {
      final cartItem = CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        jenisSayur: jenisSayur,
        harga: harga,
        jumlah: jumlah,
        satuan: satuan,
        total: harga * jumlah,
        addedAt: DateTime.now(),
      );

      await _cartService.addToCart(cartItem);
      await loadCartItems();
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      rethrow;
    }
  }

  // Add CartItem directly to cart
  Future<void> addItem(CartItem cartItem) async {
    try {
      await _cartService.addToCart(cartItem);
      await loadCartItems();
    } catch (e) {
      debugPrint('Error adding item to cart: $e');
      rethrow;
    }
  }

  // Update item quantity
  Future<void> updateItemQuantity(String itemId, double newQuantity) async {
    try {
      final itemIndex = _cartItems.indexWhere((item) => item.id == itemId);
      if (itemIndex != -1) {
        final item = _cartItems[itemIndex];
        final updatedItem = item.copyWith(
          jumlah: newQuantity,
          total: item.harga * newQuantity,
        );
        
        await _cartService.updateCartItem(updatedItem);
        await loadCartItems();
      }
    } catch (e) {
      debugPrint('Error updating item quantity: $e');
      rethrow;
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String itemId) async {
    try {
      await _cartService.removeFromCart(itemId);
      await loadCartItems();
    } catch (e) {
      debugPrint('Error removing from cart: $e');
      rethrow;
    }
  }

  // Remove item from cart by id
  Future<void> removeItem(String itemId) async {
    try {
      await _cartService.removeFromCart(itemId);
      await loadCartItems();
    } catch (e) {
      debugPrint('Error removing item from cart: $e');
      rethrow;
    }
  }

  // Clear all items from cart
  Future<void> clearCart() async {
    try {
      await _cartService.clearCart();
      _cartItems.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing cart: $e');
      rethrow;
    }
  }

  // Check if item exists in cart
  bool isItemInCart(String jenisSayur) {
    return _cartItems.any((item) => item.jenisSayur == jenisSayur);
  }

  // Get item quantity in cart
  double getItemQuantity(String jenisSayur) {
    final item = _cartItems.firstWhere(
      (item) => item.jenisSayur == jenisSayur,
      orElse: () => CartItem(
        id: '',
        jenisSayur: '',
        harga: 0,
        jumlah: 0,
        satuan: '',
        total: 0,
        addedAt: DateTime.now(),
      ),
    );
    return item.jumlah;
  }
}