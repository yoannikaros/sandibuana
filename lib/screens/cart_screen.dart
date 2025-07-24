import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/penjualan_harian_provider.dart';
import '../providers/pelanggan_provider.dart';
import '../models/cart_item_model.dart';
import '../models/penjualan_harian_model.dart';
import '../models/pelanggan_model.dart';
import 'success_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String? selectedPelangganId;
  String selectedStatusKirim = 'pending';
  final TextEditingController catatanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PelangganProvider>().loadPelanggan();
      context.read<CartProvider>().loadCartItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang Belanja'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _refreshCart(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Keranjang',
          ),
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              return IconButton(
                onPressed: cartProvider.items.isNotEmpty
                    ? () => _showClearCartDialog()
                    : null,
                icon: const Icon(Icons.delete_sweep),
                tooltip: 'Kosongkan Keranjang',
              );
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (cartProvider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Keranjang kosong',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tambahkan produk dari halaman kasir',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _refreshCart(),
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartProvider.items.length,
                  itemBuilder: (context, index) {
                    final item = cartProvider.items[index];
                    return _buildCartItem(item, cartProvider);
                  },
                ),
              ),
              _buildCheckoutSection(cartProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItem(CartItem item, CartProvider cartProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.jenisSayur,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${item.harga.toStringAsFixed(0)} per ${item.satuan}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _removeItem(cartProvider, item),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Hapus dari keranjang',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: item.jumlah > 1
                      ? () => _updateQuantity(cartProvider, item.id!, item.jumlah - 1)
                      : null,
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${item.jumlah} ${item.satuan}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _updateQuantity(cartProvider, item.id!, item.jumlah + 1),
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green.shade100,
                  ),
                ),
                const Spacer(),
                Text(
                  'Rp ${item.total.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutSection(CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Rp ${cartProvider.totalAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showCheckoutDialog(cartProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Checkout (${cartProvider.itemCount} item)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCheckoutDialog(CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Checkout Pesanan'),
        content: Consumer<PelangganProvider>(
          builder: (context, pelangganProvider, child) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Pelanggan:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedPelangganId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Pilih pelanggan',
                    ),
                    items: [
                      // Add 'Umum' option at the top
                      const DropdownMenuItem(
                        value: 'umum',
                        child: Text('Umum'),
                      ),
                      // Add existing customers
                      ...pelangganProvider.pelangganList.map((pelanggan) {
                        return DropdownMenuItem(
                          value: pelanggan.id,
                          child: Text(pelanggan.namaPelanggan),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedPelangganId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Status Kirim:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedStatusKirim,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'terkirim', child: Text('Terkirim')),
                      DropdownMenuItem(value: 'batal', child: Text('Batal')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedStatusKirim = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Catatan (Opsional):',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: catatanController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Tambahkan catatan...',
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: selectedPelangganId != null
                ? () => _processCheckout(cartProvider)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedPelangganId != null
                  ? Colors.green.shade600
                  : Colors.grey,
              foregroundColor: Colors.white,
            ),
            child: const Text('Proses Pesanan'),
          ),
        ],
      ),
    );
  }

  void _processCheckout(CartProvider cartProvider) async {
    if (selectedPelangganId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon pilih pelanggan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate cart is not empty
    if (cartProvider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keranjang kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Handle 'umum' customer case
    String finalPelangganId = selectedPelangganId!;
    if (selectedPelangganId == 'umum') {
      finalPelangganId = 'umum';
    }

    try {
      final penjualanProvider = context.read<PenjualanHarianProvider>();
      
      // Create transactions for each cart item
      for (final item in cartProvider.items) {
        await penjualanProvider.tambahPenjualan(
          tanggalJual: DateTime.now(),
          idPelanggan: finalPelangganId,
          jenisSayur: item.jenisSayur,
          jumlah: item.jumlah,
          satuan: item.satuan, // Use item's actual satuan instead of hardcoded 'kg'
          hargaPerSatuan: item.harga,
          totalHarga: item.total,
          statusKirim: selectedStatusKirim,
          catatan: catatanController.text.isNotEmpty ? catatanController.text : null,
          dicatatOleh: 'Kasir', // You might want to get this from auth provider
        );
      }
      
      // Get pelanggan data
      final pelangganProvider = context.read<PelangganProvider>();
      PelangganModel? pelanggan;
      if (selectedPelangganId != 'umum') {
        pelanggan = pelangganProvider.pelangganList
            .where((p) => p.id == selectedPelangganId)
            .firstOrNull;
      }
      // For 'umum' customer, pelanggan will remain null
      
      // Calculate total
      final totalAmount = cartProvider.items
          .fold(0.0, (sum, item) => sum + item.total);
      
      // Generate transaction ID
      final transactionId = 'TXN${DateTime.now().millisecondsSinceEpoch}';
      
      // Store items before clearing cart
      final items = List<CartItem>.from(cartProvider.items);
      
      // Clear cart after successful checkout
      await cartProvider.clearCart();
      
      Navigator.pop(context); // Close loading dialog
      Navigator.pop(context); // Close checkout dialog
      
      // Navigate to success screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SuccessScreen(
            items: items,
            pelanggan: pelanggan,
            statusKirim: selectedStatusKirim,
            catatan: catatanController.text.isNotEmpty ? catatanController.text : null,
            totalAmount: totalAmount,
            transactionId: transactionId,
          ),
        ),
      );
      
      // Reset form
      setState(() {
        selectedPelangganId = null;
        selectedStatusKirim = 'pending';
        catatanController.clear();
      });
      
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memproses pesanan: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kosongkan Keranjang'),
        content: const Text('Apakah Anda yakin ingin menghapus semua item dari keranjang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await context.read<CartProvider>().clearCart();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Keranjang dikosongkan'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal mengosongkan keranjang: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }

  void _refreshCart() async {
    try {
      await context.read<CartProvider>().loadCartItems();
      await context.read<PelangganProvider>().loadPelanggan();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keranjang diperbarui'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui keranjang: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateQuantity(CartProvider cartProvider, String itemId, double newQuantity) async {
    // Validate quantity
    if (newQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah harus lebih dari 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newQuantity > 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah terlalu besar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await cartProvider.updateItemQuantity(itemId, newQuantity);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah jumlah: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeItem(CartProvider cartProvider, CartItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Item'),
        content: Text('Hapus ${item.jenisSayur} dari keranjang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await cartProvider.removeItem(item.id!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item.jenisSayur} dihapus dari keranjang'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus item: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    catatanController.dispose();
    super.dispose();
  }
}