import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/jenis_pelanggan_provider.dart';
import '../models/jenis_pelanggan_model.dart';

class JenisPelangganScreen extends StatefulWidget {
  const JenisPelangganScreen({Key? key}) : super(key: key);

  @override
  State<JenisPelangganScreen> createState() => _JenisPelangganScreenState();
}

class _JenisPelangganScreenState extends State<JenisPelangganScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JenisPelangganProvider>().loadJenisPelanggan();
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
        title: const Text('Kelola Jenis Pelanggan'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showInactive ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showInactive = !_showInactive;
              });
            },
            tooltip: _showInactive ? 'Sembunyikan Nonaktif' : 'Tampilkan Nonaktif',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari jenis pelanggan...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<JenisPelangganProvider>().loadJenisPelanggan();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (value.isEmpty) {
                  context.read<JenisPelangganProvider>().loadJenisPelanggan();
                } else {
                  context.read<JenisPelangganProvider>().cariJenisPelanggan(value);
                }
              },
            ),
          ),
          // List
          Expanded(
            child: Consumer<JenisPelangganProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${provider.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            provider.clearError();
                            provider.loadJenisPelanggan();
                          },
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                final jenisPelangganList = _showInactive 
                    ? provider.jenisPelangganList 
                    : provider.jenisPelangganAktif;

                if (jenisPelangganList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'Tidak ada jenis pelanggan yang ditemukan'
                              : 'Belum ada jenis pelanggan',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: jenisPelangganList.length,
                  itemBuilder: (context, index) {
                    final jenisPelanggan = jenisPelangganList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: jenisPelanggan.aktif ? Colors.blue : Colors.grey,
                          child: Text(
                            jenisPelanggan.kode.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          jenisPelanggan.nama,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: jenisPelanggan.aktif ? Colors.black : Colors.grey,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kode: ${jenisPelanggan.kode}'),
                            if (jenisPelanggan.deskripsi != null)
                              Text(jenisPelanggan.deskripsi!),
                            Text(
                              'Status: ${jenisPelanggan.aktif ? "Aktif" : "Nonaktif"}',
                              style: TextStyle(
                                color: jenisPelanggan.aktif ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _showTambahEditDialog(context, jenisPelanggan: jenisPelanggan);
                                break;
                              case 'toggle':
                                if (jenisPelanggan.aktif) {
                                  _showHapusDialog(context, jenisPelanggan);
                                } else {
                                  _restoreJenisPelanggan(context, jenisPelanggan);
                                }
                                break;
                              case 'delete':
                                _showHapusPermanen(context, jenisPelanggan);
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
                            PopupMenuItem(
                              value: 'toggle',
                              child: ListTile(
                                leading: Icon(
                                  jenisPelanggan.aktif ? Icons.visibility_off : Icons.restore,
                                ),
                                title: Text(jenisPelanggan.aktif ? 'Nonaktifkan' : 'Aktifkan'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            if (!jenisPelanggan.aktif)
                              const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete_forever, color: Colors.red),
                                  title: Text('Hapus Permanen', style: TextStyle(color: Colors.red)),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTambahEditDialog(context),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showTambahEditDialog(BuildContext context, {JenisPelangganModel? jenisPelanggan}) {
    final isEdit = jenisPelanggan != null;
    final formKey = GlobalKey<FormState>();
    final namaController = TextEditingController(text: jenisPelanggan?.nama ?? '');
    final kodeController = TextEditingController(text: jenisPelanggan?.kode ?? '');
    final deskripsiController = TextEditingController(text: jenisPelanggan?.deskripsi ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Jenis Pelanggan' : 'Tambah Jenis Pelanggan'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Jenis Pelanggan',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: kodeController,
                  decoration: const InputDecoration(
                    labelText: 'Kode Jenis Pelanggan',
                    border: OutlineInputBorder(),
                    hintText: 'contoh: restoran, hotel, individu',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kode tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: deskripsiController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (Opsional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
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
                final provider = Provider.of<JenisPelangganProvider>(context, listen: false);
                
                final newJenisPelanggan = JenisPelangganModel(
                  id: jenisPelanggan?.id,
                  nama: namaController.text.trim(),
                  kode: kodeController.text.trim().toLowerCase(),
                  deskripsi: deskripsiController.text.trim().isEmpty 
                      ? null 
                      : deskripsiController.text.trim(),
                  dibuatPada: jenisPelanggan?.dibuatPada ?? DateTime.now(),
                );
                
                bool success;
                if (isEdit) {
                  success = await provider.updateJenisPelanggan(jenisPelanggan.id!, newJenisPelanggan);
                } else {
                  success = await provider.tambahJenisPelanggan(newJenisPelanggan);
                }
                
                Navigator.of(context).pop();
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEdit ? 'Jenis pelanggan berhasil diupdate' : 'Jenis pelanggan berhasil ditambahkan'),
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
            child: Text(isEdit ? 'Update' : 'Tambah'),
          ),
        ],
      ),
    );
  }

  void _showHapusDialog(BuildContext context, JenisPelangganModel jenisPelanggan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text('Apakah Anda yakin ingin menonaktifkan jenis pelanggan "${jenisPelanggan.nama}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<JenisPelangganProvider>(context, listen: false);
              final success = await provider.hapusJenisPelanggan(jenisPelanggan.id!);
              
              Navigator.of(context).pop();
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Jenis pelanggan berhasil dinonaktifkan'),
                    backgroundColor: Colors.orange,
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Nonaktifkan'),
          ),
        ],
      ),
    );
  }

  void _restoreJenisPelanggan(BuildContext context, JenisPelangganModel jenisPelanggan) async {
    final provider = Provider.of<JenisPelangganProvider>(context, listen: false);
    final success = await provider.restoreJenisPelanggan(jenisPelanggan.id!);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jenis pelanggan berhasil diaktifkan kembali'),
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

  void _showHapusPermanen(BuildContext context, JenisPelangganModel jenisPelanggan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus Permanen'),
        content: Text(
          'Apakah Anda yakin ingin menghapus permanen jenis pelanggan "${jenisPelanggan.nama}"?\n\nTindakan ini tidak dapat dibatalkan!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<JenisPelangganProvider>(context, listen: false);
              final success = await provider.hapusJenisPelangganPermanen(jenisPelanggan.id!);
              
              Navigator.of(context).pop();
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Jenis pelanggan berhasil dihapus permanen'),
                    backgroundColor: Colors.red,
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus Permanen'),
          ),
        ],
      ),
    );
  }
}