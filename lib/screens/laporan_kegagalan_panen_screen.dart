import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../providers/kegagalan_panen_provider.dart';
import '../models/kegagalan_panen_model.dart';
import '../models/penanaman_sayur_model.dart';

class LaporanKegagalanPanenScreen extends StatefulWidget {
  const LaporanKegagalanPanenScreen({super.key});

  @override
  State<LaporanKegagalanPanenScreen> createState() => _LaporanKegagalanPanenScreenState();
}

class _LaporanKegagalanPanenScreenState extends State<LaporanKegagalanPanenScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  final ScrollController _scrollController = ScrollController();
  
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedJenisKegagalan = 'Semua';
  String _selectedLokasi = 'Semua';
  String _searchQuery = '';
  
  Map<String, dynamic> _statistik = {};
  bool _isLoadingStatistik = false;

  @override
  void initState() {
    super.initState();
    // Initialize Indonesian locale for DateFormat
    initializeDateFormatting('id_ID', null);
    // Set default date range (last 30 days)
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadData() {
    final provider = Provider.of<KegagalanPanenProvider>(context, listen: false);
    if (_startDate != null && _endDate != null) {
      provider.loadKegagalanPanenByDateRange(_startDate!, _endDate!);
      _loadStatistik();
    }
  }

  void _loadStatistik() async {
    if (_startDate == null || _endDate == null) return;
    
    setState(() {
      _isLoadingStatistik = true;
    });
    
    try {
      final provider = Provider.of<KegagalanPanenProvider>(context, listen: false);
      final statistik = await provider.kegagalanPanenService.getRingkasanKegagalanPanen(
        _startDate!,
        _endDate!,
      );
      
      setState(() {
        _statistik = statistik;
        _isLoadingStatistik = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStatistik = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Kegagalan Panen'),
        backgroundColor: Colors.red.shade600,
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
            onPressed: _exportToPDF,
            tooltip: 'Export ke PDF',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Consumer<KegagalanPanenProvider>(builder: (context, provider, child) {
        return Column(
          children: [
            // Header Section with Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.red.shade600, Colors.red.shade50],
                  stops: const [0.0, 1.0],
                ),
              ),
              child: Column(
                children: [
                  // Date Range Display
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Periode: ${_startDate != null ? _dateFormat.format(_startDate!) : ''} - ${_endDate != null ? _dateFormat.format(_endDate!) : ''}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari berdasarkan jenis, penyebab, lokasi...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
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
                      setState(() {
                        _searchQuery = value;
                      });
                    },
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
            
            // Data List
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.errorMessage != null
                      ? _buildErrorWidget(provider.errorMessage!)
                      : _buildDataList(provider),
            ),
          ],
        );
      }),
      floatingActionButton: Consumer<KegagalanPanenProvider>(
        builder: (context, provider, child) {
          List<KegagalanPanenModel> filteredData = _getFilteredData(provider);
          if (filteredData.length > 5) {
            return FloatingActionButton(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              backgroundColor: Colors.red.shade600,
              child: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Kegagalan',
            _isLoadingStatistik ? '...' : '${_statistik['total_kegagalan'] ?? 0}',
            Icons.error_outline,
            Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            'Total Tanaman',
            _isLoadingStatistik ? '...' : '${_statistik['total_jumlah_gagal'] ?? 0}',
            Icons.grass,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            'Rata-rata',
            _isLoadingStatistik ? '...' : '${(_statistik['rata_rata_per_kejadian'] ?? 0).toStringAsFixed(1)}',
            Icons.analytics,
            Colors.blue,
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
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
    return _selectedJenisKegagalan != 'Semua' ||
           _selectedLokasi != 'Semua' ||
           _searchQuery.isNotEmpty;
  }

  Widget _buildActiveFilters() {
    return Wrap(
      spacing: 8,
      children: [
        if (_selectedJenisKegagalan != 'Semua')
          Chip(
            label: Text('Jenis: ${KegagalanPanenModel.getJenisKegagalanDisplayName(_selectedJenisKegagalan)}'),
            onDeleted: () => setState(() => _selectedJenisKegagalan = 'Semua'),
            deleteIcon: const Icon(Icons.close, size: 16),
          ),
        if (_selectedLokasi != 'Semua')
          Chip(
            label: Text('Lokasi: $_selectedLokasi'),
            onDeleted: () => setState(() => _selectedLokasi = 'Semua'),
            deleteIcon: const Icon(Icons.close, size: 16),
          ),
        if (_searchQuery.isNotEmpty)
          Chip(
            label: Text('Pencarian: $_searchQuery'),
            onDeleted: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
            deleteIcon: const Icon(Icons.close, size: 16),
          ),
        TextButton(
          onPressed: () {
            setState(() {
              _selectedJenisKegagalan = 'Semua';
              _selectedLokasi = 'Semua';
              _searchQuery = '';
              _searchController.clear();
            });
          },
          child: const Text('Hapus Semua Filter'),
        ),
      ],
    );
  }

  Widget _buildDataList(KegagalanPanenProvider provider) {
    List<KegagalanPanenModel> filteredData = _getFilteredData(provider);
    
    if (filteredData.isEmpty) {
      return _buildEmptyWidget();
    }
    
    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: filteredData.length,
          itemBuilder: (context, index) {
            final kegagalan = filteredData[index];
            return _buildKegagalanCard(kegagalan, provider);
          },
        ),
      ),
    );
  }

  List<KegagalanPanenModel> _getFilteredData(KegagalanPanenProvider provider) {
    List<KegagalanPanenModel> data = provider.kegagalanPanenList;
    
    // Filter by jenis kegagalan
    if (_selectedJenisKegagalan != 'Semua') {
      data = data.where((item) => item.jenisKegagalan == _selectedJenisKegagalan).toList();
    }
    
    // Filter by lokasi
    if (_selectedLokasi != 'Semua') {
      data = data.where((item) => item.lokasi == _selectedLokasi).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      data = data.where((item) {
        return item.jenisKegagalan.toLowerCase().contains(query) ||
               (item.penyebabGagal?.toLowerCase().contains(query) ?? false) ||
               (item.lokasi?.toLowerCase().contains(query) ?? false) ||
               (item.tindakanDiambil?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    return data;
  }

  Widget _buildKegagalanCard(KegagalanPanenModel kegagalan, KegagalanPanenProvider provider) {
    final jenisColor = _getJenisColor(kegagalan.jenisKegagalan);
    final penanaman = _getPenanamanInfo(kegagalan.idPenanaman, provider);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: jenisColor.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: () => _showDetailDialog(kegagalan, provider),
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
                          KegagalanPanenModel.getJenisKegagalanDisplayName(kegagalan.jenisKegagalan),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: jenisColor,
                          ),
                        ),
                        if (penanaman != null)
                          Text(
                            penanaman.jenisSayur,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: jenisColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: jenisColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${kegagalan.jumlahGagal} tanaman',
                      style: TextStyle(
                        color: jenisColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Date
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    _dateFormat.format(kegagalan.tanggalGagal),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
              
              // Location
              if (kegagalan.lokasi != null && kegagalan.lokasi!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      kegagalan.lokasi!,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ],
              
              // Cause
              if (kegagalan.penyebabGagal != null && kegagalan.penyebabGagal!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Penyebab: ${kegagalan.penyebabGagal}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
              
              // Action Taken
              if (kegagalan.tindakanDiambil != null && kegagalan.tindakanDiambil!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Tindakan: ${kegagalan.tindakanDiambil}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
              
              // Footer
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dicatat: ${_dateTimeFormat.format(kegagalan.dicatatPada)}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    'Oleh: ${kegagalan.dicatatOleh}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10,
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

  Color _getJenisColor(String jenis) {
    switch (jenis) {
      case 'busuk':
        return const Color(0xFF8B4513); // Brown
      case 'layu':
        return const Color(0xFFFF8C00); // Dark Orange
      case 'hama':
        return const Color(0xFFDC143C); // Crimson
      case 'penyakit':
        return const Color(0xFF9932CC); // Dark Orchid
      case 'cuaca':
        return const Color(0xFF4682B4); // Steel Blue
      case 'lainnya':
        return const Color(0xFF696969); // Dim Gray
      default:
        return const Color(0xFF808080); // Gray
    }
  }

  PenanamanSayurModel? _getPenanamanInfo(String idPenanaman, KegagalanPanenProvider provider) {
    try {
      return provider.penanamanSayurList.firstWhere(
        (penanaman) => penanaman.idPenanaman == idPenanaman,
      );
    } catch (e) {
      return null;
    }
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
            'Tidak ada data kegagalan panen',
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
                // Date Range
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
                
                // Jenis Kegagalan Filter
                DropdownButtonFormField<String>(
                  value: _selectedJenisKegagalan,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Kegagalan',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'Semua', child: Text('Semua Jenis')),
                    ...KegagalanPanenModel.getJenisKegagalanOptions().map(
                      (jenis) => DropdownMenuItem(
                        value: jenis,
                        child: Text(KegagalanPanenModel.getJenisKegagalanDisplayName(jenis)),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedJenisKegagalan = value ?? 'Semua';
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Lokasi Filter
                Consumer<KegagalanPanenProvider>(builder: (context, provider, child) {
                  final lokasiList = _getUniqueLocations(provider.kegagalanPanenList);
                  
                  return DropdownButtonFormField<String>(
                    value: _selectedLokasi,
                    decoration: const InputDecoration(
                      labelText: 'Lokasi',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: 'Semua', child: Text('Semua Lokasi')),
                      ...lokasiList.map(
                        (lokasi) => DropdownMenuItem(
                          value: lokasi,
                          child: Text(lokasi),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedLokasi = value ?? 'Semua';
                      });
                    },
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _startDate = DateTime.now().subtract(const Duration(days: 30));
                  _endDate = DateTime.now();
                  _selectedJenisKegagalan = 'Semua';
                  _selectedLokasi = 'Semua';
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

  List<String> _getUniqueLocations(List<KegagalanPanenModel> data) {
    final locations = data
        .where((item) => item.lokasi != null && item.lokasi!.isNotEmpty)
        .map((item) => item.lokasi!)
        .toSet()
        .toList();
    locations.sort();
    return locations;
  }

  void _showAnalyticsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analisis Kegagalan Panen'),
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
              _buildAnalyticsItem('Total Kejadian', '${_statistik['total_kegagalan'] ?? 0}'),
              _buildAnalyticsItem('Total Tanaman Gagal', '${_statistik['total_jumlah_gagal'] ?? 0}'),
              _buildAnalyticsItem('Rata-rata per Kejadian', '${(_statistik['rata_rata_per_kejadian'] ?? 0).toStringAsFixed(1)} tanaman'),
              
              const SizedBox(height: 16),
              Text(
                'Berdasarkan Jenis Kegagalan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (_statistik['jenis_kegagalan'] != null)
                ...(_statistik['jenis_kegagalan'] as Map<String, int>).entries.map((entry) {
                  final displayName = KegagalanPanenModel.getJenisKegagalanDisplayName(entry.key);
                  return _buildAnalyticsItem(displayName, '${entry.value} tanaman');
                }),
              
              const SizedBox(height: 16),
              Text(
                'Berdasarkan Lokasi',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (_statistik['lokasi_kegagalan'] != null)
                ...(_statistik['lokasi_kegagalan'] as Map<String, int>).entries.take(5).map((entry) {
                  return _buildAnalyticsItem(entry.key, '${entry.value} tanaman');
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

  Widget _buildAnalyticsItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
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

  void _showDetailDialog(KegagalanPanenModel kegagalan, KegagalanPanenProvider provider) {
    final penanaman = _getPenanamanInfo(kegagalan.idPenanaman, provider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Kegagalan Panen'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('Tanggal Gagal', _dateFormat.format(kegagalan.tanggalGagal)),
              _buildDetailItem('Jenis Kegagalan', KegagalanPanenModel.getJenisKegagalanDisplayName(kegagalan.jenisKegagalan)),
              if (penanaman != null)
                _buildDetailItem('Jenis Sayur', penanaman.jenisSayur),
              _buildDetailItem('Jumlah Gagal', '${kegagalan.jumlahGagal} tanaman'),
              if (kegagalan.penyebabGagal != null && kegagalan.penyebabGagal!.isNotEmpty)
                _buildDetailItem('Penyebab', kegagalan.penyebabGagal!),
              if (kegagalan.lokasi != null && kegagalan.lokasi!.isNotEmpty)
                _buildDetailItem('Lokasi', kegagalan.lokasi!),
              if (kegagalan.tindakanDiambil != null && kegagalan.tindakanDiambil!.isNotEmpty)
                _buildDetailItem('Tindakan Diambil', kegagalan.tindakanDiambil!),
              _buildDetailItem('Dicatat Oleh', kegagalan.dicatatOleh),
              _buildDetailItem('Dicatat Pada', _dateTimeFormat.format(kegagalan.dicatatPada)),
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

  Future<void> _exportToPDF() async {
    try {
      final provider = Provider.of<KegagalanPanenProvider>(context, listen: false);
      List<KegagalanPanenModel> filteredData = _getFilteredData(provider);
      
      if (filteredData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada data untuk diekspor'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

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
      final now = DateTime.now();
      final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
      
      // Create PDF content
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'LAPORAN KEGAGALAN PANEN',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Periode: ${_startDate != null ? _dateFormat.format(_startDate!) : ''} - ${_endDate != null ? _dateFormat.format(_endDate!) : ''}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Tanggal Cetak: ${dateFormat.format(now)}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Total Data: ${filteredData.length} kegagalan',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Summary Statistics
              if (_statistik.isNotEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'RINGKASAN STATISTIK',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total Kegagalan: ${_statistik['total_kegagalan'] ?? 0}'),
                          pw.Text('Total Tanaman Gagal: ${_statistik['total_jumlah_gagal'] ?? 0}'),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Rata-rata per Kejadian: ${(_statistik['rata_rata_per_kejadian'] ?? 0).toStringAsFixed(1)} tanaman'),
                    ],
                  ),
                ),
              
              pw.SizedBox(height: 20),
              
              // Data Table
              pw.Text(
                'DETAIL DATA KEGAGALAN PANEN',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              
              pw.SizedBox(height: 10),
              
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.5),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1),
                  4: const pw.FlexColumnWidth(1),
                  5: const pw.FlexColumnWidth(2),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'No',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Tanggal',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Jenis Kegagalan',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Jumlah',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Lokasi',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Penyebab & Tindakan',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  // Data rows
                  ...filteredData.asMap().entries.map(
                    (entry) {
                      final index = entry.key;
                      final kegagalan = entry.value;
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${index + 1}',
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              _dateFormat.format(kegagalan.tanggalGagal),
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              KegagalanPanenModel.getJenisKegagalanDisplayName(kegagalan.jenisKegagalan),
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${kegagalan.jumlahGagal}',
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              kegagalan.lokasi ?? '-',
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                if (kegagalan.penyebabGagal != null && kegagalan.penyebabGagal!.isNotEmpty)
                                  pw.Text(
                                    'Penyebab: ${kegagalan.penyebabGagal}',
                                    style: const pw.TextStyle(fontSize: 8),
                                  ),
                                if (kegagalan.tindakanDiambil != null && kegagalan.tindakanDiambil!.isNotEmpty)
                                  pw.Text(
                                    'Tindakan: ${kegagalan.tindakanDiambil}',
                                    style: const pw.TextStyle(fontSize: 8),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              // Distribution by Jenis Kegagalan
              if (_statistik['jenis_kegagalan'] != null)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DISTRIBUSI PER JENIS KEGAGALAN',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    
                    pw.SizedBox(height: 10),
                    
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey300),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(2),
                        1: const pw.FlexColumnWidth(1),
                      },
                      children: [
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.grey200,
                          ),
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                'Jenis Kegagalan',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                'Total Tanaman',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        ...(_statistik['jenis_kegagalan'] as Map<String, int>).entries.map(
                          (entry) => pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(KegagalanPanenModel.getJenisKegagalanDisplayName(entry.key)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(
                                  '${entry.value}',
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ];
          },
        ),
      );

      // Save PDF file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'laporan_kegagalan_panen_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success dialog with option to open file
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('PDF Berhasil Dibuat'),
          content: Text('File PDF telah disimpan sebagai:\n$fileName'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await OpenFile.open(file.path);
              },
              child: const Text('Buka PDF'),
            ),
          ],
        ),
      );

    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}