import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/benih_provider.dart';
import '../models/jenis_benih_model.dart';

class JenisBenihScreen extends StatefulWidget {
  const JenisBenihScreen({super.key});

  @override
  State<JenisBenihScreen> createState() => _JenisBenihScreenState();
}

class _JenisBenihScreenState extends State<JenisBenihScreen> {
  @override
  void initState() {
    super.initState();
    // Load data saat screen pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final benihProvider = Provider.of<BenihProvider>(context, listen: false);
      benihProvider.initializeDefaultData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jenis Benih'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showTambahBenihDialog(context),
          ),
        ],
      ),
      body: Consumer<BenihProvider>(
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
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${benihProvider.errorMessage}',
                    style: TextStyle(color: Colors.red.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      benihProvider.clearError();
                      benihProvider.loadJenisBenihAktif();
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (benihProvider.jenisBenihList.isEmpty) {
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
                    'Belum ada data jenis benih',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showTambahBenihDialog(context),
                    child: const Text('Tambah Jenis Benih'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => benihProvider.loadJenisBenihAktif(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: benihProvider.jenisBenihList.length,
              itemBuilder: (context, index) {
                final benih = benihProvider.jenisBenihList[index];
                return _buildBenihCard(context, benih, benihProvider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBenihCard(BuildContext context, JenisBenihModel benih, BenihProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Icon(
            Icons.eco,
            color: Colors.green.shade600,
          ),
        ),
        title: Text(
          benih.namaBenih,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (benih.pemasok != null)
              Text('Pemasok: ${benih.pemasok}'),
            if (benih.hargaPerSatuan != null && benih.hargaPerSatuan! > 0)
              Text('Harga: Rp ${_formatCurrency(benih.hargaPerSatuan!)}'),
            if (benih.jenisSatuan != null && benih.ukuranSatuan != null)
              Text('Satuan: ${benih.ukuranSatuan} ${benih.jenisSatuan}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditBenihDialog(context, benih);
                break;
              case 'delete':
                _showDeleteConfirmation(context, benih, provider);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Hapus', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTambahBenihDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final namaController = TextEditingController();
    final pemasokController = TextEditingController();
    final hargaController = TextEditingController();
    final jenisSatuanController = TextEditingController();
    final ukuranSatuanController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Jenis Benih'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Benih *',
                    hintText: 'Contoh: Selada Grand Rapid',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama benih harus diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: pemasokController,
                  decoration: const InputDecoration(
                    labelText: 'Pemasok',
                    hintText: 'Contoh: PT. Benih Unggul',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: hargaController,
                  decoration: const InputDecoration(
                    labelText: 'Harga per Satuan',
                    hintText: 'Contoh: 50000',
                    prefixText: 'Rp ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: jenisSatuanController,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Satuan',
                    hintText: 'Contoh: gram, biji, pack',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: ukuranSatuanController,
                  decoration: const InputDecoration(
                    labelText: 'Ukuran Satuan',
                    hintText: 'Contoh: 8 gram, 1000 biji',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final provider = Provider.of<BenihProvider>(context, listen: false);
                
                final success = await provider.tambahJenisBenih(
                  namaBenih: namaController.text.trim(),
                  pemasok: pemasokController.text.trim().isEmpty ? null : pemasokController.text.trim(),
                  hargaPerSatuan: hargaController.text.trim().isEmpty ? null : double.tryParse(hargaController.text.trim()),
                  jenisSatuan: jenisSatuanController.text.trim().isEmpty ? null : jenisSatuanController.text.trim(),
                  ukuranSatuan: ukuranSatuanController.text.trim().isEmpty ? null : ukuranSatuanController.text.trim(),
                );

                if (success && context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Jenis benih berhasil ditambahkan'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showEditBenihDialog(BuildContext context, JenisBenihModel benih) {
    final formKey = GlobalKey<FormState>();
    final namaController = TextEditingController(text: benih.namaBenih);
    final pemasokController = TextEditingController(text: benih.pemasok ?? '');
    final hargaController = TextEditingController(
      text: benih.hargaPerSatuan != null ? benih.hargaPerSatuan.toString() : '',
    );
    final jenisSatuanController = TextEditingController(text: benih.jenisSatuan ?? '');
    final ukuranSatuanController = TextEditingController(text: benih.ukuranSatuan ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Jenis Benih'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Benih *',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama benih harus diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: pemasokController,
                  decoration: const InputDecoration(
                    labelText: 'Pemasok',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: hargaController,
                  decoration: const InputDecoration(
                    labelText: 'Harga per Satuan',
                    prefixText: 'Rp ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: jenisSatuanController,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Satuan',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: ukuranSatuanController,
                  decoration: const InputDecoration(
                    labelText: 'Ukuran Satuan',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final provider = Provider.of<BenihProvider>(context, listen: false);
                
                final updateData = {
                  'nama_benih': namaController.text.trim(),
                  'pemasok': pemasokController.text.trim().isEmpty ? null : pemasokController.text.trim(),
                  'harga_per_satuan': hargaController.text.trim().isEmpty ? null : double.tryParse(hargaController.text.trim()),
                  'jenis_satuan': jenisSatuanController.text.trim().isEmpty ? null : jenisSatuanController.text.trim(),
                  'ukuran_satuan': ukuranSatuanController.text.trim().isEmpty ? null : ukuranSatuanController.text.trim(),
                };

                final success = await provider.updateJenisBenih(benih.idBenih, updateData);

                if (success && context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Jenis benih berhasil diupdate'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, JenisBenihModel benih, BenihProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus jenis benih "${benih.namaBenih}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await provider.hapusJenisBenih(benih.idBenih);
              
              if (success && context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Jenis benih berhasil dihapus'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}