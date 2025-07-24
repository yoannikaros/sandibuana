import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../models/penjualan_harian_model.dart';
import '../providers/penjualan_harian_provider.dart';
import '../models/pelanggan_model.dart';
import '../models/cart_item_model.dart';
import '../providers/penjualan_harian_provider.dart';
import '../providers/penanaman_sayur_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/cart_screen.dart';

class PenjualanHarianScreen extends StatefulWidget {
  const PenjualanHarianScreen({super.key});

  @override
  State<PenjualanHarianScreen> createState() => _PenjualanHarianScreenState();
}

class _PenjualanHarianScreenState extends State<PenjualanHarianScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String? _selectedPelangganId;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PenjualanHarianProvider>().initialize();
      context.read<PenanamanSayurProvider>().loadAvailableJenisSayur();
      context.read<CartProvider>().loadCartItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Penjualan Sayur'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                    },
                  ),
                  if (cartProvider.itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${cartProvider.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showTransactionHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _buildProductGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari jenis sayur...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    return Consumer<PenanamanSayurProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final searchQuery = _searchController.text.toLowerCase();
        final filteredProducts = provider.availableJenisSayur
            .where((jenis) => jenis.toLowerCase().contains(searchQuery))
            .toList();

        if (filteredProducts.isEmpty) {
          return const Center(
            child: Text('Tidak ada produk yang tersedia'),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            final jenisSayur = filteredProducts[index];
            return _buildProductCard(jenisSayur);
          },
        );
      },
    );
  }

  Widget _buildProductCard(String jenisSayur) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showAddToCartDialog(jenisSayur),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  Icons.eco,
                  color: Colors.green.shade600,
                  size: 30,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                jenisSayur,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Harga: Sesuai Pasar',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '+ Keranjang',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddToCartDialog(String jenisSayur) {
    final hargaController = TextEditingController();
    final jumlahController = TextEditingController();
    String selectedSatuan = 'kg';
    final List<String> satuanOptions = ['kg', 'gram', 'ikat', 'buah', 'pcs'];
    double totalHarga = 0;

    // Get latest price from penanaman sayur data
    final penanamanProvider = context.read<PenanamanSayurProvider>();
    final latestPrice = penanamanProvider.getLatestPriceByJenisSayur(jenisSayur);
    if (latestPrice != null) {
      hargaController.text = latestPrice.toStringAsFixed(0);
    }

    void calculateTotal() {
      final harga = double.tryParse(hargaController.text) ?? 0;
      final jumlah = double.tryParse(jumlahController.text) ?? 0;
      totalHarga = harga * jumlah;
    }

    // Calculate initial total if price is already set
    WidgetsBinding.instance.addPostFrameCallback((_) {
      calculateTotal();
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Calculate initial total when dialog builds
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              calculateTotal();
            });
          });
          
          return AlertDialog(
          title: Text('Tambah $jenisSayur ke Keranjang'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hargaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga per satuan',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    calculateTotal();
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: jumlahController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          calculateTotal();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: selectedSatuan,
                    items: satuanOptions.map((satuan) {
                      return DropdownMenuItem(
                        value: satuan,
                        child: Text(satuan),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSatuan = value!;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Harga:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Rp ${totalHarga.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final harga = double.tryParse(hargaController.text) ?? 0;
                final jumlah = double.tryParse(jumlahController.text) ?? 0;
                
                if (harga > 0 && jumlah > 0) {
                  final cartItem = CartItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    jenisSayur: jenisSayur,
                    harga: harga,
                    jumlah: jumlah,
                    satuan: selectedSatuan,
                    total: harga * jumlah,
                    addedAt: DateTime.now(),
                  );
                  
                  context.read<CartProvider>().addItem(cartItem);
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$jenisSayur ditambahkan ke keranjang'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mohon isi harga dan jumlah dengan benar'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Tambah'),
            ),
          ],
          );
        },
      ),
    );
  }

  void _showTransactionHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Riwayat Transaksi'),
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () => _exportToPDF(),
                tooltip: 'Export ke PDF',
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddTransactionDialog(),
                tooltip: 'Tambah Transaksi',
              ),
            ],
          ),
          body: Consumer<PenjualanHarianProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (provider.penjualanList.isEmpty) {
                return const Center(
                  child: Text('Belum ada riwayat transaksi'),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.penjualanList.length,
                itemBuilder: (context, index) {
                  final penjualan = provider.penjualanList[index];
                  final pelanggan = provider.getPelangganById(penjualan.idPelanggan);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: Icon(
                          Icons.eco,
                          color: Colors.green.shade600,
                        ),
                      ),
                      title: Text(penjualan.jenisSayur),
                      subtitle: Text(
                        '${pelanggan?.namaPelanggan ?? 'Unknown'} • ${DateFormat('dd/MM/yyyy').format(penjualan.tanggalJual)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Rp ${penjualan.totalHarga.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              Text(
                                penjualan.statusKirim,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'detail':
                                  _showTransactionDetailDialog(penjualan);
                                  break;
                                case 'edit':
                                  _showEditTransactionDialog(penjualan);
                                  break;
                                case 'delete':
                                  _showDeleteConfirmation(penjualan);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'detail',
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline),
                                    SizedBox(width: 8),
                                    Text('Detail'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Hapus', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // CRUD Methods
  void _showAddTransactionDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddTransactionDialog(),
    );
  }

  void _showEditTransactionDialog(PenjualanHarianModel penjualan) {
    showDialog(
      context: context,
      builder: (context) => _EditTransactionDialog(penjualan: penjualan),
    );
  }

  void _showTransactionDetailDialog(PenjualanHarianModel penjualan) {
    showDialog(
      context: context,
      builder: (context) => _TransactionDetailDialog(penjualan: penjualan),
    );
  }

  void _showDeleteConfirmation(PenjualanHarianModel penjualan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus transaksi ${penjualan.jenisSayur}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context.read<PenjualanHarianProvider>().hapusPenjualan(penjualan.id);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaksi berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gagal menghapus transaksi'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToPDF() async {
    try {
      final provider = context.read<PenjualanHarianProvider>();
      final penjualanList = provider.penjualanList;
      
      if (penjualanList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada data untuk diekspor'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await _generatePDF(penjualanList, provider);
      
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF berhasil dibuat dan disimpan'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generatePDF(List<PenjualanHarianModel> penjualanList, PenjualanHarianProvider provider) async {
    final pdf = pw.Document();
    
    double totalPenjualan = 0;
    int totalTransaksi = penjualanList.length;
    
    for (final penjualan in penjualanList) {
      if (penjualan.statusKirim != 'batal') {
        totalPenjualan += penjualan.totalHarga;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'LAPORAN RIWAYAT TRANSAKSI',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Tanggal: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'RINGKASAN',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Transaksi: $totalTransaksi'),
                      pw.Text('Total Penjualan: Rp ${totalPenjualan.toStringAsFixed(0)}'),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'DETAIL TRANSAKSI',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Tanggal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Sayur', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Jumlah', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                ...penjualanList.map((penjualan) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(DateFormat('dd/MM/yyyy').format(penjualan.tanggalJual)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(penjualan.jenisSayur),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${penjualan.jumlah} ${penjualan.satuan}'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Rp ${penjualan.totalHarga.toStringAsFixed(0)}'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(penjualan.statusKirim),
                    ),
                  ],
                )),
              ],
            ),
          ];
        },
      ),
    );

    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/riwayat_transaksi_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }
}

// Dialog Classes
class _AddTransactionDialog extends StatefulWidget {
  @override
  State<_AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<_AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tanggalController = TextEditingController();
  final _jenisSayurController = TextEditingController();
  final _jumlahController = TextEditingController();
  final _hargaController = TextEditingController();
  final _catatanController = TextEditingController();
  String? _selectedPelangganId;
  String _selectedSatuan = 'kg';
  String _selectedStatus = 'pending';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tanggalController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Transaksi Baru'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _tanggalController,
                decoration: const InputDecoration(
                  labelText: 'Tanggal',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                      _tanggalController.text = DateFormat('dd/MM/yyyy').format(date);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _jenisSayurController,
                decoration: const InputDecoration(labelText: 'Jenis Sayur'),
                validator: (value) => value?.isEmpty == true ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _jumlahController,
                      decoration: const InputDecoration(labelText: 'Jumlah'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value?.isEmpty == true ? 'Wajib diisi' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: _selectedSatuan,
                    items: ['kg', 'gram', 'ikat', 'buah', 'pcs'].map((satuan) {
                      return DropdownMenuItem(value: satuan, child: Text(satuan));
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedSatuan = value!),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hargaController,
                decoration: const InputDecoration(
                  labelText: 'Harga per Satuan',
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty == true ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status Kirim'),
                items: [
                  const DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  const DropdownMenuItem(value: 'dikirim', child: Text('Dikirim')),
                  const DropdownMenuItem(value: 'selesai', child: Text('Selesai')),
                ],
                onChanged: (value) => setState(() => _selectedStatus = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _catatanController,
                decoration: const InputDecoration(labelText: 'Catatan (Opsional)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final jumlah = double.tryParse(_jumlahController.text) ?? 0;
      final harga = double.tryParse(_hargaController.text) ?? 0;
      
      final success = await context.read<PenjualanHarianProvider>().tambahPenjualan(
        tanggalJual: _selectedDate,
        idPelanggan: _selectedPelangganId!,
        jenisSayur: _jenisSayurController.text,
        jumlah: jumlah,
        satuan: _selectedSatuan,
        hargaPerSatuan: harga,
        totalHarga: jumlah * harga,
        statusKirim: _selectedStatus,
        catatan: _catatanController.text,
        dicatatOleh: 'Admin',
      );
      
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menambahkan transaksi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _EditTransactionDialog extends StatefulWidget {
  final PenjualanHarianModel penjualan;
  
  const _EditTransactionDialog({required this.penjualan});
  
  @override
  State<_EditTransactionDialog> createState() => _EditTransactionDialogState();
}

class _EditTransactionDialogState extends State<_EditTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tanggalController;
  late TextEditingController _jenisSayurController;
  late TextEditingController _jumlahController;
  late TextEditingController _hargaController;
  late TextEditingController _catatanController;
  late String _selectedSatuan;
  late String _selectedStatus;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.penjualan.tanggalJual;
    _tanggalController = TextEditingController(text: DateFormat('dd/MM/yyyy').format(_selectedDate));
    _jenisSayurController = TextEditingController(text: widget.penjualan.jenisSayur);
    _jumlahController = TextEditingController(text: widget.penjualan.jumlah.toString());
    _hargaController = TextEditingController(text: widget.penjualan.hargaPerSatuan?.toString() ?? '0');
    _catatanController = TextEditingController(text: widget.penjualan.catatan ?? '');
    _selectedSatuan = widget.penjualan.satuan ?? 'kg';
    _selectedStatus = widget.penjualan.statusKirim;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Transaksi'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _tanggalController,
                decoration: const InputDecoration(
                  labelText: 'Tanggal',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                      _tanggalController.text = DateFormat('dd/MM/yyyy').format(date);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _jenisSayurController,
                decoration: const InputDecoration(labelText: 'Jenis Sayur'),
                validator: (value) => value?.isEmpty == true ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _jumlahController,
                      decoration: const InputDecoration(labelText: 'Jumlah'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value?.isEmpty == true ? 'Wajib diisi' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: _selectedSatuan,
                    items: ['kg', 'gram', 'ikat', 'buah', 'pcs'].map((satuan) {
                      return DropdownMenuItem(value: satuan, child: Text(satuan));
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedSatuan = value!),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hargaController,
                decoration: const InputDecoration(
                  labelText: 'Harga per Satuan',
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty == true ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status Kirim'),
                items: [
                  const DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  const DropdownMenuItem(value: 'dikirim', child: Text('Dikirim')),
                  const DropdownMenuItem(value: 'selesai', child: Text('Selesai')),
                ],
                onChanged: (value) => setState(() => _selectedStatus = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _catatanController,
                decoration: const InputDecoration(labelText: 'Catatan (Opsional)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: const Text('Update'),
        ),
      ],
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final jumlah = double.tryParse(_jumlahController.text) ?? 0;
      final harga = double.tryParse(_hargaController.text) ?? 0;
      
      final success = await context.read<PenjualanHarianProvider>().updatePenjualan(widget.penjualan.id, {
        'tanggal_jual': _selectedDate,
        'jenis_sayur': _jenisSayurController.text,
        'jumlah': jumlah,
        'satuan': _selectedSatuan,
        'harga_per_satuan': harga,
        'total_harga': jumlah * harga,
        'status_kirim': _selectedStatus,
        'catatan': _catatanController.text,
      });
      
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi berhasil diupdate'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengupdate transaksi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _TransactionDetailDialog extends StatelessWidget {
  final PenjualanHarianModel penjualan;
  
  const _TransactionDetailDialog({required this.penjualan});
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Detail Transaksi'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Tanggal', DateFormat('dd/MM/yyyy').format(penjualan.tanggalJual)),
          _buildDetailRow('Jenis Sayur', penjualan.jenisSayur),
          _buildDetailRow('Jumlah', '${penjualan.jumlah} ${penjualan.satuan}'),
          _buildDetailRow('Harga per Satuan', penjualan.hargaPerSatuan != null ? 'Rp ${penjualan.hargaPerSatuan!.toStringAsFixed(0)}' : '-'),
          _buildDetailRow('Total Harga', 'Rp ${penjualan.totalHarga.toStringAsFixed(0)}'),
          _buildDetailRow('Status Kirim', penjualan.statusKirim),
          if (penjualan.catatan?.isNotEmpty == true)
            _buildDetailRow('Catatan', penjualan.catatan!),
          _buildDetailRow('Dicatat Pada', DateFormat('dd/MM/yyyy HH:mm').format(penjualan.dicatatPada)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}