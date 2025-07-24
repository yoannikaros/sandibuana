import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/kegagalan_panen_model.dart';
import '../models/penanaman_sayur_model.dart';
import '../providers/kegagalan_panen_provider.dart';
import '../providers/auth_provider.dart';

class KegagalanPanenScreen extends StatefulWidget {
  const KegagalanPanenScreen({super.key});

  @override
  State<KegagalanPanenScreen> createState() => _KegagalanPanenScreenState();
}

class _KegagalanPanenScreenState extends State<KegagalanPanenScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String _selectedJenisFilter = 'Semua';
  String _selectedPenanamanFilter = 'Semua';
  String _selectedLokasiFilter = 'Semua';
  List<KegagalanPanenModel> _filteredList = [];

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
    final provider = Provider.of<KegagalanPanenProvider>(context, listen: false);
    await provider.initialize();
    _applyFilters();
  }

  void _applyFilters() {
    final provider = Provider.of<KegagalanPanenProvider>(context, listen: false);
    List<KegagalanPanenModel> filtered = provider.kegagalanPanenList;

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      filtered = provider.searchKegagalanPanen(_searchController.text);
    }

    // Apply jenis filter
    filtered = provider.filterByJenisKegagalan(_selectedJenisFilter);

    // Apply penanaman filter
    filtered = provider.filterByPenanaman(_selectedPenanamanFilter);

    // Apply lokasi filter
    filtered = provider.filterByLokasi(_selectedLokasiFilter);

    // Apply date range filter
    if (_selectedStartDate != null && _selectedEndDate != null) {
      filtered = filtered.where((kegagalan) {
        return kegagalan.tanggalGagal.isAfter(_selectedStartDate!.subtract(const Duration(days: 1))) &&
               kegagalan.tanggalGagal.isBefore(_selectedEndDate!.add(const Duration(days: 1)));
      }).toList();
    }

    setState(() {
      _filteredList = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kegagalan Panen Harian'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showStatistikDialog(),
          ),
        ],
      ),
      body: Consumer<KegagalanPanenProvider>(builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error: ${provider.errorMessage}',
                  style: const TextStyle(color: Colors.red),
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

        return Column(
          children: [
            _buildSearchAndFilter(provider),
            Expanded(
              child: _filteredList.isEmpty
                  ? _buildEmptyState()
                  : _buildKegagalanList(),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddKegagalanDialog(),
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilter(KegagalanPanenProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari jenis kegagalan, penyebab, lokasi...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilters();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => _applyFilters(),
          ),
          const SizedBox(height: 12),
          // Filter row 1
          Row(
            children: [
              // Date range filter
              Expanded(
                child: InkWell(
                  onTap: () => _selectDateRange(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.date_range, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedStartDate != null && _selectedEndDate != null
                                ? '${DateFormat('dd/MM/yy').format(_selectedStartDate!)} - ${DateFormat('dd/MM/yy').format(_selectedEndDate!)}'
                                : 'Pilih Tanggal',
                            style: TextStyle(
                              fontSize: 12,
                              color: _selectedStartDate != null ? Colors.black : Colors.grey[600],
                            ),
                          ),
                        ),
                        if (_selectedStartDate != null)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedStartDate = null;
                                _selectedEndDate = null;
                              });
                              _applyFilters();
                            },
                            child: const Icon(Icons.clear, size: 16),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Jenis filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedJenisFilter,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: provider.getJenisKegagalanOptions().map((jenis) {
                    return DropdownMenuItem(
                      value: jenis,
                      child: Text(
                        provider.getJenisKegagalanDisplayName(jenis),
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedJenisFilter = value!;
                    });
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Filter row 2
          Row(
            children: [
              // Penanaman filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPenanamanFilter,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: provider.getPenanamanOptions().map((penanaman) {
                    return DropdownMenuItem(
                      value: penanaman,
                      child: Text(
                        penanaman == 'Semua' ? 'Semua Penanaman' : provider.getPenanamanName(penanaman),
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPenanamanFilter = value!;
                    });
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Lokasi filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedLokasiFilter,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: provider.getLokasiOptions().map((lokasi) {
                    return DropdownMenuItem(
                      value: lokasi,
                      child: Text(
                        lokasi,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLokasiFilter = value!;
                    });
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Belum ada data kegagalan panen',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap tombol + untuk menambah data baru',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildKegagalanList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredList.length,
      itemBuilder: (context, index) {
        final kegagalan = _filteredList[index];
        return _buildKegagalanCard(kegagalan);
      },
    );
  }

  Widget _buildKegagalanCard(KegagalanPanenModel kegagalan) {
    final provider = Provider.of<KegagalanPanenProvider>(context, listen: false);
    final jenisColor = _getJenisColor(kegagalan.jenisKegagalan);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showDetailDialog(kegagalan),
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
                          KegagalanPanenModel.getJenisKegagalanDisplayName(kegagalan.jenisKegagalan),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tanggal: ${DateFormat('dd/MM/yyyy').format(kegagalan.tanggalGagal)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: jenisColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: jenisColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${kegagalan.jumlahGagal} unit',
                      style: TextStyle(
                        color: jenisColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Penanaman',
                      provider.getPenanamanName(kegagalan.idPenanaman),
                      Icons.grass,
                    ),
                  ),
                  if (kegagalan.lokasi != null && kegagalan.lokasi!.isNotEmpty)
                    Expanded(
                      child: _buildInfoItem(
                        'Lokasi',
                        kegagalan.lokasi!,
                        Icons.location_on,
                      ),
                    ),
                ],
              ),
              if (kegagalan.penyebabGagal != null && kegagalan.penyebabGagal!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Penyebab: ${kegagalan.penyebabGagal}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              if (kegagalan.tindakanDiambil != null && kegagalan.tindakanDiambil!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Tindakan: ${kegagalan.tindakanDiambil}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showEditDialog(kegagalan),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(foregroundColor: Colors.orange),
                  ),
                  TextButton.icon(
                    onPressed: () => _showDeleteConfirmation(kegagalan),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Hapus'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
        return Colors.grey;
    }
  }

  Future<void> _selectDateRange() async {
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
      _applyFilters();
    }
  }

  void _showAddKegagalanDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddKegagalanDialog(),
    ).then((_) => _loadData());
  }

  void _showEditDialog(KegagalanPanenModel kegagalan) {
    showDialog(
      context: context,
      builder: (context) => _EditKegagalanDialog(kegagalan: kegagalan),
    ).then((_) => _loadData());
  }

  void _showDetailDialog(KegagalanPanenModel kegagalan) {
    showDialog(
      context: context,
      builder: (context) => _DetailKegagalanDialog(kegagalan: kegagalan),
    );
  }

  void _showStatistikDialog() {
    showDialog(
      context: context,
      builder: (context) => _StatistikKegagalanDialog(),
    );
  }

  void _showDeleteConfirmation(KegagalanPanenModel kegagalan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus data kegagalan ${KegagalanPanenModel.getJenisKegagalanDisplayName(kegagalan.jenisKegagalan)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final provider = Provider.of<KegagalanPanenProvider>(context, listen: false);
              final success = await provider.hapusKegagalanPanen(kegagalan.idKegagalan);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data berhasil dihapus')),
                );
                _loadData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal menghapus data: ${provider.errorMessage}')),
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

// Add Kegagalan Dialog
class _AddKegagalanDialog extends StatefulWidget {
  @override
  _AddKegagalanDialogState createState() => _AddKegagalanDialogState();
}

class _AddKegagalanDialogState extends State<_AddKegagalanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahGagalController = TextEditingController();
  final _penyebabGagalController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _tindakanDiambilController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedPenanamanId;
  String _selectedJenisKegagalan = 'busuk';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Kegagalan Panen'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tanggal Gagal
                ListTile(
                  title: const Text('Tanggal Gagal'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
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
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Penanaman
                Consumer<KegagalanPanenProvider>(builder: (context, provider, child) {
                  return DropdownButtonFormField<String>(
                    value: _selectedPenanamanId,
                    decoration: const InputDecoration(
                      labelText: 'Penanaman',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Penanaman harus dipilih';
                      }
                      return null;
                    },
                    items: provider.penanamanSayurList.map((penanaman) {
                      return DropdownMenuItem<String>(
                        value: penanaman.idPenanaman,
                        child: Text(
                          '${penanaman.jenisSayur} - ${DateFormat('dd/MM/yyyy').format(penanaman.tanggalTanam)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPenanamanId = value;
                      });
                    },
                  );
                }),
                const SizedBox(height: 16),
                // Jenis Kegagalan
                DropdownButtonFormField<String>(
                  value: _selectedJenisKegagalan,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Kegagalan',
                    border: OutlineInputBorder(),
                  ),
                  items: KegagalanPanenModel.getJenisKegagalanOptions().map((jenis) {
                    return DropdownMenuItem(
                      value: jenis,
                      child: Text(KegagalanPanenModel.getJenisKegagalanDisplayName(jenis)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedJenisKegagalan = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Jumlah Gagal
                TextFormField(
                  controller: _jumlahGagalController,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Gagal',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Jumlah gagal harus diisi';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Jumlah harus berupa angka positif';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Penyebab Gagal
                TextFormField(
                  controller: _penyebabGagalController,
                  decoration: const InputDecoration(
                    labelText: 'Penyebab Gagal (Opsional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                // Lokasi
                TextFormField(
                  controller: _lokasiController,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi (Opsional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Tindakan Diambil
                TextFormField(
                  controller: _tindakanDiambilController,
                  decoration: const InputDecoration(
                    labelText: 'Tindakan Diambil (Opsional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        Consumer<KegagalanPanenProvider>(builder: (context, provider, child) {
          return ElevatedButton(
            onPressed: provider.isLoading
                ? null
                : () async {
                    if (_formKey.currentState!.validate()) {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      final success = await provider.tambahKegagalanPanen(
                        tanggalGagal: _selectedDate,
                        idPenanaman: _selectedPenanamanId!,
                        jumlahGagal: int.parse(_jumlahGagalController.text),
                        jenisKegagalan: _selectedJenisKegagalan,
                        penyebabGagal: _penyebabGagalController.text.isNotEmpty ? _penyebabGagalController.text : null,
                        lokasi: _lokasiController.text.isNotEmpty ? _lokasiController.text : null,
                        tindakanDiambil: _tindakanDiambilController.text.isNotEmpty ? _tindakanDiambilController.text : null,
                        dicatatOleh: authProvider.user?.idPengguna ?? '',
                      );

                      if (success) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Data berhasil ditambahkan')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal menambahkan data: ${provider.errorMessage}')),
                        );
                      }
                    }
                  },
            child: provider.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan'),
          );
        }),
      ],
    );
  }
}

// Edit Kegagalan Dialog
class _EditKegagalanDialog extends StatefulWidget {
  final KegagalanPanenModel kegagalan;

  const _EditKegagalanDialog({required this.kegagalan});

  @override
  _EditKegagalanDialogState createState() => _EditKegagalanDialogState();
}

class _EditKegagalanDialogState extends State<_EditKegagalanDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _jumlahGagalController;
  late TextEditingController _penyebabGagalController;
  late TextEditingController _lokasiController;
  late TextEditingController _tindakanDiambilController;
  late DateTime _selectedDate;
  String? _selectedPenanamanId;
  late String _selectedJenisKegagalan;

  @override
  void initState() {
    super.initState();
    _jumlahGagalController = TextEditingController(text: widget.kegagalan.jumlahGagal.toString());
    _penyebabGagalController = TextEditingController(text: widget.kegagalan.penyebabGagal ?? '');
    _lokasiController = TextEditingController(text: widget.kegagalan.lokasi ?? '');
    _tindakanDiambilController = TextEditingController(text: widget.kegagalan.tindakanDiambil ?? '');
    _selectedDate = widget.kegagalan.tanggalGagal;
    _selectedPenanamanId = widget.kegagalan.idPenanaman;
    _selectedJenisKegagalan = widget.kegagalan.jenisKegagalan;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Kegagalan Panen'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tanggal Gagal
                ListTile(
                  title: const Text('Tanggal Gagal'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
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
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Penanaman
                Consumer<KegagalanPanenProvider>(builder: (context, provider, child) {
                  return DropdownButtonFormField<String>(
                    value: _selectedPenanamanId,
                    decoration: const InputDecoration(
                      labelText: 'Penanaman',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Penanaman harus dipilih';
                      }
                      return null;
                    },
                    items: provider.penanamanSayurList.map((penanaman) {
                      return DropdownMenuItem<String>(
                        value: penanaman.idPenanaman,
                        child: Text(
                          '${penanaman.jenisSayur} - ${DateFormat('dd/MM/yyyy').format(penanaman.tanggalTanam)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPenanamanId = value;
                      });
                    },
                  );
                }),
                const SizedBox(height: 16),
                // Jenis Kegagalan
                DropdownButtonFormField<String>(
                  value: _selectedJenisKegagalan,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Kegagalan',
                    border: OutlineInputBorder(),
                  ),
                  items: KegagalanPanenModel.getJenisKegagalanOptions().map((jenis) {
                    return DropdownMenuItem(
                      value: jenis,
                      child: Text(KegagalanPanenModel.getJenisKegagalanDisplayName(jenis)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedJenisKegagalan = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Jumlah Gagal
                TextFormField(
                  controller: _jumlahGagalController,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Gagal',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Jumlah gagal harus diisi';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Jumlah harus berupa angka positif';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Penyebab Gagal
                TextFormField(
                  controller: _penyebabGagalController,
                  decoration: const InputDecoration(
                    labelText: 'Penyebab Gagal (Opsional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                // Lokasi
                TextFormField(
                  controller: _lokasiController,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi (Opsional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Tindakan Diambil
                TextFormField(
                  controller: _tindakanDiambilController,
                  decoration: const InputDecoration(
                    labelText: 'Tindakan Diambil (Opsional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        Consumer<KegagalanPanenProvider>(builder: (context, provider, child) {
          return ElevatedButton(
            onPressed: provider.isLoading
                ? null
                : () async {
                    if (_formKey.currentState!.validate()) {
                      final updateData = {
                        'tanggal_gagal': _selectedDate,
                        'id_penanaman': _selectedPenanamanId,
                        'jumlah_gagal': int.parse(_jumlahGagalController.text),
                        'jenis_kegagalan': _selectedJenisKegagalan,
                        'penyebab_gagal': _penyebabGagalController.text.isNotEmpty ? _penyebabGagalController.text : null,
                        'lokasi': _lokasiController.text.isNotEmpty ? _lokasiController.text : null,
                        'tindakan_diambil': _tindakanDiambilController.text.isNotEmpty ? _tindakanDiambilController.text : null,
                      };

                      final success = await provider.updateKegagalanPanen(
                        widget.kegagalan.idKegagalan,
                        updateData,
                      );

                      if (success) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Data berhasil diupdate')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal mengupdate data: ${provider.errorMessage}')),
                        );
                      }
                    }
                  },
            child: provider.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Update'),
          );
        }),
      ],
    );
  }
}

// Detail Kegagalan Dialog
class _DetailKegagalanDialog extends StatelessWidget {
  final KegagalanPanenModel kegagalan;

  const _DetailKegagalanDialog({required this.kegagalan});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<KegagalanPanenProvider>(context, listen: false);
    
    return AlertDialog(
      title: Text('Detail ${KegagalanPanenModel.getJenisKegagalanDisplayName(kegagalan.jenisKegagalan)}'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Tanggal Gagal', DateFormat('dd/MM/yyyy').format(kegagalan.tanggalGagal)),
              _buildDetailRow('Jenis Kegagalan', KegagalanPanenModel.getJenisKegagalanDisplayName(kegagalan.jenisKegagalan)),
              _buildDetailRow('Jumlah Gagal', '${kegagalan.jumlahGagal} unit'),
              _buildDetailRow('Penanaman', provider.getPenanamanName(kegagalan.idPenanaman)),
              if (kegagalan.lokasi != null && kegagalan.lokasi!.isNotEmpty)
                _buildDetailRow('Lokasi', kegagalan.lokasi!),
              if (kegagalan.penyebabGagal != null && kegagalan.penyebabGagal!.isNotEmpty)
                _buildDetailRow('Penyebab Gagal', kegagalan.penyebabGagal!),
              if (kegagalan.tindakanDiambil != null && kegagalan.tindakanDiambil!.isNotEmpty)
                _buildDetailRow('Tindakan Diambil', kegagalan.tindakanDiambil!),
              const SizedBox(height: 16),
              Text(
                'Dicatat pada: ${DateFormat('dd/MM/yyyy HH:mm').format(kegagalan.dicatatPada)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
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
              style: const TextStyle(fontWeight: FontWeight.w500),
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

// Statistik Kegagalan Dialog
class _StatistikKegagalanDialog extends StatefulWidget {
  @override
  _StatistikKegagalanDialogState createState() => _StatistikKegagalanDialogState();
}

class _StatistikKegagalanDialogState extends State<_StatistikKegagalanDialog> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  Map<String, dynamic>? _ringkasan;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStatistik();
  }

  Future<void> _loadStatistik() async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<KegagalanPanenProvider>(context, listen: false);
    final ringkasan = await provider.getRingkasanKegagalanPanen(_startDate, _endDate);

    setState(() {
      _ringkasan = ringkasan;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Statistik Kegagalan Panen'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Date range selector
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                      );
                      if (picked != null) {
                        setState(() {
                          _startDate = picked.start;
                          _endDate = picked.end;
                        });
                        _loadStatistik();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${DateFormat('dd/MM/yy').format(_startDate)} - ${DateFormat('dd/MM/yy').format(_endDate)}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Statistics content
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_ringkasan != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatCard('Total Kejadian', '${_ringkasan!['total_kegagalan']}', Icons.warning),
                      _buildStatCard('Total Unit Gagal', '${_ringkasan!['total_jumlah_gagal']}', Icons.cancel),
                      _buildStatCard('Rata-rata per Kejadian', '${(_ringkasan!['rata_rata_per_kejadian'] as double).toStringAsFixed(1)}', Icons.analytics),
                      const SizedBox(height: 16),
                      const Text('Berdasarkan Jenis:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...(_ringkasan!['jenis_kegagalan'] as Map<String, int>).entries.map((entry) {
                        return _buildJenisStatRow(entry.key, entry.value);
                      }).toList(),
                      if ((_ringkasan!['lokasi_kegagalan'] as Map<String, int>).isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text('Berdasarkan Lokasi:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...(_ringkasan!['lokasi_kegagalan'] as Map<String, int>).entries.map((entry) {
                          return _buildLokasiStatRow(entry.key, entry.value);
                        }).toList(),
                      ],
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
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJenisStatRow(String jenis, int jumlah) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Color(int.parse(KegagalanPanenModel.getJenisKegagalanColor(jenis).substring(1), radix: 16) + 0xFF000000),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(KegagalanPanenModel.getJenisKegagalanDisplayName(jenis)),
          ),
          Text('$jumlah unit', style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildLokasiStatRow(String lokasi, int jumlah) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.location_on, size: 12, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(lokasi),
          ),
          Text('$jumlah unit', style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}