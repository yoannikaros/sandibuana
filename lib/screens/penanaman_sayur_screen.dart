import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/penanaman_sayur_model.dart';
import '../models/catatan_pembenihan_model.dart';
import '../providers/penanaman_sayur_provider.dart';
import '../providers/auth_provider.dart';

class PenanamanSayurScreen extends StatefulWidget {
  const PenanamanSayurScreen({super.key});

  @override
  State<PenanamanSayurScreen> createState() => _PenanamanSayurScreenState();
}

class _PenanamanSayurScreenState extends State<PenanamanSayurScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String _selectedTahapFilter = 'Semua';
  String _selectedJenisFilter = 'Semua';
  List<PenanamanSayurModel> _filteredList = [];

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
    final provider = Provider.of<PenanamanSayurProvider>(context, listen: false);
    await provider.initialize();
    _applyFilters();
  }

  void _applyFilters() {
    final provider = Provider.of<PenanamanSayurProvider>(context, listen: false);
    List<PenanamanSayurModel> filtered = provider.penanamanSayurList;

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      filtered = provider.searchPenanamanSayur(_searchController.text);
    }

    // Apply tahap filter
    filtered = provider.filterByTahapPertumbuhan(_selectedTahapFilter);

    // Apply jenis filter
    filtered = provider.filterByJenisSayur(_selectedJenisFilter);

    // Apply date range filter
    if (_selectedStartDate != null && _selectedEndDate != null) {
      filtered = filtered.where((penanaman) {
        return penanaman.tanggalTanam.isAfter(_selectedStartDate!.subtract(const Duration(days: 1))) &&
               penanaman.tanggalTanam.isBefore(_selectedEndDate!.add(const Duration(days: 1)));
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
        title: const Text('Penanaman Sayur'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Consumer<PenanamanSayurProvider>(builder: (context, provider, child) {
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
                  : _buildPenanamanList(),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPenanamanDialog(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilter(PenanamanSayurProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari jenis sayur, lokasi, atau catatan...',
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
          // Filter row
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
              // Tahap filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedTahapFilter,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: provider.getTahapPertumbuhanOptions().map((tahap) {
                    return DropdownMenuItem(
                      value: tahap,
                      child: Text(
                        provider.getTahapPertumbuhanDisplayName(tahap),
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTahapFilter = value!;
                    });
                    _applyFilters();
                  },
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
                  items: provider.getUniqueJenisSayur().map((jenis) {
                    return DropdownMenuItem(
                      value: jenis,
                      child: Text(
                        jenis,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
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
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.spa, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Belum ada data penanaman sayur',
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

  Widget _buildPenanamanList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredList.length,
      itemBuilder: (context, index) {
        final penanaman = _filteredList[index];
        return _buildPenanamanCard(penanaman);
      },
    );
  }

  Widget _buildPenanamanCard(PenanamanSayurModel penanaman) {
    final provider = Provider.of<PenanamanSayurProvider>(context, listen: false);
    final tahapColor = _getTahapColor(penanaman.tahapPertumbuhan);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showDetailDialog(penanaman),
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
                          penanaman.jenisSayur,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tanggal Tanam: ${DateFormat('dd/MM/yyyy').format(penanaman.tanggalTanam)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: tahapColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: tahapColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      provider.getTahapPertumbuhanDisplayName(penanaman.tahapPertumbuhan),
                      style: TextStyle(
                        color: tahapColor,
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
                      'Jumlah Ditanam',
                      '${penanaman.jumlahDitanam}',
                      Icons.grass,
                    ),
                  ),
                  if (penanaman.tahapPertumbuhan == 'panen') ...[
                    Expanded(
                      child: _buildInfoItem(
                        'Dipanen',
                        '${penanaman.jumlahDipanen}',
                        Icons.agriculture,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        'Keberhasilan',
                        '${penanaman.tingkatKeberhasilan.toStringAsFixed(1)}%',
                        Icons.trending_up,
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: _buildInfoItem(
                        'Lokasi',
                        penanaman.lokasi ?? 'Tidak ada',
                        Icons.location_on,
                      ),
                    ),
                  ],
                  Expanded(
                    child: _buildInfoItem(
                      'Harga',
                      penanaman.harga != null ? 'Rp ${penanaman.harga!.toStringAsFixed(0)}' : 'Belum diset',
                      Icons.attach_money,
                    ),
                  ),
                ],
              ),
              if (penanaman.idPembenihan != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Batch: ${provider.getCatatanPembenihanName(penanaman.idPembenihan)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (penanaman.catatan != null && penanaman.catatan!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Catatan: ${penanaman.catatan}',
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
                  if (penanaman.tahapPertumbuhan != 'panen' && penanaman.tahapPertumbuhan != 'gagal')
                    TextButton.icon(
                      onPressed: () => _showUpdateTahapDialog(penanaman),
                      icon: const Icon(Icons.update, size: 16),
                      label: const Text('Update Tahap'),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    ),
                  if (penanaman.tahapPertumbuhan == 'siap_panen')
                    TextButton.icon(
                      onPressed: () => _showPanenDialog(penanaman),
                      icon: const Icon(Icons.agriculture, size: 16),
                      label: const Text('Panen'),
                      style: TextButton.styleFrom(foregroundColor: Colors.green),
                    ),
                  TextButton.icon(
                    onPressed: () => _showEditDialog(penanaman),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(foregroundColor: Colors.orange),
                  ),
                  TextButton.icon(
                    onPressed: () => _showDeleteConfirmation(penanaman),
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
        ),
      ],
    );
  }

  Color _getTahapColor(String tahap) {
    switch (tahap) {
      case 'semai':
        return Colors.blue;
      case 'vegetatif':
        return Colors.green;
      case 'siap_panen':
        return Colors.orange;
      case 'panen':
        return Colors.purple;
      case 'gagal':
        return Colors.red;
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

  void _showAddPenanamanDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddPenanamanDialog(),
    ).then((_) => _loadData());
  }

  void _showEditDialog(PenanamanSayurModel penanaman) {
    showDialog(
      context: context,
      builder: (context) => _EditPenanamanDialog(penanaman: penanaman),
    ).then((_) => _loadData());
  }

  void _showDetailDialog(PenanamanSayurModel penanaman) {
    showDialog(
      context: context,
      builder: (context) => _DetailPenanamanDialog(penanaman: penanaman),
    );
  }

  void _showUpdateTahapDialog(PenanamanSayurModel penanaman) {
    showDialog(
      context: context,
      builder: (context) => _UpdateTahapDialog(penanaman: penanaman),
    ).then((_) => _loadData());
  }

  void _showPanenDialog(PenanamanSayurModel penanaman) {
    showDialog(
      context: context,
      builder: (context) => _PanenDialog(penanaman: penanaman),
    ).then((_) => _loadData());
  }

  void _showDeleteConfirmation(PenanamanSayurModel penanaman) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus data penanaman ${penanaman.jenisSayur}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final provider = Provider.of<PenanamanSayurProvider>(context, listen: false);
              final success = await provider.hapusPenanamanSayur(penanaman.idPenanaman);
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

// Add Penanaman Dialog
class _AddPenanamanDialog extends StatefulWidget {
  @override
  _AddPenanamanDialogState createState() => _AddPenanamanDialogState();
}

class _AddPenanamanDialogState extends State<_AddPenanamanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _jenisSayurController = TextEditingController();
  final _jumlahDitanamController = TextEditingController();
  final _hargaController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _catatanController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedPembenihanId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Penanaman Sayur'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tanggal Tanam
                ListTile(
                  title: const Text('Tanggal Tanam'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Jenis Sayur
                TextFormField(
                  controller: _jenisSayurController,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Sayur',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Jenis sayur harus diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Jumlah Ditanam
                TextFormField(
                  controller: _jumlahDitanamController,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Ditanam',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Jumlah ditanam harus diisi';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Jumlah harus berupa angka positif';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Harga
                TextFormField(
                  controller: _hargaController,
                  decoration: const InputDecoration(
                    labelText: 'Harga per Unit (Opsional)',
                    border: OutlineInputBorder(),
                    prefixText: 'Rp ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (double.tryParse(value) == null || double.parse(value) < 0) {
                        return 'Harga harus berupa angka positif';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Catatan Pembenihan
                Consumer<PenanamanSayurProvider>(builder: (context, provider, child) {
                  return DropdownButtonFormField<String>(
                    value: _selectedPembenihanId,
                    decoration: const InputDecoration(
                      labelText: 'Catatan Pembenihan (Opsional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Tidak terkait dengan batch'),
                      ),
                      ...provider.catatanPembenihanList.map((catatan) {
                        return DropdownMenuItem<String>(
                          value: catatan.idPembenihan,
                          child: Text(
                            'Batch: ${catatan.kodeBatch ?? 'N/A'} - ${DateFormat('dd/MM/yyyy').format(catatan.tanggalSemai)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPembenihanId = value;
                      });
                    },
                  );
                }),
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
                // Catatan
                TextFormField(
                  controller: _catatanController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (Opsional)',
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
        Consumer<PenanamanSayurProvider>(builder: (context, provider, child) {
          return ElevatedButton(
            onPressed: provider.isLoading
                ? null
                : () async {
                    if (_formKey.currentState!.validate()) {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      final success = await provider.tambahPenanamanSayur(
                        idPembenihan: _selectedPembenihanId,
                        tanggalTanam: _selectedDate,
                        jenisSayur: _jenisSayurController.text,
                        jumlahDitanam: int.parse(_jumlahDitanamController.text),
                        harga: _hargaController.text.isNotEmpty ? double.parse(_hargaController.text) : null,
                        lokasi: _lokasiController.text.isNotEmpty ? _lokasiController.text : null,
                        catatan: _catatanController.text.isNotEmpty ? _catatanController.text : null,
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

// Edit Penanaman Dialog
class _EditPenanamanDialog extends StatefulWidget {
  final PenanamanSayurModel penanaman;

  const _EditPenanamanDialog({required this.penanaman});

  @override
  _EditPenanamanDialogState createState() => _EditPenanamanDialogState();
}

class _EditPenanamanDialogState extends State<_EditPenanamanDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _jenisSayurController;
  late TextEditingController _jumlahDitanamController;
  late TextEditingController _hargaController;
  late TextEditingController _lokasiController;
  late TextEditingController _catatanController;
  late DateTime _selectedDate;
  String? _selectedPembenihanId;

  @override
  void initState() {
    super.initState();
    _jenisSayurController = TextEditingController(text: widget.penanaman.jenisSayur);
    _jumlahDitanamController = TextEditingController(text: widget.penanaman.jumlahDitanam.toString());
    _hargaController = TextEditingController(text: widget.penanaman.harga?.toString() ?? '');
    _lokasiController = TextEditingController(text: widget.penanaman.lokasi ?? '');
    _catatanController = TextEditingController(text: widget.penanaman.catatan ?? '');
    _selectedDate = widget.penanaman.tanggalTanam;
    _selectedPembenihanId = widget.penanaman.idPembenihan;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Penanaman Sayur'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tanggal Tanam
                ListTile(
                  title: const Text('Tanggal Tanam'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Jenis Sayur
                TextFormField(
                  controller: _jenisSayurController,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Sayur',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Jenis sayur harus diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Jumlah Ditanam
                TextFormField(
                  controller: _jumlahDitanamController,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Ditanam',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Jumlah ditanam harus diisi';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Jumlah harus berupa angka positif';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Harga
                TextFormField(
                  controller: _hargaController,
                  decoration: const InputDecoration(
                    labelText: 'Harga per Unit (Opsional)',
                    border: OutlineInputBorder(),
                    prefixText: 'Rp ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (double.tryParse(value) == null || double.parse(value) < 0) {
                        return 'Harga harus berupa angka positif';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Catatan Pembenihan
                Consumer<PenanamanSayurProvider>(builder: (context, provider, child) {
                  return DropdownButtonFormField<String>(
                    value: _selectedPembenihanId,
                    decoration: const InputDecoration(
                      labelText: 'Catatan Pembenihan (Opsional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Tidak terkait dengan batch'),
                      ),
                      ...provider.catatanPembenihanList.map((catatan) {
                        return DropdownMenuItem<String>(
                          value: catatan.idPembenihan,
                          child: Text(
                            'Batch: ${catatan.kodeBatch ?? 'N/A'} - ${DateFormat('dd/MM/yyyy').format(catatan.tanggalSemai)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPembenihanId = value;
                      });
                    },
                  );
                }),
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
                // Catatan
                TextFormField(
                  controller: _catatanController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (Opsional)',
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
        Consumer<PenanamanSayurProvider>(builder: (context, provider, child) {
          return ElevatedButton(
            onPressed: provider.isLoading
                ? null
                : () async {
                    if (_formKey.currentState!.validate()) {
                      final updateData = {
                        'tanggal_tanam': _selectedDate,
                        'jenis_sayur': _jenisSayurController.text,
                        'jumlah_ditanam': int.parse(_jumlahDitanamController.text),
                        'harga': _hargaController.text.isNotEmpty ? double.parse(_hargaController.text) : null,
                        'id_pembenihan': _selectedPembenihanId,
                        'lokasi': _lokasiController.text.isNotEmpty ? _lokasiController.text : null,
                        'catatan': _catatanController.text.isNotEmpty ? _catatanController.text : null,
                      };

                      final success = await provider.updatePenanamanSayur(
                        widget.penanaman.idPenanaman,
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

// Detail Penanaman Dialog
class _DetailPenanamanDialog extends StatelessWidget {
  final PenanamanSayurModel penanaman;

  const _DetailPenanamanDialog({required this.penanaman});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PenanamanSayurProvider>(context, listen: false);
    
    return AlertDialog(
      title: Text('Detail ${penanaman.jenisSayur}'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Tanggal Tanam', DateFormat('dd/MM/yyyy').format(penanaman.tanggalTanam)),
              _buildDetailRow('Jenis Sayur', penanaman.jenisSayur),
              _buildDetailRow('Jumlah Ditanam', '${penanaman.jumlahDitanam}'),
              if (penanaman.harga != null)
                _buildDetailRow('Harga per Unit', 'Rp ${penanaman.harga!.toStringAsFixed(0)}'),
              _buildDetailRow('Tahap Pertumbuhan', provider.getTahapPertumbuhanDisplayName(penanaman.tahapPertumbuhan)),
              if (penanaman.lokasi != null)
                _buildDetailRow('Lokasi', penanaman.lokasi!),
              if (penanaman.idPembenihan != null)
                _buildDetailRow('Batch Pembenihan', provider.getCatatanPembenihanName(penanaman.idPembenihan)),
              if (penanaman.tanggalPanen != null)
                _buildDetailRow('Tanggal Panen', DateFormat('dd/MM/yyyy').format(penanaman.tanggalPanen!)),
              if (penanaman.tahapPertumbuhan == 'panen') ...[
                _buildDetailRow('Jumlah Dipanen', '${penanaman.jumlahDipanen}'),
                _buildDetailRow('Jumlah Gagal', '${penanaman.jumlahGagal}'),
                _buildDetailRow('Tingkat Keberhasilan', '${penanaman.tingkatKeberhasilan.toStringAsFixed(1)}%'),
              ],
              if (penanaman.alasanGagal != null && penanaman.alasanGagal!.isNotEmpty)
                _buildDetailRow('Alasan Gagal', penanaman.alasanGagal!),
              if (penanaman.catatan != null && penanaman.catatan!.isNotEmpty)
                _buildDetailRow('Catatan', penanaman.catatan!),
              const SizedBox(height: 16),
              Text(
                'Dicatat pada: ${DateFormat('dd/MM/yyyy HH:mm').format(penanaman.dicatatPada)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                'Diubah pada: ${DateFormat('dd/MM/yyyy HH:mm').format(penanaman.diubahPada)}',
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

// Update Tahap Dialog
class _UpdateTahapDialog extends StatefulWidget {
  final PenanamanSayurModel penanaman;

  const _UpdateTahapDialog({required this.penanaman});

  @override
  _UpdateTahapDialogState createState() => _UpdateTahapDialogState();
}

class _UpdateTahapDialogState extends State<_UpdateTahapDialog> {
  late String _selectedTahap;
  final List<String> _tahapOptions = ['semai', 'vegetatif', 'siap_panen', 'gagal'];

  @override
  void initState() {
    super.initState();
    _selectedTahap = widget.penanaman.tahapPertumbuhan;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PenanamanSayurProvider>(context, listen: false);
    
    return AlertDialog(
      title: const Text('Update Tahap Pertumbuhan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Tahap saat ini: ${provider.getTahapPertumbuhanDisplayName(widget.penanaman.tahapPertumbuhan)}'),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedTahap,
            decoration: const InputDecoration(
              labelText: 'Tahap Baru',
              border: OutlineInputBorder(),
            ),
            items: _tahapOptions.map((tahap) {
              return DropdownMenuItem(
                value: tahap,
                child: Text(provider.getTahapPertumbuhanDisplayName(tahap)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedTahap = value!;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        Consumer<PenanamanSayurProvider>(builder: (context, provider, child) {
          return ElevatedButton(
            onPressed: provider.isLoading
                ? null
                : () async {
                    final success = await provider.updateTahapPertumbuhan(
                      widget.penanaman.idPenanaman,
                      _selectedTahap,
                    );

                    if (success) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tahap berhasil diupdate')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal mengupdate tahap: ${provider.errorMessage}')),
                      );
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

// Panen Dialog
class _PanenDialog extends StatefulWidget {
  final PenanamanSayurModel penanaman;

  const _PanenDialog({required this.penanaman});

  @override
  _PanenDialogState createState() => _PanenDialogState();
}

class _PanenDialogState extends State<_PanenDialog> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahDipanenController = TextEditingController();
  final _jumlahGagalController = TextEditingController(text: '0');
  final _alasanGagalController = TextEditingController();
  DateTime _tanggalPanen = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Input Data Panen'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Jumlah ditanam: ${widget.penanaman.jumlahDitanam}'),
                const SizedBox(height: 16),
                // Tanggal Panen
                ListTile(
                  title: const Text('Tanggal Panen'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(_tanggalPanen)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _tanggalPanen,
                      firstDate: widget.penanaman.tanggalTanam,
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (date != null) {
                      setState(() {
                        _tanggalPanen = date;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Jumlah Dipanen
                TextFormField(
                  controller: _jumlahDipanenController,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Dipanen',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Jumlah dipanen harus diisi';
                    }
                    final jumlah = int.tryParse(value);
                    if (jumlah == null || jumlah < 0) {
                      return 'Jumlah harus berupa angka positif atau nol';
                    }
                    final jumlahGagal = int.tryParse(_jumlahGagalController.text) ?? 0;
                    if (jumlah + jumlahGagal > widget.penanaman.jumlahDitanam) {
                      return 'Total dipanen + gagal tidak boleh melebihi jumlah ditanam';
                    }
                    return null;
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
                    final jumlah = int.tryParse(value);
                    if (jumlah == null || jumlah < 0) {
                      return 'Jumlah harus berupa angka positif atau nol';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Alasan Gagal
                TextFormField(
                  controller: _alasanGagalController,
                  decoration: const InputDecoration(
                    labelText: 'Alasan Gagal (Opsional)',
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
        Consumer<PenanamanSayurProvider>(builder: (context, provider, child) {
          return ElevatedButton(
            onPressed: provider.isLoading
                ? null
                : () async {
                    if (_formKey.currentState!.validate()) {
                      final success = await provider.updateDataPanen(
                        widget.penanaman.idPenanaman,
                        tanggalPanen: _tanggalPanen,
                        jumlahDipanen: int.parse(_jumlahDipanenController.text),
                        jumlahGagal: int.parse(_jumlahGagalController.text),
                        alasanGagal: _alasanGagalController.text.isNotEmpty ? _alasanGagalController.text : null,
                      );

                      if (success) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Data panen berhasil disimpan')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal menyimpan data panen: ${provider.errorMessage}')),
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