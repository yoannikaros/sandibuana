import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/catatan_pembenihan_model.dart';
import '../models/jenis_benih_model.dart';
import '../providers/benih_provider.dart';
import '../providers/auth_provider.dart';

class CatatanPembenihanScreen extends StatefulWidget {
  const CatatanPembenihanScreen({super.key});

  @override
  State<CatatanPembenihanScreen> createState() => _CatatanPembenihanScreenState();
}

class _CatatanPembenihanScreenState extends State<CatatanPembenihanScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _selectedEndDate = DateTime.now();
  String _searchQuery = '';

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
    final benihProvider = Provider.of<BenihProvider>(context, listen: false);
    await benihProvider.loadJenisBenihAktif();
    await benihProvider.loadCatatanPembenihanByTanggal(_selectedStartDate, _selectedEndDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Pembenihan'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari berdasarkan nama benih atau kode batch...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Date Range
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectStartDate(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('dd/MM/yyyy').format(_selectedStartDate),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('s/d'),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectEndDate(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('dd/MM/yyyy').format(_selectedEndDate),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: Consumer<BenihProvider>(
              builder: (context, benihProvider, child) {
                if (benihProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (benihProvider.errorMessage != null) {
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
                          'Error: ${benihProvider.errorMessage}',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 16,
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

                List<CatatanPembenihanModel> filteredData = benihProvider.catatanPembenihanList
                    .where((catatan) {
                      if (_searchQuery.isEmpty) return true;
                      
                      // Get benih name
                      final benih = benihProvider.jenisBenihList
                          .firstWhere(
                            (b) => b.idBenih == catatan.idBenih,
                            orElse: () => JenisBenihModel(
                              idBenih: '',
                              namaBenih: 'Unknown',
                              pemasok: '',
                              hargaPerSatuan: 0,
                              jenisSatuan: '',
                              ukuranSatuan: '',
                              aktif: true,
                              dibuatPada: DateTime.now(),
                            ),
                          );
                      
                      return benih.namaBenih.toLowerCase().contains(_searchQuery) ||
                             (catatan.kodeBatch?.toLowerCase().contains(_searchQuery) ?? false);
                    })
                    .toList();

                if (filteredData.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.grass,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty 
                              ? 'Tidak ada catatan pembenihan yang sesuai'
                              : 'Belum ada catatan pembenihan',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      final catatan = filteredData[index];
                      return _buildCatatanCard(catatan, benihProvider);
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
        backgroundColor: Colors.green.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCatatanCard(CatatanPembenihanModel catatan, BenihProvider benihProvider) {
    // Get benih name
    final benih = benihProvider.jenisBenihList.firstWhere(
      (b) => b.idBenih == catatan.idBenih,
      orElse: () => JenisBenihModel(
        idBenih: '',
        namaBenih: 'Unknown',
        pemasok: '',
        hargaPerSatuan: 0,
        jenisSatuan: '',
        ukuranSatuan: '',
        aktif: true,
        dibuatPada: DateTime.now(),
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAddEditDialog(catatan: catatan),
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
                          benih.namaBenih,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd/MM/yyyy').format(catatan.tanggalSemai),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showAddEditDialog(catatan: catatan);
                          break;
                        case 'delete':
                          _showDeleteConfirmation(catatan);
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jumlah: ${catatan.jumlah} ${catatan.satuan ?? ''}',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (catatan.kodeBatch != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Batch: ${catatan.kodeBatch}',
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (catatan.tanggalPanenTarget != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Target Panen: ${DateFormat('dd/MM/yyyy').format(catatan.tanggalPanenTarget!)}',
                            style: TextStyle(
                              color: Colors.orange[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (catatan.catatan != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Catatan: ${catatan.catatan}',
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          'Dicatat: ${DateFormat('dd/MM/yyyy HH:mm').format(catatan.dicatatPada)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
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

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedStartDate) {
      setState(() {
        _selectedStartDate = picked;
      });
      _loadData();
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedEndDate) {
      setState(() {
        _selectedEndDate = picked;
      });
      _loadData();
    }
  }

  void _showAddEditDialog({CatatanPembenihanModel? catatan}) {
    showDialog(
      context: context,
      builder: (context) => _AddEditCatatanDialog(
        catatan: catatan,
        onSaved: () {
          _loadData();
        },
      ),
    );
  }

  void _showDeleteConfirmation(CatatanPembenihanModel catatan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus catatan pembenihan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final benihProvider = Provider.of<BenihProvider>(context, listen: false);
              final success = await benihProvider.hapusCatatanPembenihan(catatan.idPembenihan);
              
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Catatan pembenihan berhasil dihapus'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gagal menghapus catatan pembenihan'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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

class _AddEditCatatanDialog extends StatefulWidget {
  final CatatanPembenihanModel? catatan;
  final VoidCallback onSaved;

  const _AddEditCatatanDialog({
    this.catatan,
    required this.onSaved,
  });

  @override
  State<_AddEditCatatanDialog> createState() => _AddEditCatatanDialogState();
}

class _AddEditCatatanDialogState extends State<_AddEditCatatanDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController jumlahController = TextEditingController();
  final TextEditingController satuanController = TextEditingController();
  final TextEditingController kodeBatchController = TextEditingController();
  final TextEditingController catatanController = TextEditingController();
  
  DateTime selectedTanggalSemai = DateTime.now();
  DateTime? selectedTanggalPanenTarget;
  String? selectedIdBenih;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.catatan != null) {
      final catatan = widget.catatan!;
      selectedTanggalSemai = catatan.tanggalSemai;
      selectedIdBenih = catatan.idBenih;
      jumlahController.text = catatan.jumlah.toString();
      satuanController.text = catatan.satuan ?? '';
      kodeBatchController.text = catatan.kodeBatch ?? '';
      selectedTanggalPanenTarget = catatan.tanggalPanenTarget;
      catatanController.text = catatan.catatan ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.catatan == null ? 'Tambah Catatan Pembenihan' : 'Edit Catatan Pembenihan'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tanggal Semai
                InkWell(
                  onTap: () => _selectTanggalSemai(),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Semai',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(selectedTanggalSemai),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Jenis Benih
                Consumer<BenihProvider>(
                  builder: (context, benihProvider, child) {
                    return DropdownButtonFormField<String>(
                      value: selectedIdBenih,
                      decoration: const InputDecoration(
                        labelText: 'Jenis Benih',
                        border: OutlineInputBorder(),
                      ),
                      items: benihProvider.jenisBenihList.map((benih) {
                        return DropdownMenuItem(
                          value: benih.idBenih,
                          child: Text(benih.namaBenih),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedIdBenih = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Pilih jenis benih';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                
                // Jumlah
                TextFormField(
                  controller: jumlahController,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan jumlah';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Masukkan angka yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Satuan
                TextFormField(
                  controller: satuanController,
                  decoration: const InputDecoration(
                    labelText: 'Satuan',
                    hintText: 'tray, hampan, dll',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Kode Batch
                TextFormField(
                  controller: kodeBatchController,
                  decoration: const InputDecoration(
                    labelText: 'Kode Batch',
                    hintText: 'Opsional',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Tanggal Panen Target
                InkWell(
                  onTap: () => _selectTanggalPanenTarget(),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Panen Target',
                      hintText: 'Opsional',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      selectedTanggalPanenTarget != null
                          ? DateFormat('dd/MM/yyyy').format(selectedTanggalPanenTarget!)
                          : 'Pilih tanggal',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Catatan
                TextFormField(
                  controller: catatanController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan',
                    hintText: 'Opsional',
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
        ElevatedButton(
          onPressed: isLoading ? null : _saveCatatan,
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.catatan == null ? 'Tambah' : 'Simpan'),
        ),
      ],
    );
  }

  Future<void> _selectTanggalSemai() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedTanggalSemai,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedTanggalSemai) {
      setState(() {
        selectedTanggalSemai = picked;
      });
    }
  }

  Future<void> _selectTanggalPanenTarget() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedTanggalPanenTarget ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        selectedTanggalPanenTarget = picked;
      });
    }
  }

  Future<void> _saveCatatan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final benihProvider = Provider.of<BenihProvider>(context, listen: false);

      bool success;
      if (widget.catatan == null) {
        // Add new
        success = await benihProvider.tambahCatatanPembenihan(
          tanggalSemai: selectedTanggalSemai,
          idBenih: selectedIdBenih!,
          jumlah: int.parse(jumlahController.text),
          satuan: satuanController.text.isNotEmpty ? satuanController.text : null,
          kodeBatch: kodeBatchController.text.isNotEmpty ? kodeBatchController.text : null,
          tanggalPanenTarget: selectedTanggalPanenTarget,
          catatan: catatanController.text.isNotEmpty ? catatanController.text : null,
          dicatatOleh: authProvider.user?.idPengguna ?? '',
        );
      } else {
        // Update existing
        success = await benihProvider.updateCatatanPembenihan(
          widget.catatan!.idPembenihan,
          {
            'tanggal_semai': selectedTanggalSemai,
            'id_benih': selectedIdBenih!,
            'jumlah': int.parse(jumlahController.text),
            'satuan': satuanController.text.isNotEmpty ? satuanController.text : null,
            'kode_batch': kodeBatchController.text.isNotEmpty ? kodeBatchController.text : null,
            'tanggal_panen_target': selectedTanggalPanenTarget,
            'catatan': catatanController.text.isNotEmpty ? catatanController.text : null,
          },
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.catatan == null
                    ? 'Catatan pembenihan berhasil ditambahkan'
                    : 'Catatan pembenihan berhasil diupdate',
              ),
              backgroundColor: Colors.green,
            ),
          );
          widget.onSaved();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.catatan == null
                    ? 'Gagal menambahkan catatan pembenihan'
                    : 'Gagal mengupdate catatan pembenihan',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    jumlahController.dispose();
    satuanController.dispose();
    kodeBatchController.dispose();
    catatanController.dispose();
    super.dispose();
  }
}