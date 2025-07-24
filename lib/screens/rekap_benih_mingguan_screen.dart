import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../models/rekap_benih_mingguan_model.dart';
import '../providers/rekap_benih_mingguan_provider.dart';

class RekapBenihMingguanScreen extends StatefulWidget {
  const RekapBenihMingguanScreen({Key? key}) : super(key: key);

  @override
  State<RekapBenihMingguanScreen> createState() => _RekapBenihMingguanScreenState();
}

class _RekapBenihMingguanScreenState extends State<RekapBenihMingguanScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final ScrollController _scrollController = ScrollController();

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
    final provider = Provider.of<RekapBenihMingguanProvider>(context, listen: false);
    
    await Future.wait([
      provider.loadRekapBenihMingguan(),
      provider.loadStatistics(),
    ]);
    
    // Initialize with default data if empty
    if (provider.rekapList.isEmpty) {
      await provider.initializeWithDefaultData();
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
        title: const Text('Rekap Benih Mingguan'),
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
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPDF,
            tooltip: 'Export ke PDF',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          _buildSummaryCards(),
          Expanded(
            child: Consumer<RekapBenihMingguanProvider>(
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

                if (provider.rekapList.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.eco_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada data rekap benih mingguan',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadRekapBenihMingguan(),
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: provider.rekapList.map((rekap) => _buildRekapCard(rekap)).toList(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Scroll to top button
          Consumer<RekapBenihMingguanProvider>(
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
                  backgroundColor: Colors.grey[600],
                  child: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 8),
          // Add button
          FloatingActionButton(
            onPressed: () => _showAddEditDialog(),
            backgroundColor: Colors.green[700],
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
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
              hintText: 'Cari jenis benih atau catatan...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        Provider.of<RekapBenihMingguanProvider>(context, listen: false)
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
              Provider.of<RekapBenihMingguanProvider>(context, listen: false)
                  .setSearchQuery(value);
            },
          ),
          const SizedBox(height: 8),
          Consumer<RekapBenihMingguanProvider>(
            builder: (context, provider, child) {
              final hasActiveFilters = provider.selectedJenisBenih != null ||
                  provider.startDate != null ||
                  provider.endDate != null;

              if (!hasActiveFilters) return const SizedBox.shrink();

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (provider.selectedJenisBenih != null)
                      _buildFilterChip(
                        'Jenis: ${provider.selectedJenisBenih}',
                        () => provider.setSelectedJenisBenih(null),
                      ),
                    if (provider.startDate != null)
                      _buildFilterChip(
                        'Dari: ${_dateFormat.format(provider.startDate!)}',
                        () => provider.setDateRange(null, provider.endDate),
                      ),
                    if (provider.endDate != null)
                      _buildFilterChip(
                        'Sampai: ${_dateFormat.format(provider.endDate!)}',
                        () => provider.setDateRange(provider.startDate, null),
                      ),
                    _buildFilterChip(
                      'Hapus Semua Filter',
                      () => provider.clearFilters(),
                      isAction: true,
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

  Widget _buildFilterChip(String label, VoidCallback onDeleted, {bool isAction = false}) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isAction ? Colors.red[700] : Colors.grey[700],
        ),
      ),
      deleteIcon: Icon(
        isAction ? Icons.clear_all : Icons.close,
        size: 16,
        color: isAction ? Colors.red[700] : Colors.grey[600],
      ),
      onDeleted: onDeleted,
      backgroundColor: isAction ? Colors.red[50] : Colors.grey[200],
    );
  }

  Widget _buildSummaryCards() {
    return Consumer<RekapBenihMingguanProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Rekap',
                  provider.rekapList.length.toString(),
                  Icons.list_alt,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  'Total Nampan',
                  provider.getTotalNampan().toString(),
                  Icons.eco,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  'Rata-rata',
                  provider.getAverageNampanPerRekap().toStringAsFixed(1),
                  Icons.analytics,
                  Colors.orange,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
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
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRekapCard(RekapBenihMingguanModel rekap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showDetailDialog(rekap),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: rekap.getJenisBenihColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: rekap.getJenisBenihColor().withOpacity(0.3)),
                    ),
                    child: Text(
                      rekap.jenisBenih,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: rekap.getJenisBenihColor(),
                      ),
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showAddEditDialog(rekap: rekap);
                          break;
                        case 'delete':
                          _showDeleteConfirmation(rekap);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.eco, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    rekap.formattedJumlahNampan,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.date_range, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    rekap.formattedPeriode,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              if (rekap.catatan != null && rekap.catatan!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rekap.catatan!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    final provider = Provider.of<RekapBenihMingguanProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Rekap Benih'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: provider.selectedJenisBenih,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Benih',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Semua Jenis'),
                    ),
                    ...RekapBenihMingguanModel.getJenisBenihOptions().map(
                      (jenis) => DropdownMenuItem<String>(
                        value: jenis,
                        child: Text(jenis),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      provider.setSelectedJenisBenih(value);
                    });
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
                          text: provider.startDate != null
                              ? _dateFormat.format(provider.startDate!)
                              : '',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: provider.startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() {
                              provider.setDateRange(date, provider.endDate);
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
                          text: provider.endDate != null
                              ? _dateFormat.format(provider.endDate!)
                              : '',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: provider.endDate ?? DateTime.now(),
                            firstDate: provider.startDate ?? DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() {
                              provider.setDateRange(provider.startDate, date);
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
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

  void _showStatisticsDialog() {
    final provider = Provider.of<RekapBenihMingguanProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistik Rekap Benih'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatItem('Total Rekap', provider.rekapList.length.toString()),
              _buildStatItem('Total Nampan', provider.getTotalNampan().toString()),
              _buildStatItem('Rata-rata per Rekap', provider.getAverageNampanPerRekap().toStringAsFixed(1)),
              _buildStatItem('Jenis Terpopuler', provider.getMostPopularJenisBenih()),
              const SizedBox(height: 16),
              const Text(
                'Distribusi per Jenis:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...provider.getDistributionByJenisBenih().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(child: Text(entry.key)),
                      Text('${entry.value} nampan'),
                    ],
                  ),
                ),
              ),
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

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(RekapBenihMingguanModel rekap) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail Rekap - ${rekap.jenisBenih}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Jenis Benih', rekap.jenisBenih, Icons.eco),
            _buildDetailRow('Jumlah Nampan', rekap.formattedJumlahNampan, Icons.eco),
            _buildDetailRow('Periode', rekap.formattedPeriode, Icons.date_range),
            if (rekap.catatan != null && rekap.catatan!.isNotEmpty)
              _buildDetailRow('Catatan', rekap.catatan!, Icons.note),
            _buildDetailRow('Dicatat pada', DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(rekap.dicatatPada), Icons.access_time),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showAddEditDialog(rekap: rekap);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog({RekapBenihMingguanModel? rekap}) {
    final isEdit = rekap != null;
    final formKey = GlobalKey<FormState>();
    
    DateTime tanggalMulai = rekap?.tanggalMulai ?? DateTime.now();
    DateTime tanggalSelesai = rekap?.tanggalSelesai ?? DateTime.now().add(const Duration(days: 6));
    String jenisBenih = rekap?.jenisBenih ?? 'Selada';
    int jumlahNampan = rekap?.jumlahNampan ?? 1;
    String catatan = rekap?.catatan ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Rekap Benih' : 'Tambah Rekap Benih'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                              text: _dateFormat.format(tanggalMulai),
                            ),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: tanggalMulai,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() {
                                  tanggalMulai = date;
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
                              text: _dateFormat.format(tanggalSelesai),
                            ),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: tanggalSelesai,
                                firstDate: tanggalMulai,
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() {
                                  tanggalSelesai = date;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: jenisBenih,
                      decoration: const InputDecoration(
                        labelText: 'Jenis Benih',
                        border: OutlineInputBorder(),
                      ),
                      items: RekapBenihMingguanModel.getJenisBenihOptions().map(
                        (jenis) => DropdownMenuItem<String>(
                          value: jenis,
                          child: Text(jenis),
                        ),
                      ).toList(),
                      onChanged: (value) {
                        setState(() {
                          jenisBenih = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Jenis benih harus dipilih';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: jumlahNampan.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Jumlah Nampan',
                        border: OutlineInputBorder(),
                        suffixText: 'nampan',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Jumlah nampan harus diisi';
                        }
                        final number = int.tryParse(value);
                        if (number == null || number <= 0) {
                          return 'Jumlah nampan harus lebih dari 0';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        jumlahNampan = int.tryParse(value) ?? 1;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: catatan,
                      decoration: const InputDecoration(
                        labelText: 'Catatan (Opsional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        catatan = value;
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final provider = Provider.of<RekapBenihMingguanProvider>(context, listen: false);
                
                final newRekap = RekapBenihMingguanModel(
                  idRekap: rekap?.idRekap,
                  tanggalMulai: tanggalMulai,
                  tanggalSelesai: tanggalSelesai,
                  jenisBenih: jenisBenih,
                  jumlahNampan: jumlahNampan,
                  catatan: catatan.isNotEmpty ? catatan : null,
                  dicatatOleh: rekap?.dicatatOleh ?? '',
                  dicatatPada: rekap?.dicatatPada ?? DateTime.now(),
                );

                bool success;
                if (isEdit) {
                  success = await provider.updateRekapBenihMingguan(rekap!.idRekap!, newRekap);
                } else {
                  success = await provider.addRekapBenihMingguan(newRekap);
                }

                if (success) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEdit ? 'Rekap berhasil diperbarui' : 'Rekap berhasil ditambahkan'),
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
            },
            child: Text(isEdit ? 'Perbarui' : 'Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(RekapBenihMingguanModel rekap) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus rekap ${rekap.jenisBenih} (${rekap.formattedJumlahNampan})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<RekapBenihMingguanProvider>(context, listen: false);
              final success = await provider.deleteRekapBenihMingguan(rekap.idRekap!);
              
              Navigator.of(context).pop();
              
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

  Future<void> _exportToPDF() async {
    try {
      final provider = Provider.of<RekapBenihMingguanProvider>(context, listen: false);
      
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
                      'LAPORAN REKAP BENIH MINGGUAN',
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
                        pw.Text('Total Nampan: ${provider.getTotalNampan()}'),
                        pw.Text('Rata-rata: ${provider.getAverageNampanPerRekap().toStringAsFixed(1)}'),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Jenis Terpopuler: ${provider.getMostPopularJenisBenih()}'),
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
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(2),
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
                        child: pw.Text(
                          'No',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Jenis Benih',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Jumlah Nampan',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Periode',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Catatan',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
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
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              '${index + 1}',
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(rekap.jenisBenih),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              rekap.formattedJumlahNampan,
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              rekap.formattedPeriode,
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              rekap.catatan ?? '-',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              // Distribution by Jenis Benih
              pw.Text(
                'DISTRIBUSI PER JENIS BENIH',
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
                          'Jenis Benih',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Total Nampan',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  ...provider.getDistributionByJenisBenih().entries.map(
                    (entry) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(entry.key),
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
            ];
          },
        ),
      );

      // Save PDF file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'rekap_benih_mingguan_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf';
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