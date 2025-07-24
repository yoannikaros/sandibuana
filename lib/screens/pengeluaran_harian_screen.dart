import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/pengeluaran_harian_model.dart';
import '../models/kategori_pengeluaran_model.dart';
import '../providers/pengeluaran_provider.dart';
import '../providers/auth_provider.dart';

class PengeluaranHarianScreen extends StatefulWidget {
  const PengeluaranHarianScreen({super.key});

  @override
  State<PengeluaranHarianScreen> createState() => _PengeluaranHarianScreenState();
}

class _PengeluaranHarianScreenState extends State<PengeluaranHarianScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String? _selectedKategoriId;

  @override
  void initState() {
    super.initState();
    // Initialize Indonesian locale for DateFormat
    initializeDateFormatting('id_ID', null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PengeluaranProvider>().initialize();
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
        title: const Text('Pengeluaran Harian'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<PengeluaranProvider>().refresh();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          _buildSummaryCard(),
          Expanded(
            child: _buildPengeluaranList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.red.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari berdasarkan keterangan atau pemasok...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context.read<PengeluaranProvider>().searchPengeluaran('');
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
              context.read<PengeluaranProvider>().searchPengeluaran(value);
            },
          ),
          const SizedBox(height: 12),
          // Filter row
          Row(
            children: [
              // Category filter
              Expanded(
                child: Consumer<PengeluaranProvider>(
                  builder: (context, provider, child) {
                    return DropdownButtonFormField<String>(
                      value: _selectedKategoriId,
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Semua Kategori'),
                        ),
                        ...provider.kategoriList.map((kategori) {
                          return DropdownMenuItem(
                            value: kategori.id,
                            child: Text(kategori.namaKategori),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedKategoriId = value;
                        });
                        provider.filterByKategori(value);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Date filter button
              ElevatedButton.icon(
                onPressed: _showDateRangeFilter,
                icon: const Icon(Icons.date_range),
                label: Text(
                  _selectedStartDate != null && _selectedEndDate != null
                      ? '${DateFormat('dd/MM').format(_selectedStartDate!)} - ${DateFormat('dd/MM').format(_selectedEndDate!)}'
                      : 'Filter Tanggal',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Consumer<PengeluaranProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    'Total Pengeluaran',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(provider.totalPengeluaran),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.red.shade200,
              ),
              Column(
                children: [
                  Text(
                    'Total Transaksi',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '${provider.totalCount}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPengeluaranList() {
    return Consumer<PengeluaranProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Terjadi kesalahan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    provider.clearError();
                    provider.refresh();
                  },
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        if (provider.pengeluaranList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada data pengeluaran',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap tombol + untuk menambah pengeluaran baru',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.pengeluaranList.length,
          itemBuilder: (context, index) {
            final pengeluaran = provider.pengeluaranList[index];
            return _buildPengeluaranCard(pengeluaran, provider);
          },
        );
      },
    );
  }

  Widget _buildPengeluaranCard(PengeluaranHarianModel pengeluaran, PengeluaranProvider provider) {
    final kategoriName = provider.getKategoriName(pengeluaran.idKategori);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAddEditDialog(pengeluaran: pengeluaran),
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
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd/MM/yyyy').format(pengeluaran.tanggalPengeluaran),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                kategoriName,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          pengeluaran.keterangan,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (pengeluaran.pemasok != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.store,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                pengeluaran.pemasok!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(pengeluaran.jumlah),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _showAddEditDialog(pengeluaran: pengeluaran);
                              break;
                            case 'delete':
                              _showDeleteConfirmation(pengeluaran);
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
                ],
              ),
              if (pengeluaran.nomorNota != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.receipt,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'No. Nota: ${pengeluaran.nomorNota}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
              if (pengeluaran.catatan != null && pengeluaran.catatan!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.note,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          pengeluaran.catatan!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
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

  void _showDateRangeFilter() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedStartDate != null && _selectedEndDate != null
          ? DateTimeRange(start: _selectedStartDate!, end: _selectedEndDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
      });
      context.read<PengeluaranProvider>().filterByDateRange(picked.start, picked.end);
    }
  }

  void _showAddEditDialog({PengeluaranHarianModel? pengeluaran}) {
    final isEdit = pengeluaran != null;
    final tanggalController = TextEditingController(
      text: isEdit ? DateFormat('yyyy-MM-dd').format(pengeluaran.tanggalPengeluaran) : DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    final keteranganController = TextEditingController(text: pengeluaran?.keterangan ?? '');
    final jumlahController = TextEditingController(text: pengeluaran?.jumlah.toString() ?? '');
    final nomorNotaController = TextEditingController(text: pengeluaran?.nomorNota ?? '');
    final pemasokController = TextEditingController(text: pengeluaran?.pemasok ?? '');
    final catatanController = TextEditingController(text: pengeluaran?.catatan ?? '');
    
    String? selectedKategoriId = pengeluaran?.idKategori;
    DateTime selectedDate = pengeluaran?.tanggalPengeluaran ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit Pengeluaran' : 'Tambah Pengeluaran'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date picker
                ListTile(
                  title: const Text('Tanggal'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        selectedDate = date;
                        tanggalController.text = DateFormat('yyyy-MM-dd').format(date);
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Category dropdown
                Consumer<PengeluaranProvider>(
                  builder: (context, provider, child) {
                    return DropdownButtonFormField<String>(
                      value: selectedKategoriId,
                      decoration: const InputDecoration(
                        labelText: 'Kategori *',
                        border: OutlineInputBorder(),
                      ),
                      items: provider.kategoriList.map((kategori) {
                        return DropdownMenuItem(
                          value: kategori.id,
                          child: Text(kategori.namaKategori),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedKategoriId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kategori harus dipilih';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Description
                TextField(
                  controller: keteranganController,
                  decoration: const InputDecoration(
                    labelText: 'Keterangan *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                // Amount
                TextField(
                  controller: jumlahController,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah (Rp) *',
                    border: OutlineInputBorder(),
                    prefixText: 'Rp ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                // Receipt number
                TextField(
                  controller: nomorNotaController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Nota',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Supplier
                TextField(
                  controller: pemasokController,
                  decoration: const InputDecoration(
                    labelText: 'Pemasok',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Notes
                TextField(
                  controller: catatanController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan',
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
                if (selectedKategoriId == null || selectedKategoriId!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kategori harus dipilih')),
                  );
                  return;
                }
                if (keteranganController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Keterangan harus diisi')),
                  );
                  return;
                }
                if (jumlahController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Jumlah harus diisi')),
                  );
                  return;
                }

                final authProvider = context.read<AuthProvider>();
                final pengeluaranProvider = context.read<PengeluaranProvider>();

                final newPengeluaran = PengeluaranHarianModel(
                  id: pengeluaran?.id ?? '',
                  tanggalPengeluaran: selectedDate,
                  idKategori: selectedKategoriId!,
                  keterangan: keteranganController.text.trim(),
                  jumlah: double.tryParse(jumlahController.text.trim()) ?? 0,
                  nomorNota: nomorNotaController.text.trim().isEmpty ? null : nomorNotaController.text.trim(),
                  pemasok: pemasokController.text.trim().isEmpty ? null : pemasokController.text.trim(),
                  catatan: catatanController.text.trim().isEmpty ? null : catatanController.text.trim(),
                  dicatatOleh: authProvider.user?.idPengguna,
                  dicatatPada: pengeluaran?.dicatatPada ?? DateTime.now(),
                );

                bool success;
                if (isEdit) {
                  success = await pengeluaranProvider.updatePengeluaran(newPengeluaran);
                } else {
                  success = await pengeluaranProvider.tambahPengeluaran(newPengeluaran);
                }

                if (success) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEdit ? 'Pengeluaran berhasil diupdate' : 'Pengeluaran berhasil ditambahkan'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(pengeluaranProvider.error ?? 'Terjadi kesalahan'),
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

  void _showDeleteConfirmation(PengeluaranHarianModel pengeluaran) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Apakah Anda yakin ingin menghapus pengeluaran ini?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pengeluaran.keterangan,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(pengeluaran.jumlah),
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy').format(pengeluaran.tanggalPengeluaran),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await context.read<PengeluaranProvider>().hapusPengeluaran(pengeluaran.id);
              Navigator.of(context).pop();
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pengeluaran berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gagal menghapus pengeluaran'),
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
}