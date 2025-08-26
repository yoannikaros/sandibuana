import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/jenis_pupuk_model.dart';
import '../providers/pupuk_provider.dart';
import '../providers/tipe_pupuk_provider.dart';
import 'tipe_pupuk_screen.dart';

class JenisPupukScreen extends StatefulWidget {
  const JenisPupukScreen({super.key});

  @override
  State<JenisPupukScreen> createState() => _JenisPupukScreenState();
}

class _JenisPupukScreenState extends State<JenisPupukScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PupukProvider>().loadJenisPupukAktif();
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Jenis Pupuk',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green[600],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Kelola Tipe Pupuk',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TipePupukScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari pupuk...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          context.read<PupukProvider>().loadJenisPupukAktif();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green[600]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                if (value.isEmpty) {
                  context.read<PupukProvider>().loadJenisPupukAktif();
                } else {
                  context.read<PupukProvider>().searchJenisPupuk(value);
                }
              },
            ),
          ),
          // Content
          Expanded(
            child: Consumer<PupukProvider>(
              builder: (context, pupukProvider, child) {
                if (pupukProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  );
                }

                if (pupukProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Terjadi Kesalahan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          pupukProvider.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            pupukProvider.clearError();
                            pupukProvider.loadJenisPupukAktif();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                if (pupukProvider.jenisPupukList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.eco_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Belum ada data pupuk'
                              : 'Pupuk tidak ditemukan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Tambahkan pupuk pertama Anda'
                              : 'Coba kata kunci lain',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pupukProvider.jenisPupukList.length,
                  itemBuilder: (context, index) {
                    final pupuk = pupukProvider.jenisPupukList[index];
                    return _buildPupukCard(pupuk);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.green[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Color _getStokColor(double stok) {
    if (stok <= 0) {
      return Colors.red[600]!;
    } else if (stok <= 10) {
      return Colors.orange[600]!;
    } else {
      return Colors.green[600]!;
    }
  }

  IconData _getStokIcon(double stok) {
    if (stok <= 0) {
      return Icons.warning;
    } else if (stok <= 10) {
      return Icons.info;
    } else {
      return Icons.check;
    }
  }

  void _showStokDialog(JenisPupukModel pupuk, {required bool isAdd}) {
    final formKey = GlobalKey<FormState>();
    final stokController = TextEditingController();
    final keteranganController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAdd ? 'Tambah Stok' : 'Kurangi Stok'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pupuk: ${pupuk.namaPupuk}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Stok saat ini: ${pupuk.stok.toStringAsFixed(1)} kg/L'),
              const SizedBox(height: 16),
              TextFormField(
                controller: stokController,
                decoration: InputDecoration(
                  labelText: '${isAdd ? 'Jumlah Tambah' : 'Jumlah Kurang'} (kg/L)',
                  border: const OutlineInputBorder(),
                  suffixText: 'kg/L',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Jumlah harus diisi';
                  }
                  final jumlah = double.tryParse(value.trim());
                  if (jumlah == null || jumlah <= 0) {
                    return 'Jumlah harus berupa angka positif';
                  }
                  if (!isAdd && jumlah > pupuk.stok) {
                    return 'Jumlah tidak boleh melebihi stok saat ini';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: keteranganController,
                decoration: const InputDecoration(
                  labelText: 'Keterangan',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final jumlah = double.parse(stokController.text.trim());
                final keterangan = keteranganController.text.trim();
                
                final provider = context.read<PupukProvider>();
                bool success;
                
                if (isAdd) {
                   success = await provider.tambahStokPupuk(
                     pupuk.id,
                     jumlah,
                   );
                 } else {
                   success = await provider.kurangiStokPupuk(
                     pupuk.id,
                     jumlah,
                   );
                 }

                if (!mounted) return;

                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAdd
                            ? 'Stok berhasil ditambahkan'
                            : 'Stok berhasil dikurangi',
                      ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: isAdd ? Colors.green[600] : Colors.orange[600],
              foregroundColor: Colors.white,
            ),
            child: Text(isAdd ? 'Tambah' : 'Kurangi'),
          ),
        ],
      ),
    );
  }

  Widget _buildPupukCard(JenisPupukModel pupuk) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                        pupuk.namaPupuk,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (pupuk.kodePupuk != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            pupuk.kodePupuk!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getTipeColor(pupuk.tipe),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    pupuk.tipe.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showAddEditDialog(pupuk: pupuk);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(pupuk);
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
            if (pupuk.keterangan != null && pupuk.keterangan!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                pupuk.keterangan!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 8),
            // Stok Information
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStokColor(pupuk.stok),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStokIcon(pupuk.stok),
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Stok: ${pupuk.stok.toStringAsFixed(1)} kg/L',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  pupuk.aktif ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: pupuk.aktif ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  pupuk.aktif ? 'Aktif' : 'Tidak Aktif',
                  style: TextStyle(
                    fontSize: 12,
                    color: pupuk.aktif ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                // Quick stock action buttons
                if (pupuk.aktif) ...[
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    onPressed: () => _showStokDialog(pupuk, isAdd: true),
                    tooltip: 'Tambah Stok',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 18),
                    onPressed: () => _showStokDialog(pupuk, isAdd: false),
                    tooltip: 'Kurangi Stok',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTipeColor(String tipe) {
    switch (tipe.toLowerCase()) {
      case 'makro':
        return Colors.green[600]!;
      case 'mikro':
        return Colors.blue[600]!;
      case 'organik':
        return Colors.orange[600]!;
      case 'kimia':
        return Colors.purple[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  void _showAddEditDialog({JenisPupukModel? pupuk}) {
    final isEdit = pupuk != null;
    final formKey = GlobalKey<FormState>();
    final namaController = TextEditingController(text: pupuk?.namaPupuk ?? '');
    final kodeController = TextEditingController(text: pupuk?.kodePupuk ?? '');
    final keteranganController = TextEditingController(text: pupuk?.keterangan ?? '');
    final stokController = TextEditingController(text: pupuk?.stok.toString() ?? '0');
    String selectedTipe = pupuk?.tipe ?? 'makro';
    bool isAktif = pupuk?.aktif ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit Pupuk' : 'Tambah Pupuk'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: namaController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Pupuk *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama pupuk harus diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: kodeController,
                    decoration: const InputDecoration(
                      labelText: 'Kode Pupuk',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Consumer<TipePupukProvider>(
                    builder: (context, tipePupukProvider, child) {
                      final tipePupukOptions = tipePupukProvider.tipePupukOptions;
                      final tipePupukDisplayOptions = tipePupukProvider.tipePupukDisplayOptions;
                      
                      // Ensure selectedTipe is valid
                      if (!tipePupukOptions.contains(selectedTipe) && tipePupukOptions.isNotEmpty) {
                        selectedTipe = tipePupukOptions.first;
                      }
                      
                      return DropdownButtonFormField<String>(
                        value: selectedTipe,
                        decoration: const InputDecoration(
                          labelText: 'Tipe Pupuk *',
                          border: OutlineInputBorder(),
                        ),
                        items: tipePupukOptions.asMap().entries
                            .map((entry) => DropdownMenuItem(
                                  value: entry.value,
                                  child: Text(tipePupukDisplayOptions.length > entry.key 
                                      ? tipePupukDisplayOptions[entry.key]
                                      : entry.value.toUpperCase()),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedTipe = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Tipe pupuk harus dipilih';
                          }
                          return null;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: stokController,
                    decoration: const InputDecoration(
                      labelText: 'Stok (kg/liter)',
                      border: OutlineInputBorder(),
                      suffixText: 'kg/L',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Stok harus diisi';
                      }
                      final stok = double.tryParse(value.trim());
                      if (stok == null || stok < 0) {
                        return 'Stok harus berupa angka positif';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: keteranganController,
                    decoration: const InputDecoration(
                      labelText: 'Keterangan',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: isAktif,
                        onChanged: (value) {
                          setState(() {
                            isAktif = value!;
                          });
                        },
                      ),
                      const Text('Aktif'),
                    ],
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
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final pupukData = JenisPupukModel(
                    id: pupuk?.id ?? '',
                    namaPupuk: namaController.text.trim(),
                    kodePupuk: kodeController.text.trim().isEmpty
                        ? null
                        : kodeController.text.trim(),
                    tipe: selectedTipe,
                    keterangan: keteranganController.text.trim().isEmpty
                        ? null
                        : keteranganController.text.trim(),
                    aktif: isAktif,
                    stok: double.parse(stokController.text.trim()),
                  );

                  final provider = context.read<PupukProvider>();
                  bool success;
                  if (isEdit) {
                    success = await provider.updateJenisPupuk(pupuk!.id, pupukData);
                  } else {
                    success = await provider.tambahJenisPupuk(pupukData);
                  }

                  if (!mounted) return;

                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEdit
                              ? 'Pupuk berhasil diupdate'
                              : 'Pupuk berhasil ditambahkan',
                        ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
              child: Text(isEdit ? 'Update' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(JenisPupukModel pupuk) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Apakah Anda yakin ingin menghapus pupuk "${pupuk.namaPupuk}"?\n\n'
          'Data ini akan dinonaktifkan dan tidak akan muncul dalam daftar aktif.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = context.read<PupukProvider>();
              final success = await provider.hapusJenisPupuk(pupuk.id);
              
              if (!mounted) return;
              
              Navigator.pop(context);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pupuk berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(provider.error ?? 'Gagal menghapus pupuk'),
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