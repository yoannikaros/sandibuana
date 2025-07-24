import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/pembelian_benih_model.dart';
import '../models/jenis_benih_model.dart';
import '../providers/pembelian_benih_provider.dart';
import '../providers/benih_provider.dart';

class PembelianBenihScreen extends StatefulWidget {
  const PembelianBenihScreen({Key? key}) : super(key: key);

  @override
  State<PembelianBenihScreen> createState() => _PembelianBenihScreenState();
}

class _PembelianBenihScreenState extends State<PembelianBenihScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    // Initialize Indonesian locale for DateFormat
    initializeDateFormatting('id_ID', null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = Provider.of<PembelianBenihProvider>(context, listen: false);
    final benihProvider = Provider.of<BenihProvider>(context, listen: false);
    
    await Future.wait([
      provider.loadPembelianBenih(),
      provider.loadDropdownOptions(),
      provider.loadStatistics(),
      benihProvider.loadJenisBenihAktif(),
    ]);
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
        title: const Text('Pembelian Benih'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showStatisticsDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: Consumer<PembelianBenihProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${provider.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.pembelianList.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada data pembelian benih',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.pembelianList.length,
                    itemBuilder: (context, index) {
                      final pembelian = provider.pembelianList[index];
                      return _buildPembelianCard(pembelian);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari pemasok, nomor faktur, atau catatan...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        Provider.of<PembelianBenihProvider>(context, listen: false)
                            .setSearchQuery('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              Provider.of<PembelianBenihProvider>(context, listen: false)
                  .setSearchQuery(value);
            },
          ),
          const SizedBox(height: 8),
          Consumer<PembelianBenihProvider>(
            builder: (context, provider, child) {
              final hasActiveFilters = provider.selectedBenih != null ||
                  provider.selectedPemasok != null ||
                  provider.startDate != null ||
                  provider.endDate != null ||
                  provider.showExpiredOnly ||
                  provider.showExpiringSoonOnly;

              if (!hasActiveFilters) return const SizedBox.shrink();

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (provider.selectedBenih != null)
                      _buildFilterChip(
                        'Benih: ${provider.selectedBenih}',
                        () => provider.setSelectedBenih(null),
                      ),
                    if (provider.selectedPemasok != null)
                      _buildFilterChip(
                        'Pemasok: ${provider.selectedPemasok}',
                        () => provider.setSelectedPemasok(null),
                      ),
                    if (provider.startDate != null || provider.endDate != null)
                      _buildFilterChip(
                        'Tanggal: ${provider.startDate != null ? _dateFormat.format(provider.startDate!) : ''} - ${provider.endDate != null ? _dateFormat.format(provider.endDate!) : ''}',
                        () => provider.setDateRange(null, null),
                      ),
                    if (provider.showExpiredOnly)
                      _buildFilterChip(
                        'Kadaluarsa',
                        () => provider.setShowExpiredOnly(false),
                      ),
                    if (provider.showExpiringSoonOnly)
                      _buildFilterChip(
                        'Akan Kadaluarsa',
                        () => provider.setShowExpiringSoonOnly(false),
                      ),
                    ActionChip(
                      label: const Text('Hapus Semua'),
                      onPressed: provider.clearFilters,
                      backgroundColor: Colors.red[100],
                      labelStyle: TextStyle(color: Colors.red[700]),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDeleted) {
    return Chip(
      label: Text(label),
      onDeleted: onDeleted,
      backgroundColor: Colors.blue[100],
      labelStyle: TextStyle(color: Colors.blue[700]),
    );
  }

  Widget _buildPembelianCard(PembelianBenihModel pembelian) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showDetailDialog(pembelian),
        borderRadius: BorderRadius.circular(8),
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
                          pembelian.displayTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pembelian.displaySubtitle,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(
                        pembelian.getStatusIcon(),
                        color: pembelian.getStatusColor(),
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _showAddEditDialog(pembelian: pembelian);
                              break;
                            case 'delete':
                              _showDeleteConfirmation(pembelian);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Hapus', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    pembelian.formattedTanggalBeli,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule, size: 16, color: pembelian.getStatusColor()),
                  const SizedBox(width: 4),
                  Text(
                    pembelian.getStatusText(),
                    style: TextStyle(
                      color: pembelian.getStatusColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (pembelian.catatan != null && pembelian.catatan!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.note, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          pembelian.catatan!,
                          style: TextStyle(color: Colors.grey[700], fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(),
    );
  }

  void _showStatisticsDialog() {
    showDialog(
      context: context,
      builder: (context) => _StatisticsDialog(),
    );
  }

  void _showAddEditDialog({PembelianBenihModel? pembelian}) {
    showDialog(
      context: context,
      builder: (context) => _AddEditDialog(pembelian: pembelian),
    );
  }

  void _showDetailDialog(PembelianBenihModel pembelian) {
    showDialog(
      context: context,
      builder: (context) => _DetailDialog(pembelian: pembelian),
    );
  }

  void _showDeleteConfirmation(PembelianBenihModel pembelian) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Apakah Anda yakin ingin menghapus pembelian benih dari ${pembelian.pemasok}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = Provider.of<PembelianBenihProvider>(context, listen: false);
              final success = await provider.deletePembelianBenih(pembelian.idPembelian!);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Pembelian benih berhasil dihapus'
                        : 'Gagal menghapus pembelian benih'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// Filter Dialog
class _FilterDialog extends StatefulWidget {
  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  String? _selectedBenih;
  String? _selectedPemasok;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showExpiredOnly = false;
  bool _showExpiringSoonOnly = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<PembelianBenihProvider>(context, listen: false);
    _selectedBenih = provider.selectedBenih;
    _selectedPemasok = provider.selectedPemasok;
    _startDate = provider.startDate;
    _endDate = provider.endDate;
    _showExpiredOnly = provider.showExpiredOnly;
    _showExpiringSoonOnly = provider.showExpiringSoonOnly;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Pembelian Benih'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Consumer<BenihProvider>(
              builder: (context, benihProvider, child) {
                return DropdownButtonFormField<String>(
                  value: _selectedBenih,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Benih',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Semua Benih'),
                    ),
                    ...benihProvider.jenisBenihList.map((benih) =>
                        DropdownMenuItem<String>(
                          value: benih.idBenih,
                          child: Text(benih.namaBenih),
                        )),
                  ],
                  onChanged: (value) => setState(() => _selectedBenih = value),
                );
              },
            ),
            const SizedBox(height: 16),
            Consumer<PembelianBenihProvider>(
              builder: (context, provider, child) {
                return DropdownButtonFormField<String>(
                  value: _selectedPemasok,
                  decoration: const InputDecoration(
                    labelText: 'Pemasok',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Semua Pemasok'),
                    ),
                    ...provider.pemasokOptions.map((pemasok) =>
                        DropdownMenuItem<String>(
                          value: pemasok,
                          child: Text(pemasok),
                        )),
                  ],
                  onChanged: (value) => setState(() => _selectedPemasok = value),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Mulai',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    controller: TextEditingController(
                      text: _startDate != null
                          ? DateFormat('dd/MM/yyyy').format(_startDate!)
                          : '',
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _startDate = date);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Akhir',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    controller: TextEditingController(
                      text: _endDate != null
                          ? DateFormat('dd/MM/yyyy').format(_endDate!)
                          : '',
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: _startDate ?? DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _endDate = date);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Hanya yang Kadaluarsa'),
              value: _showExpiredOnly,
              onChanged: (value) {
                setState(() {
                  _showExpiredOnly = value ?? false;
                  if (_showExpiredOnly) _showExpiringSoonOnly = false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Hanya yang Akan Kadaluarsa'),
              value: _showExpiringSoonOnly,
              onChanged: (value) {
                setState(() {
                  _showExpiringSoonOnly = value ?? false;
                  if (_showExpiringSoonOnly) _showExpiredOnly = false;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () {
            final provider = Provider.of<PembelianBenihProvider>(context, listen: false);
            provider.setSelectedBenih(_selectedBenih);
            provider.setSelectedPemasok(_selectedPemasok);
            provider.setDateRange(_startDate, _endDate);
            provider.setShowExpiredOnly(_showExpiredOnly);
            provider.setShowExpiringSoonOnly(_showExpiringSoonOnly);
            Navigator.pop(context);
          },
          child: const Text('Terapkan'),
        ),
      ],
    );
  }
}

// Statistics Dialog
class _StatisticsDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Statistik Pembelian Benih'),
      content: Consumer<PembelianBenihProvider>(
        builder: (context, provider, child) {
          final stats = provider.statistics;
          final expiredItems = provider.getExpiredItems();
          final expiringSoonItems = provider.getExpiringSoonItems();
          final recentPurchases = provider.getRecentPurchases();
          final thisMonthSpending = provider.getThisMonthSpending();
          final averagePurchase = provider.getAveragePurchaseValue();
          final mostFrequentSupplier = provider.getMostFrequentSupplier();

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatCard(
                  'Total Pembelian (30 hari)',
                  'Rp ${(stats['total_harga'] ?? 0).toStringAsFixed(0)}',
                  Icons.shopping_cart,
                  Colors.blue,
                ),
                const SizedBox(height: 8),
                _buildStatCard(
                  'Total Transaksi (30 hari)',
                  '${stats['total_transaksi'] ?? 0}',
                  Icons.receipt,
                  Colors.green,
                ),
                const SizedBox(height: 8),
                _buildStatCard(
                  'Rata-rata per Transaksi',
                  'Rp ${averagePurchase.toStringAsFixed(0)}',
                  Icons.analytics,
                  Colors.orange,
                ),
                const SizedBox(height: 8),
                _buildStatCard(
                  'Pengeluaran Bulan Ini',
                  'Rp ${thisMonthSpending.toStringAsFixed(0)}',
                  Icons.calendar_month,
                  Colors.purple,
                ),
                const SizedBox(height: 8),
                _buildStatCard(
                  'Pembelian 7 Hari Terakhir',
                  '${recentPurchases.length}',
                  Icons.schedule,
                  Colors.teal,
                ),
                const SizedBox(height: 8),
                _buildStatCard(
                  'Item Kadaluarsa',
                  '${expiredItems.length}',
                  Icons.dangerous,
                  Colors.red,
                ),
                const SizedBox(height: 8),
                _buildStatCard(
                  'Item Akan Kadaluarsa',
                  '${expiringSoonItems.length}',
                  Icons.warning,
                  Colors.orange,
                ),
                if (mostFrequentSupplier != null) ...[
                  const SizedBox(height: 8),
                  _buildStatCard(
                    'Pemasok Terfavorit',
                    mostFrequentSupplier,
                    Icons.business,
                    Colors.indigo,
                  ),
                ],
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Add/Edit Dialog
class _AddEditDialog extends StatefulWidget {
  final PembelianBenihModel? pembelian;

  const _AddEditDialog({this.pembelian});

  @override
  State<_AddEditDialog> createState() => _AddEditDialogState();
}

class _AddEditDialogState extends State<_AddEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pemasokController = TextEditingController();
  final _jumlahController = TextEditingController();
  final _hargaSatuanController = TextEditingController();
  final _totalHargaController = TextEditingController();
  final _nomorFakturController = TextEditingController();
  final _lokasiPenyimpananController = TextEditingController();
  final _catatanController = TextEditingController();
  
  String? _selectedBenih;
  String? _selectedSatuan;
  DateTime _tanggalBeli = DateTime.now();
  DateTime? _tanggalKadaluarsa;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.pembelian != null) {
      _initializeFromPembelian();
    }
  }

  void _initializeFromPembelian() {
    final p = widget.pembelian!;
    _selectedBenih = p.idBenih;
    _pemasokController.text = p.pemasok;
    _jumlahController.text = p.jumlah.toString();
    _selectedSatuan = p.satuan;
    _hargaSatuanController.text = p.hargaSatuan.toString();
    _totalHargaController.text = p.totalHarga.toString();
    _nomorFakturController.text = p.nomorFaktur ?? '';
    _tanggalBeli = p.tanggalBeli;
    _tanggalKadaluarsa = p.tanggalKadaluarsa;
    _lokasiPenyimpananController.text = p.lokasiPenyimpanan ?? '';
    _catatanController.text = p.catatan ?? '';
  }

  @override
  void dispose() {
    _pemasokController.dispose();
    _jumlahController.dispose();
    _hargaSatuanController.dispose();
    _totalHargaController.dispose();
    _nomorFakturController.dispose();
    _lokasiPenyimpananController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final jumlah = double.tryParse(_jumlahController.text) ?? 0;
    final hargaSatuan = double.tryParse(_hargaSatuanController.text) ?? 0;
    final total = jumlah * hargaSatuan;
    _totalHargaController.text = total.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.pembelian == null ? 'Tambah Pembelian Benih' : 'Edit Pembelian Benih'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<BenihProvider>(
                builder: (context, benihProvider, child) {
                  return DropdownButtonFormField<String>(
                    value: _selectedBenih,
                    decoration: const InputDecoration(
                      labelText: 'Jenis Benih *',
                      border: OutlineInputBorder(),
                    ),
                    items: benihProvider.jenisBenihList.map((benih) =>
                        DropdownMenuItem<String>(
                          value: benih.idBenih,
                          child: Text(benih.namaBenih),
                        )).toList(),
                    onChanged: (value) => setState(() => _selectedBenih = value),
                    validator: (value) => value == null ? 'Pilih jenis benih' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pemasokController,
                decoration: const InputDecoration(
                  labelText: 'Pemasok *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.trim().isEmpty ?? true ? 'Pemasok harus diisi' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _jumlahController,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _calculateTotal(),
                      validator: (value) {
                        final num = double.tryParse(value ?? '');
                        return num == null || num <= 0 ? 'Jumlah harus > 0' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSatuan,
                      decoration: const InputDecoration(
                        labelText: 'Satuan',
                        border: OutlineInputBorder(),
                      ),
                      items: PembelianBenihModel.getSatuanOptions().map((satuan) =>
                          DropdownMenuItem<String>(
                            value: satuan,
                            child: Text(satuan),
                          )).toList(),
                      onChanged: (value) => setState(() => _selectedSatuan = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hargaSatuanController,
                      decoration: const InputDecoration(
                        labelText: 'Harga Satuan *',
                        border: OutlineInputBorder(),
                        prefixText: 'Rp ',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _calculateTotal(),
                      validator: (value) {
                        final num = double.tryParse(value ?? '');
                        return num == null || num <= 0 ? 'Harga harus > 0' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _totalHargaController,
                      decoration: const InputDecoration(
                        labelText: 'Total Harga *',
                        border: OutlineInputBorder(),
                        prefixText: 'Rp ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final num = double.tryParse(value ?? '');
                        return num == null || num <= 0 ? 'Total harus > 0' : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomorFakturController,
                decoration: const InputDecoration(
                  labelText: 'Nomor Faktur',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Beli *',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      controller: TextEditingController(
                        text: DateFormat('dd/MM/yyyy').format(_tanggalBeli),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _tanggalBeli,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _tanggalBeli = date);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Kadaluarsa',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      controller: TextEditingController(
                        text: _tanggalKadaluarsa != null
                            ? DateFormat('dd/MM/yyyy').format(_tanggalKadaluarsa!)
                            : '',
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _tanggalKadaluarsa ?? _tanggalBeli.add(const Duration(days: 365)),
                          firstDate: _tanggalBeli,
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (date != null) {
                          setState(() => _tanggalKadaluarsa = date);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _lokasiPenyimpananController.text.isNotEmpty
                    ? _lokasiPenyimpananController.text
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Lokasi Penyimpanan',
                  border: OutlineInputBorder(),
                ),
                items: PembelianBenihModel.getLokasiPenyimpananOptions().map((lokasi) =>
                    DropdownMenuItem<String>(
                      value: lokasi,
                      child: Text(lokasi),
                    )).toList(),
                onChanged: (value) {
                  setState(() => _lokasiPenyimpananController.text = value ?? '');
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _catatanController,
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _savePembelian,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.pembelian == null ? 'Simpan' : 'Update'),
        ),
      ],
    );
  }

  Future<void> _savePembelian() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final pembelian = PembelianBenihModel(
        idPembelian: widget.pembelian?.idPembelian,
        tanggalBeli: _tanggalBeli,
        idBenih: _selectedBenih!,
        pemasok: _pemasokController.text.trim(),
        jumlah: double.parse(_jumlahController.text),
        satuan: _selectedSatuan,
        hargaSatuan: double.parse(_hargaSatuanController.text),
        totalHarga: double.parse(_totalHargaController.text),
        nomorFaktur: _nomorFakturController.text.trim().isNotEmpty
            ? _nomorFakturController.text.trim()
            : null,
        tanggalKadaluarsa: _tanggalKadaluarsa,
        lokasiPenyimpanan: _lokasiPenyimpananController.text.trim().isNotEmpty
            ? _lokasiPenyimpananController.text.trim()
            : null,
        catatan: _catatanController.text.trim().isNotEmpty
            ? _catatanController.text.trim()
            : null,
        dicatatOleh: '',
        dicatatPada: DateTime.now(),
      );

      final validation = pembelian.validate();
      if (validation != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validation),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final provider = Provider.of<PembelianBenihProvider>(context, listen: false);
      bool success;
      
      if (widget.pembelian == null) {
        success = await provider.addPembelianBenih(pembelian);
      } else {
        success = await provider.updatePembelianBenih(
          widget.pembelian!.idPembelian!,
          pembelian,
        );
      }

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.pembelian == null
                  ? 'Pembelian benih berhasil ditambahkan'
                  : 'Pembelian benih berhasil diperbarui'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.error ?? 'Terjadi kesalahan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// Detail Dialog
class _DetailDialog extends StatelessWidget {
  final PembelianBenihModel pembelian;

  const _DetailDialog({required this.pembelian});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Detail Pembelian Benih'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Pemasok', pembelian.pemasok),
            _buildDetailRow('Jumlah', pembelian.formattedJumlah),
            _buildDetailRow('Harga Satuan', pembelian.formattedHargaSatuan),
            _buildDetailRow('Total Harga', pembelian.formattedTotalHarga),
            if (pembelian.nomorFaktur != null)
              _buildDetailRow('Nomor Faktur', pembelian.nomorFaktur!),
            _buildDetailRow('Tanggal Beli', pembelian.formattedTanggalBeli),
            _buildDetailRow('Tanggal Kadaluarsa', pembelian.formattedTanggalKadaluarsa),
            if (pembelian.lokasiPenyimpanan != null)
              _buildDetailRow('Lokasi Penyimpanan', pembelian.lokasiPenyimpanan!),
            if (pembelian.catatan != null)
              _buildDetailRow('Catatan', pembelian.catatan!),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: pembelian.getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: pembelian.getStatusColor().withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    pembelian.getStatusIcon(),
                    color: pembelian.getStatusColor(),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status Kadaluarsa',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          pembelian.getStatusText(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: pembelian.getStatusColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}