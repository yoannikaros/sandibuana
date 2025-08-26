import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../providers/rekap_pupuk_mingguan_provider.dart';
import '../models/rekap_pupuk_mingguan_model.dart';

class RekapPupukMingguanScreen extends StatefulWidget {
  const RekapPupukMingguanScreen({super.key});

  @override
  State<RekapPupukMingguanScreen> createState() => _RekapPupukMingguanScreenState();
}

class _RekapPupukMingguanScreenState extends State<RekapPupukMingguanScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialize Indonesian locale for DateFormat
    initializeDateFormatting('id_ID', null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    try {
      final provider = Provider.of<RekapPupukMingguanProvider>(context, listen: false);
      await provider.initialize();
      await provider.loadStatistik();
    } catch (e) {
      print('Error initializing rekap pupuk data: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Pupuk Mingguan'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showAnalyticsDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPDF,
            tooltip: 'Export ke PDF',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<RekapPupukMingguanProvider>(context, listen: false).refresh();
            },
          ),
        ]
      ),
      body: Consumer<RekapPupukMingguanProvider>(builder: (context, provider, child) {
        if (!provider.isInitialized && provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Search and Summary Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.green.shade600, Colors.green.shade50],
                  stops: const [0.0, 1.0],
                ),
              ),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari berdasarkan tandon, pupuk, atau catatan...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                provider.setSearchQuery('');
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
                    onChanged: provider.setSearchQuery,
                  ),
                  const SizedBox(height: 16),
                  
                  // Summary Cards
                  _buildSummaryCards(provider),
                ],
              ),
            ),
            
            // Active Filters
            if (_hasActiveFilters(provider))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildActiveFilters(provider),
              ),
            
            // Data List
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.error != null
                      ? _buildErrorWidget(provider.error!)
                      : provider.rekapList.isEmpty
                          ? _buildEmptyWidget()
                          : _buildDataList(provider),
            ),
          ],
        );
      }),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Scroll to top button
          Consumer<RekapPupukMingguanProvider>(
            builder: (context, provider, child) {
              if (provider.rekapList.length > 5) {
                return FloatingActionButton.small(
                  onPressed: () {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                  backgroundColor: Colors.grey.shade600,
                  child: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 8),
          // Add button
          FloatingActionButton(
            onPressed: () => _showAddDialog(context),
            backgroundColor: Colors.green.shade600,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(RekapPupukMingguanProvider provider) {
    final stats = provider.statistik;
    
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Rekap',
            '${stats['totalRecaps'] ?? 0}',
            Icons.list_alt,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            'Indikasi Bocor',
            '${stats['leakRecaps'] ?? 0}',
            Icons.warning,
            Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            'Normal',
            '${stats['normalRecaps'] ?? 0}',
            Icons.check_circle,
            Colors.green,
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

  bool _hasActiveFilters(RekapPupukMingguanProvider provider) {
    return provider.selectedTandonId.isNotEmpty ||
           provider.selectedPupukId.isNotEmpty ||
           provider.startDate != null ||
           provider.endDate != null ||
           provider.filterLeakOnly != null;
  }

  Widget _buildActiveFilters(RekapPupukMingguanProvider provider) {
    return Wrap(
      spacing: 8,
      children: [
        if (provider.selectedTandonId.isNotEmpty)
          Chip(
            label: Text('Tandon: ${provider.getTandonName(provider.selectedTandonId)}'),
            onDeleted: () => provider.setTandonFilter(''),
            deleteIcon: const Icon(Icons.close, size: 16),
          ),
        if (provider.selectedPupukId.isNotEmpty)
          Chip(
            label: Text('Pupuk: ${provider.getPupukName(provider.selectedPupukId)}'),
            onDeleted: () => provider.setPupukFilter(''),
            deleteIcon: const Icon(Icons.close, size: 16),
          ),
        if (provider.startDate != null || provider.endDate != null)
          Chip(
            label: Text(
              'Tanggal: ${provider.startDate != null ? _dateFormat.format(provider.startDate!) : ''} - ${provider.endDate != null ? _dateFormat.format(provider.endDate!) : ''}'
            ),
            onDeleted: () => provider.setDateRangeFilter(null, null),
            deleteIcon: const Icon(Icons.close, size: 16),
          ),
        if (provider.filterLeakOnly != null)
          Chip(
            label: Text(provider.filterLeakOnly! ? 'Hanya Bocor' : 'Hanya Normal'),
            onDeleted: () => provider.setLeakFilter(null),
            deleteIcon: const Icon(Icons.close, size: 16),
          ),
        TextButton(
          onPressed: provider.clearFilters,
          child: const Text('Hapus Semua Filter'),
        ),
      ],
    );
  }

  Widget _buildDataList(RekapPupukMingguanProvider provider) {
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: provider.rekapList.map((rekap) => _buildRekapCard(rekap, provider)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRekapCard(RekapPupukMingguanModel rekap, RekapPupukMingguanProvider provider) {
    final statusColor = _getStatusColor(rekap);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: () => _showDetailDialog(context, rekap, provider),
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
                          provider.getTandonName(rekap.idTandon),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          provider.getPupukName(rekap.idPupuk),
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
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      rekap.getStatusText(),
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
              
              // Period
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    rekap.getWeekRangeText(),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Usage Info
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Digunakan',
                      '${rekap.jumlahDigunakan.toStringAsFixed(2)} ${rekap.satuan}',
                      Icons.water_drop,
                    ),
                  ),
                  if (rekap.jumlahSeharusnya != null)
                    Expanded(
                      child: _buildInfoItem(
                        'Seharusnya',
                        '${rekap.jumlahSeharusnya!.toStringAsFixed(2)} ${rekap.satuan}',
                        Icons.rule,
                      ),
                    ),
                  if (rekap.selisih != null)
                    Expanded(
                      child: _buildInfoItem(
                        'Selisih',
                        '${rekap.selisih! >= 0 ? '+' : ''}${rekap.selisih!.toStringAsFixed(2)} ${rekap.satuan}',
                        Icons.compare_arrows,
                        color: rekap.selisih! >= 0 ? Colors.red : Colors.green,
                      ),
                    ),
                ],
              ),
              
              // Notes
              if (rekap.catatan != null && rekap.catatan!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  rekap.catatan!,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              
              // Footer
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dicatat: ${_dateTimeFormat.format(rekap.dicatatPada)}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16),
                        onPressed: () => _showEditDialog(context, rekap, provider),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                        onPressed: () => _showDeleteConfirmation(context, rekap, provider),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey.shade600),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(RekapPupukMingguanModel rekap) {
    if (rekap.indikasiBocor == true) return Colors.red;
    if ((rekap.selisih?.abs() ?? 0) > 0) return Colors.orange;
    return Colors.green;
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.eco_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada data rekap pupuk mingguan',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap tombol + untuk menambah data baru',
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
            onPressed: () {
              Provider.of<RekapPupukMingguanProvider>(context, listen: false).refresh();
            },
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    final provider = Provider.of<RekapPupukMingguanProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Data'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tandon Filter
              DropdownButtonFormField<String>(
                value: provider.selectedTandonId.isEmpty ? null : provider.selectedTandonId,
                decoration: const InputDecoration(
                  labelText: 'Tandon',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Semua Tandon')),
                  ...provider.tandonList.map((tandon) => DropdownMenuItem(
                    value: tandon.id,
                    child: Text(tandon.namaTandon ?? ''),
                  )),
                ],
                onChanged: (value) => provider.setTandonFilter(value ?? ''),
              ),
              const SizedBox(height: 16),
              
              // Pupuk Filter
              DropdownButtonFormField<String>(
                value: provider.selectedPupukId.isEmpty ? null : provider.selectedPupukId,
                decoration: const InputDecoration(
                  labelText: 'Jenis Pupuk',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Semua Pupuk')),
                  ...provider.pupukList.map((pupuk) => DropdownMenuItem(
                    value: pupuk.id,
                    child: Text(pupuk.namaPupuk),
                  )),
                ],
                onChanged: (value) => provider.setPupukFilter(value ?? ''),
              ),
              const SizedBox(height: 16),
              
              // Leak Filter
              DropdownButtonFormField<bool?>(
                value: provider.filterLeakOnly,
                decoration: const InputDecoration(
                  labelText: 'Status Kebocoran',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Semua Status')),
                  DropdownMenuItem(value: true, child: Text('Hanya Indikasi Bocor')),
                  DropdownMenuItem(value: false, child: Text('Hanya Normal')),
                ],
                onChanged: provider.setLeakFilter,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.clearFilters();
              Navigator.of(context).pop();
            },
            child: const Text('Reset'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showAnalyticsDialog(BuildContext context) {
    final provider = Provider.of<RekapPupukMingguanProvider>(context, listen: false);
    final stats = provider.statistik;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analisis Data'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ringkasan Keseluruhan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildAnalyticsItem('Total Rekap', '${stats['totalRecaps'] ?? 0}'),
              _buildAnalyticsItem('Indikasi Bocor', '${stats['leakRecaps'] ?? 0}'),
              _buildAnalyticsItem('Persentase Bocor', '${(stats['leakPercentage'] ?? 0).toStringAsFixed(1)}%'),
              _buildAnalyticsItem('Total Pupuk Digunakan', '${(stats['totalFertilizerUsed'] ?? 0).toStringAsFixed(2)} L'),
              _buildAnalyticsItem('Rata-rata Penggunaan', '${(stats['averageUsage'] ?? 0).toStringAsFixed(2)} L'),
              
              const SizedBox(height: 16),
              Text(
                'Berdasarkan Tandon',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (stats['byTandon'] != null)
                ...((stats['byTandon'] as Map).entries.take(5).map((entry) {
                  final tandonName = provider.getTandonName(entry.key);
                  final data = entry.value as Map;
                  return _buildAnalyticsItem(
                    tandonName,
                    '${data['count']} rekap, ${data['leakCount']} bocor',
                  );
                })),
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

  void _showAddDialog(BuildContext context) {
    _showRekapDialog(context, null);
  }

  void _showEditDialog(BuildContext context, RekapPupukMingguanModel rekap, RekapPupukMingguanProvider provider) {
    _showRekapDialog(context, rekap);
  }

  void _showRekapDialog(BuildContext context, RekapPupukMingguanModel? rekap) {
    final provider = Provider.of<RekapPupukMingguanProvider>(context, listen: false);
    final isEdit = rekap != null;
    
    final tanggalMulaiController = TextEditingController(
      text: isEdit ? _dateFormat.format(rekap.tanggalMulai) : '',
    );
    final tanggalSelesaiController = TextEditingController(
      text: isEdit ? _dateFormat.format(rekap.tanggalSelesai) : '',
    );
    final jumlahController = TextEditingController(
      text: isEdit ? rekap.jumlahDigunakan.toString() : '',
    );
    final catatanController = TextEditingController(
      text: isEdit ? (rekap.catatan ?? '') : '',
    );
    
    String selectedTandonId = isEdit ? rekap.idTandon : '';
    String selectedPupukId = isEdit ? rekap.idPupuk : '';
    String selectedSatuan = isEdit ? rekap.satuan : 'liter';
    DateTime? tanggalMulai = isEdit ? rekap.tanggalMulai : null;
    DateTime? tanggalSelesai = isEdit ? rekap.tanggalSelesai : null;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit Rekap Pupuk' : 'Tambah Rekap Pupuk'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tanggal Mulai
                TextFormField(
                  controller: tanggalMulaiController,
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Mulai',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: tanggalMulai ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        tanggalMulai = date;
                        tanggalMulaiController.text = _dateFormat.format(date);
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Tanggal Selesai
                TextFormField(
                  controller: tanggalSelesaiController,
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Selesai',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: tanggalSelesai ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        tanggalSelesai = date;
                        tanggalSelesaiController.text = _dateFormat.format(date);
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Tandon
                DropdownButtonFormField<String>(
                  value: selectedTandonId.isEmpty ? null : selectedTandonId,
                  decoration: const InputDecoration(
                    labelText: 'Tandon',
                    border: OutlineInputBorder(),
                  ),
                  items: provider.tandonList.map((tandon) => DropdownMenuItem(
                    value: tandon.id,
                    child: Text(tandon.namaTandon ?? ''),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedTandonId = value ?? '';
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Pupuk
                DropdownButtonFormField<String>(
                  value: selectedPupukId.isEmpty ? null : selectedPupukId,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Pupuk',
                    border: OutlineInputBorder(),
                  ),
                  items: provider.pupukList.map((pupuk) => DropdownMenuItem(
                    value: pupuk.id,
                    child: Text(pupuk.namaPupuk),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedPupukId = value ?? '';
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Jumlah dan Satuan
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: jumlahController,
                        decoration: const InputDecoration(
                          labelText: 'Jumlah Digunakan',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedSatuan,
                        decoration: const InputDecoration(
                          labelText: 'Satuan',
                          border: OutlineInputBorder(),
                        ),
                        items: RekapPupukMingguanModel.getSatuanOptions()
                            .map((satuan) => DropdownMenuItem(
                                  value: satuan,
                                  child: Text(satuan),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedSatuan = value ?? 'liter';
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Catatan
                TextFormField(
                  controller: catatanController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (Opsional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (tanggalMulai == null || tanggalSelesai == null ||
                    selectedTandonId.isEmpty || selectedPupukId.isEmpty ||
                    jumlahController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mohon lengkapi semua field yang wajib diisi'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                final jumlah = double.tryParse(jumlahController.text);
                if (jumlah == null || jumlah < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Jumlah harus berupa angka positif'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                final newRekap = provider.createRekapWithCalculations(
                  tanggalMulai: tanggalMulai!,
                  tanggalSelesai: tanggalSelesai!,
                  idTandon: selectedTandonId,
                  idPupuk: selectedPupukId,
                  jumlahDigunakan: jumlah,
                  satuan: selectedSatuan,
                  catatan: catatanController.text.isEmpty ? null : catatanController.text,
                );
                
                bool success;
                if (isEdit) {
                  success = await provider.updateRekapPupukMingguan(
                    rekap.id,
                    newRekap.copyWith(id: rekap.id),
                  );
                } else {
                  success = await provider.tambahRekapPupukMingguan(newRekap);
                }
                
                if (success) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEdit ? 'Rekap berhasil diupdate' : 'Rekap berhasil ditambahkan'),
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
              },
              child: Text(isEdit ? 'Update' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, RekapPupukMingguanModel rekap, RekapPupukMingguanProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Rekap Pupuk'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('Periode', rekap.getWeekRangeText()),
              _buildDetailItem('Tandon', provider.getTandonName(rekap.idTandon)),
              _buildDetailItem('Jenis Pupuk', provider.getPupukName(rekap.idPupuk)),
              _buildDetailItem('Jumlah Digunakan', '${rekap.jumlahDigunakan.toStringAsFixed(2)} ${rekap.satuan}'),
              if (rekap.jumlahSeharusnya != null)
                _buildDetailItem('Jumlah Seharusnya', '${rekap.jumlahSeharusnya!.toStringAsFixed(2)} ${rekap.satuan}'),
              if (rekap.selisih != null)
                _buildDetailItem(
                  'Selisih',
                  '${rekap.selisih! >= 0 ? '+' : ''}${rekap.selisih!.toStringAsFixed(2)} ${rekap.satuan}',
                  color: rekap.selisih! >= 0 ? Colors.red : Colors.green,
                ),
              _buildDetailItem('Status', rekap.getStatusText(), color: _getStatusColor(rekap)),
              if (rekap.catatan != null && rekap.catatan!.isNotEmpty)
                _buildDetailItem('Catatan', rekap.catatan!),
              _buildDetailItem('Dicatat Pada', _dateTimeFormat.format(rekap.dicatatPada)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditDialog(context, rekap, provider);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? color}) {
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
            child: Text(
              value,
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, RekapPupukMingguanModel rekap, RekapPupukMingguanProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Apakah Anda yakin ingin menghapus rekap pupuk untuk ${provider.getTandonName(rekap.idTandon)} periode ${rekap.getWeekRangeText()}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final success = await provider.hapusRekapPupukMingguan(rekap.id);
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rekap berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(provider.error ?? 'Gagal menghapus rekap'),
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
      final provider = Provider.of<RekapPupukMingguanProvider>(context, listen: false);
      
      if (provider.rekapList.isEmpty) {
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
                      'LAPORAN REKAP PUPUK MINGGUAN',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                       'Tanggal Cetak: ${dateFormat.format(now)}',
                       style: const pw.TextStyle(fontSize: 12),
                     ),
                     pw.SizedBox(height: 4),
                     pw.Text(
                       'Total Data: ${provider.rekapList.length} rekap',
                       style: const pw.TextStyle(fontSize: 12),
                     ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Summary Statistics
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
                         pw.Text('Total Rekap: ${provider.rekapList.length}'),
                         pw.Text('Indikasi Bocor: ${provider.statistik['leakRecaps'] ?? 0}'),
                         pw.Text('Normal: ${provider.statistik['normalRecaps'] ?? 0}'),
                       ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Data Table
              pw.Text(
                'DETAIL DATA REKAP',
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
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1),
                  4: const pw.FlexColumnWidth(1),
                  5: const pw.FlexColumnWidth(1),
                  6: const pw.FlexColumnWidth(1.5),
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
                          'Tandon',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Pupuk',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Digunakan',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Seharusnya',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Status',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Periode',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  // Data rows
                  ...provider.rekapList.asMap().entries.map(
                    (entry) {
                      final index = entry.key;
                      final rekap = entry.value;
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
                              provider.getTandonName(rekap.idTandon),
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              provider.getPupukName(rekap.idPupuk),
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                               '${rekap.jumlahDigunakan.toStringAsFixed(1)} ${rekap.satuan}',
                               textAlign: pw.TextAlign.center,
                               style: const pw.TextStyle(fontSize: 9),
                             ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                               rekap.jumlahSeharusnya != null ? '${rekap.jumlahSeharusnya!.toStringAsFixed(1)} ${rekap.satuan}' : '-',
                               textAlign: pw.TextAlign.center,
                               style: const pw.TextStyle(fontSize: 9),
                             ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              rekap.getStatusText(),
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              rekap.getWeekRangeText(),
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ];
          },
        ),
      );

      // Save PDF file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'rekap_pupuk_mingguan_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf';
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