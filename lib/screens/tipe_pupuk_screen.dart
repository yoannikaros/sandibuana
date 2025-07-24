import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tipe_pupuk_provider.dart';
import '../models/tipe_pupuk_model.dart';

class TipePupukScreen extends StatefulWidget {
  const TipePupukScreen({Key? key}) : super(key: key);

  @override
  State<TipePupukScreen> createState() => _TipePupukScreenState();
}

class _TipePupukScreenState extends State<TipePupukScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TipePupukProvider>().loadTipePupuk();
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
        title: const Text('Kelola Tipe Pupuk'),
        backgroundColor: Colors.green,
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
                hintText: 'Cari tipe pupuk...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<TipePupukProvider>().loadTipePupuk();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (value.isEmpty) {
                  context.read<TipePupukProvider>().loadTipePupuk();
                } else {
                  context.read<TipePupukProvider>().cariTipePupuk(value);
                }
              },
            ),
          ),
          // List
          Expanded(
            child: Consumer<TipePupukProvider>(
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
                            provider.loadTipePupuk();
                          },
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                final tipePupukList = _showInactive 
                    ? provider.tipePupukList 
                    : provider.tipePupukAktif;

                if (tipePupukList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.eco_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'Tidak ada tipe pupuk yang ditemukan'
                              : 'Belum ada tipe pupuk',
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
                  itemCount: tipePupukList.length,
                  itemBuilder: (context, index) {
                    final tipePupuk = tipePupukList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: tipePupuk.aktif ? Colors.green : Colors.grey,
                          child: Text(
                            tipePupuk.kode.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          tipePupuk.nama,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: tipePupuk.aktif ? Colors.black : Colors.grey,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kode: ${tipePupuk.kode}'),
                            if (tipePupuk.deskripsi != null)
                              Text(tipePupuk.deskripsi!),
                            Text(
                              'Status: ${tipePupuk.aktif ? "Aktif" : "Nonaktif"}',
                              style: TextStyle(
                                color: tipePupuk.aktif ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _showTambahEditDialog(context, tipePupuk: tipePupuk);
                                break;
                              case 'toggle':
                                if (tipePupuk.aktif) {
                                  _showHapusDialog(context, tipePupuk);
                                } else {
                                  _restoreTipePupuk(context, tipePupuk);
                                }
                                break;
                              case 'delete':
                                _showHapusPermanen(context, tipePupuk);
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
                                  tipePupuk.aktif ? Icons.visibility_off : Icons.restore,
                                ),
                                title: Text(tipePupuk.aktif ? 'Nonaktifkan' : 'Aktifkan'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            if (!tipePupuk.aktif)
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
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showTambahEditDialog(BuildContext context, {TipePupukModel? tipePupuk}) {
    final isEdit = tipePupuk != null;
    final formKey = GlobalKey<FormState>();
    final namaController = TextEditingController(text: tipePupuk?.nama ?? '');
    final kodeController = TextEditingController(text: tipePupuk?.kode ?? '');
    final deskripsiController = TextEditingController(text: tipePupuk?.deskripsi ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Tipe Pupuk' : 'Tambah Tipe Pupuk'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Tipe Pupuk',
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
                    labelText: 'Kode Tipe Pupuk',
                    border: OutlineInputBorder(),
                    hintText: 'contoh: makro, mikro, organik',
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
                final provider = Provider.of<TipePupukProvider>(context, listen: false);
                
                final newTipePupuk = TipePupukModel(
                  id: tipePupuk?.id,
                  nama: namaController.text.trim(),
                  kode: kodeController.text.trim().toLowerCase(),
                  deskripsi: deskripsiController.text.trim().isEmpty 
                      ? null 
                      : deskripsiController.text.trim(),
                  dibuatPada: tipePupuk?.dibuatPada ?? DateTime.now(),
                );
                
                bool success;
                if (isEdit) {
                  success = await provider.updateTipePupuk(tipePupuk.id!, newTipePupuk);
                } else {
                  success = await provider.tambahTipePupuk(newTipePupuk);
                }
                
                Navigator.of(context).pop();
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEdit ? 'Tipe pupuk berhasil diupdate' : 'Tipe pupuk berhasil ditambahkan'),
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

  void _showHapusDialog(BuildContext context, TipePupukModel tipePupuk) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text('Apakah Anda yakin ingin menonaktifkan tipe pupuk "${tipePupuk.nama}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<TipePupukProvider>(context, listen: false);
              final success = await provider.hapusTipePupuk(tipePupuk.id!);
              
              Navigator.of(context).pop();
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tipe pupuk berhasil dinonaktifkan'),
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

  void _restoreTipePupuk(BuildContext context, TipePupukModel tipePupuk) async {
    final provider = Provider.of<TipePupukProvider>(context, listen: false);
    final success = await provider.restoreTipePupuk(tipePupuk.id!);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tipe pupuk berhasil diaktifkan kembali'),
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

  void _showHapusPermanen(BuildContext context, TipePupukModel tipePupuk) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus Permanen'),
        content: Text(
          'Apakah Anda yakin ingin menghapus permanen tipe pupuk "${tipePupuk.nama}"?\n\nTindakan ini tidak dapat dibatalkan!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<TipePupukProvider>(context, listen: false);
              final success = await provider.hapusTipePupukPermanen(tipePupuk.id!);
              
              Navigator.of(context).pop();
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tipe pupuk berhasil dihapus permanen'),
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