import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../providers/penjualan_harian_provider.dart';
import '../models/penjualan_harian_model.dart';
import '../services/penjualan_harian_service.dart';

class LaporanPenjualanScreen extends StatefulWidget {
  const LaporanPenjualanScreen({super.key});

  @override
  State<LaporanPenjualanScreen> createState() => _LaporanPenjualanScreenState();
}

class _LaporanPenjualanScreenState extends State<LaporanPenjualanScreen> {
  final PenjualanHarianService _penjualanService = PenjualanHarianService();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _monthFormat = DateFormat('MMMM yyyy', 'id_ID');
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedPeriod = 'Semua';
  String _selectedJenisSayur = 'Semua';
  String _selectedStatus = 'Semua';
  
  Map<String, dynamic> _statistik = {};
  List<Map<String, dynamic>> _topProducts = [];
  List<PenjualanHarianModel> _penjualanList = [];
  bool _isLoading = false;
  bool _isLoadingStats = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Set default to current month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    _selectedPeriod = 'Bulan Ini';
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() async {
    if (_startDate == null || _endDate == null) return;
    
    setState(() {
      _isLoading = true;
      _isLoadingStats = true;
      _errorMessage = null;
    });
    
    try {
      // Load sales data
      final penjualanData = await _penjualanService.getPenjualanByDateRange(_startDate!, _endDate!);
      
      // Load statistics
      final statistikData = await _penjualanService.getStatistikPenjualan(_startDate!, _endDate!);
      
      // Load top products
      final topProductsData = await _penjualanService.getTopSellingProducts(_startDate!, _endDate!, limit: 10);
      
      setState(() {
        _penjualanList = penjualanData;
        _statistik = statistikData;
        _topProducts = topProductsData;
        _isLoading = false;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showAnalyticsDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePDF,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Header Section with Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.blue.shade600, Colors.blue.shade50],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                      child: Column(
                        children: [
                          // Period Display
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  'Periode: ${_startDate != null ? _dateFormat.format(_startDate!) : ''} - ${_endDate != null ? _dateFormat.format(_endDate!) : ''}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Summary Cards
                          _buildSummaryCards(),
                        ],
                      ),
                    ),
                    
                    // Active Filters
                    if (_hasActiveFilters())
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: _buildActiveFilters(),
                      ),
                  ],
                ),
              ),
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    labelColor: Colors.blue.shade600,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blue.shade600,
                    tabs: const [
                      Tab(text: 'Ringkasan', icon: Icon(Icons.dashboard)),
                      Tab(text: 'Detail Transaksi', icon: Icon(Icons.list)),
                      Tab(text: 'Produk Terlaris', icon: Icon(Icons.trending_up)),
                    ],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildSummaryTab(),
              _buildTransactionTab(),
              _buildTopProductsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Penjualan',
            _isLoadingStats ? '...' : _currencyFormat.format(_statistik['total_penjualan'] ?? 0),
            Icons.attach_money,
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            'Total Transaksi',
            _isLoadingStats ? '...' : '${_statistik['total_transaksi'] ?? 0}',
            Icons.receipt,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            'Rata-rata',
            _isLoadingStats ? '...' : _currencyFormat.format(_statistik['rata_rata_per_transaksi'] ?? 0),
            Icons.analytics,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedPeriod != 'Semua' ||
           _selectedJenisSayur != 'Semua' ||
           _selectedStatus != 'Semua';
  }

  Widget _buildActiveFilters() {
    return Wrap(
      spacing: 8,
      children: [
        if (_selectedPeriod != 'Semua')
          Chip(
            label: Text('Periode: $_selectedPeriod'),
            onDeleted: () => setState(() => _selectedPeriod = 'Semua'),
            deleteIcon: const Icon(Icons.close, size: 16),
          ),
        if (_selectedJenisSayur != 'Semua')
          Chip(
            label: Text('Sayur: $_selectedJenisSayur'),
            onDeleted: () => setState(() => _selectedJenisSayur = 'Semua'),
            deleteIcon: const Icon(Icons.close, size: 16),
          ),
        if (_selectedStatus != 'Semua')
          Chip(
            label: Text('Status: $_selectedStatus'),
            onDeleted: () => setState(() => _selectedStatus = 'Semua'),
            deleteIcon: const Icon(Icons.close, size: 16),
          ),
        TextButton(
          onPressed: () {
            setState(() {
              _selectedPeriod = 'Semua';
              _selectedJenisSayur = 'Semua';
              _selectedStatus = 'Semua';
            });
          },
          child: const Text('Hapus Semua Filter'),
        ),
      ],
    );
  }

  Widget _buildSummaryTab() {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return _buildErrorWidget(_errorMessage!);
    }
    
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Revenue Chart Placeholder
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ringkasan Penjualan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatItem('Total Penjualan', _currencyFormat.format(_statistik['total_penjualan'] ?? 0)),
                  _buildStatItem('Total Transaksi', '${_statistik['total_transaksi'] ?? 0} transaksi'),
                  _buildStatItem('Rata-rata per Transaksi', _currencyFormat.format(_statistik['rata_rata_per_transaksi'] ?? 0)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Top Vegetables
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sayuran Terlaris',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_statistik['sayur_total_penjualan'] != null)
                    ...(_statistik['sayur_total_penjualan'] as Map<String, double>)
                        .entries
                        .take(5)
                        .map((entry) => _buildStatItem(
                              entry.key,
                              _currencyFormat.format(entry.value),
                            )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Customer Analysis
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analisis Pelanggan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatItem('Total Pelanggan Aktif', '${(_statistik['pelanggan_count'] as Map<String, int>?)?.length ?? 0} pelanggan'),
                  if (_statistik['pelanggan_total'] != null)
                    ...(_statistik['pelanggan_total'] as Map<String, double>)
                        .entries
                        .take(3)
                        .map((entry) => Consumer<PenjualanHarianProvider>(
                              builder: (context, provider, child) {
                                final pelangganName = provider.getPelangganName(entry.key);
                                return _buildStatItem(
                                  pelangganName.isNotEmpty ? pelangganName : 'Pelanggan ${entry.key}',
                                  _currencyFormat.format(entry.value),
                                );
                              },
                            )),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildTransactionTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return _buildErrorWidget(_errorMessage!);
    }
    
    List<PenjualanHarianModel> filteredData = _getFilteredData();
    
    if (filteredData.isEmpty) {
      return _buildEmptyWidget();
    }
    
    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header dengan informasi total
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total ${filteredData.length} transaksi',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _currencyFormat.format(
                          filteredData.fold<double>(
                            0,
                            (sum, item) => sum + item.totalHarga,
                          ),
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // List transaksi
              ...filteredData.map((penjualan) => _buildTransactionCard(penjualan)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopProductsTab() {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return _buildErrorWidget(_errorMessage!);
    }
    
    if (_topProducts.isEmpty) {
      return _buildEmptyWidget();
    }
    
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: _topProducts.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            return _buildProductCard(product, index + 1);
          }).toList(),
        ),
      ),
    );
  }

  List<PenjualanHarianModel> _getFilteredData() {
    List<PenjualanHarianModel> data = _penjualanList;
    
    // Filter by jenis sayur
    if (_selectedJenisSayur != 'Semua') {
      data = data.where((item) => item.jenisSayur == _selectedJenisSayur).toList();
    }
    
    // Filter by status
    if (_selectedStatus != 'Semua') {
      data = data.where((item) => item.statusKirim == _selectedStatus).toList();
    }
    
    return data;
  }

  Widget _buildTransactionCard(PenjualanHarianModel penjualan) {
    final statusColor = _getStatusColor(penjualan.statusKirim);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: () => _showDetailDialog(penjualan),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          penjualan.jenisSayur,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Consumer<PenjualanHarianProvider>(
                          builder: (context, provider, child) {
                            final pelangganName = provider.getPelangganName(penjualan.idPelanggan);
                            return Text(
                              pelangganName.isNotEmpty ? pelangganName : 'Pelanggan ${penjualan.idPelanggan}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      _getStatusDisplayName(penjualan.statusKirim),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Details
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jumlah: ${penjualan.formattedJumlah}',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        ),
                        Text(
                          'Harga: ${_currencyFormat.format(penjualan.hargaPerSatuan)}/${penjualan.satuan}',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _currencyFormat.format(penjualan.totalHarga),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade600,
                    ),
                  ),
                ],
              ),
              
              // Date
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _dateFormat.format(penjualan.tanggalJual),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Oleh: ${penjualan.dicatatOleh}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, int rank) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getRankColor(rank),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['jenis_sayur'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Terjual: ${(product['total_quantity'] as double).toStringAsFixed(1)} unit',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Revenue
            Text(
              _currencyFormat.format(product['total_revenue']),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade400;
      default:
        return Colors.blue.shade400;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'dikirim':
        return Colors.blue;
      case 'selesai':
        return Colors.green;
      case 'batal':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'dikirim':
        return 'Dikirim';
      case 'selesai':
        return 'Selesai';
      case 'batal':
        return 'Batal';
      default:
        return status;
    }
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada data penjualan',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah filter atau rentang tanggal',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Terjadi kesalahan',
            style: TextStyle(
              fontSize: 16,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter Laporan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Period Filter
                DropdownButtonFormField<String>(
                  value: _selectedPeriod,
                  decoration: const InputDecoration(
                    labelText: 'Periode',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'Semua',
                    'Hari Ini',
                    'Minggu Ini',
                    'Bulan Ini',
                    'Bulan Lalu',
                    'Custom',
                  ].map((period) => DropdownMenuItem(
                    value: period,
                    child: Text(period),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPeriod = value ?? 'Semua';
                      _updateDateRange();
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Custom Date Range
                if (_selectedPeriod == 'Custom') ...[
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
                            text: _startDate != null ? _dateFormat.format(_startDate!) : '',
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _startDate = date;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal Selesai',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          controller: TextEditingController(
                            text: _endDate != null ? _dateFormat.format(_endDate!) : '',
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _endDate = date;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Jenis Sayur Filter
                Consumer<PenjualanHarianProvider>(builder: (context, provider, child) {
                  final jenisSayurList = _getUniqueJenisSayur();
                  
                  return DropdownButtonFormField<String>(
                    value: _selectedJenisSayur,
                    decoration: const InputDecoration(
                      labelText: 'Jenis Sayur',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: 'Semua', child: Text('Semua Sayur')),
                      ...jenisSayurList.map(
                        (sayur) => DropdownMenuItem(
                          value: sayur,
                          child: Text(sayur),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedJenisSayur = value ?? 'Semua';
                      });
                    },
                  );
                }),
                const SizedBox(height: 16),
                
                // Status Filter
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'Semua',
                    'pending',
                    'dikirim',
                    'selesai',
                    'batal',
                  ].map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status == 'Semua' ? status : _getStatusDisplayName(status)),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value ?? 'Semua';
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedPeriod = 'Semua';
                  _selectedJenisSayur = 'Semua';
                  _selectedStatus = 'Semua';
                  _updateDateRange();
                });
              },
              child: const Text('Reset'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {});
                _loadData();
              },
              child: const Text('Terapkan'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateDateRange() {
    final now = DateTime.now();
    
    switch (_selectedPeriod) {
      case 'Hari Ini':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'Minggu Ini':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        _startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'Bulan Ini':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 'Bulan Lalu':
        _startDate = DateTime(now.year, now.month - 1, 1);
        _endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case 'Semua':
        _startDate = DateTime(2020, 1, 1);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
    }
  }

  List<String> _getUniqueJenisSayur() {
    final jenisSayurSet = _penjualanList
        .map((item) => item.jenisSayur)
        .toSet()
        .toList();
    jenisSayurSet.sort();
    return jenisSayurSet;
  }

  void _showAnalyticsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analisis Penjualan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ringkasan Periode',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildStatItem('Total Penjualan', _currencyFormat.format(_statistik['total_penjualan'] ?? 0)),
              _buildStatItem('Total Transaksi', '${_statistik['total_transaksi'] ?? 0}'),
              _buildStatItem('Rata-rata per Transaksi', _currencyFormat.format(_statistik['rata_rata_per_transaksi'] ?? 0)),
              
              const SizedBox(height: 16),
              Text(
                'Produk Terlaris',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (_topProducts.isNotEmpty)
                ..._topProducts.take(5).map((product) {
                  return _buildStatItem(
                    product['jenis_sayur'],
                    _currencyFormat.format(product['total_revenue']),
                  );
                }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(PenjualanHarianModel penjualan) {
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Detail Penjualan'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailItem('Tanggal Jual', _dateFormat.format(penjualan.tanggalJual)),
                  _buildDetailItem('Jenis Sayur', penjualan.jenisSayur ?? 'Tidak diketahui'),
                  Consumer<PenjualanHarianProvider>(
                    builder: (context, provider, child) {
                      try {
                        final pelangganName = provider.getPelangganName(penjualan.idPelanggan);
                        return _buildDetailItem(
                          'Pelanggan',
                          pelangganName.isNotEmpty ? pelangganName : 'Pelanggan ${penjualan.idPelanggan}',
                        );
                      } catch (e) {
                        return _buildDetailItem('Pelanggan', 'Pelanggan ${penjualan.idPelanggan}');
                      }
                    },
                  ),
                  _buildDetailItem('Jumlah', penjualan.formattedJumlah ?? '0'),
                  _buildDetailItem('Harga per Satuan', _currencyFormat.format(penjualan.hargaPerSatuan ?? 0)),
                  _buildDetailItem('Total Harga', _currencyFormat.format(penjualan.totalHarga ?? 0)),
                  _buildDetailItem('Status', _getStatusDisplayName(penjualan.statusKirim ?? 'pending')),
                  if (penjualan.catatan != null && penjualan.catatan!.isNotEmpty)
                    _buildDetailItem('Catatan', penjualan.catatan!),
                  _buildDetailItem('Dicatat Oleh', penjualan.dicatatOleh ?? 'Tidak diketahui'),
                  _buildDetailItem('Dicatat Pada', DateFormat('dd/MM/yyyy HH:mm').format(penjualan.dicatatPada)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error menampilkan detail: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDetailItem(String label, String value) {
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

  Future<void> _generatePDF() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Membuat PDF...'),
            ],
          ),
        ),
      );

      final pdf = pw.Document();
      final filteredData = _getFilteredData();
      
      // Add pages to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Text(
                  'LAPORAN PENJUALAN',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Period info
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  'Periode: ${_startDate != null ? _dateFormat.format(_startDate!) : ''} - ${_endDate != null ? _dateFormat.format(_endDate!) : ''}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
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
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Transaksi:'),
                        pw.Text('${filteredData.length}'),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Penjualan:'),
                        pw.Text(_currencyFormat.format(
                          filteredData.fold<double>(0, (sum, item) => sum + item.totalHarga),
                        )),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Rata-rata per Transaksi:'),
                        pw.Text(_currencyFormat.format(
                          filteredData.isNotEmpty
                              ? filteredData.fold<double>(0, (sum, item) => sum + item.totalHarga) / filteredData.length
                              : 0,
                        )),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Transaction table
              pw.Text(
                'DETAIL TRANSAKSI',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(2),
                  5: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Tanggal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Jenis Sayur', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Jumlah', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Harga/Unit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
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
                  // Data rows
                  ...filteredData.map((penjualan) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(_dateFormat.format(penjualan.tanggalJual)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(penjualan.jenisSayur),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(penjualan.formattedJumlah),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(_currencyFormat.format(penjualan.hargaPerSatuan)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(_currencyFormat.format(penjualan.totalHarga)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(_getStatusDisplayName(penjualan.statusKirim)),
                      ),
                    ],
                  )),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              // Footer
              pw.Text(
                'Dibuat pada: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ];
          },
        ),
      );

      // Save PDF
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'laporan_penjualan_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('PDF Berhasil Dibuat'),
          content: Text('File disimpan di: ${file.path}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                OpenFile.open(file.path);
              },
              child: const Text('Buka PDF'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog if open
      Navigator.of(context).pop();
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Gagal membuat PDF: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}