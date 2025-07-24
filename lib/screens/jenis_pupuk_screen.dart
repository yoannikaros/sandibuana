import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/jenis_pupuk_model.dart';
import '../providers/pupuk_provider.dart';

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
      context.read<PupukProvider>().loadJenisPupuk();
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
                          context.read<PupukProvider>().loadJenisPupuk();
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
                  context.read<PupukProvider>().loadJenisPupuk();
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
                            pupukProvider.loadJenisPupuk();
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
                  DropdownButtonFormField<String>(
                    value: selectedTipe,
                    decoration: const InputDecoration(
                      labelText: 'Tipe Pupuk *',
                      border: OutlineInputBorder(),
                    ),
                    items: context.read<PupukProvider>().tipePupukList
                        .map((tipe) => DropdownMenuItem(
                              value: tipe,
                              child: Text(tipe.toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedTipe = value!;
                      });
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
                  );

                  bool success;
                  if (isEdit) {
                    success = await context
                        .read<PupukProvider>()
                        .updateJenisPupuk(pupuk!.id, pupukData);
                  } else {
                    success = await context
                        .read<PupukProvider>()
                        .tambahJenisPupuk(pupukData);
                  }

                  if (success && mounted) {
                    Navigator.pop(context);
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
              final success = await context
                  .read<PupukProvider>()
                  .hapusJenisPupuk(pupuk.id);
              
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pupuk berhasil dihapus'),
                    backgroundColor: Colors.green,
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