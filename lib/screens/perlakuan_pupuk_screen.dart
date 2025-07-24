import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/perlakuan_pupuk_model.dart';
import '../providers/perlakuan_pupuk_provider.dart';
import '../providers/auth_provider.dart';

class PerlakuanPupukScreen extends StatefulWidget {
  const PerlakuanPupukScreen({super.key});

  @override
  State<PerlakuanPupukScreen> createState() => _PerlakuanPupukScreenState();
}

class _PerlakuanPupukScreenState extends State<PerlakuanPupukScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PerlakuanPupukProvider>().loadPerlakuanPupuk();
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
        title: const Text('Kelola Perlakuan Pupuk'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          Consumer<PerlakuanPupukProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: Icon(
                  provider.showActiveOnly ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  provider.toggleShowActiveOnly();
                },
                tooltip: provider.showActiveOnly ? 'Tampilkan Semua' : 'Tampilkan Aktif Saja',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<PerlakuanPupukProvider>().refresh();
            },
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
                hintText: 'Cari perlakuan pupuk...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<PerlakuanPupukProvider>().clearSearch();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                context.read<PerlakuanPupukProvider>().searchPerlakuanPupuk(value);
              },
            ),
          ),
          
          // Status Filter Chips
          Consumer<PerlakuanPupukProvider>(
            builder: (context, provider, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Aktif Saja'),
                      selected: provider.showActiveOnly,
                      onSelected: (selected) {
                        provider.setShowActiveOnly(selected);
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Semua'),
                      selected: !provider.showActiveOnly,
                      onSelected: (selected) {
                        provider.setShowActiveOnly(!selected);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Content
          Expanded(
            child: Consumer<PerlakuanPupukProvider>(
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
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${provider.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.refresh(),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                final perlakuanList = provider.perlakuanPupukList;

                if (perlakuanList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.science_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.searchQuery.isNotEmpty
                              ? 'Tidak ada perlakuan pupuk yang sesuai dengan pencarian'
                              : 'Belum ada perlakuan pupuk',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (provider.searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              provider.clearSearch();
                            },
                            child: const Text('Hapus Filter'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: perlakuanList.length,
                  itemBuilder: (context, index) {
                    final perlakuan = perlakuanList[index];
                    return _buildPerlakuanCard(perlakuan);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPerlakuanCard(PerlakuanPupukModel perlakuan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
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
                        perlakuan.namaPerlakuan,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kode: ${perlakuan.kodePerlakuan}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: perlakuan.isAktif ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    perlakuan.statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showAddEditDialog(perlakuan: perlakuan);
                        break;
                      case 'deactivate':
                        _showDeactivateDialog(perlakuan);
                        break;
                      case 'activate':
                        _showActivateDialog(perlakuan);
                        break;
                      case 'delete':
                        _showDeleteDialog(perlakuan);
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
                    if (perlakuan.isAktif)
                      const PopupMenuItem(
                        value: 'deactivate',
                        child: ListTile(
                          leading: Icon(Icons.visibility_off, color: Colors.orange),
                          title: Text('Nonaktifkan'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                    else
                      const PopupMenuItem(
                        value: 'activate',
                        child: ListTile(
                          leading: Icon(Icons.visibility, color: Colors.green),
                          title: Text('Aktifkan'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Hapus Permanen'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (perlakuan.deskripsi != null && perlakuan.deskripsi!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                perlakuan.deskripsi!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Dibuat oleh: ${perlakuan.dibuatOleh}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(perlakuan.dibuatPada),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditDialog({PerlakuanPupukModel? perlakuan}) {
    final isEdit = perlakuan != null;
    final formKey = GlobalKey<FormState>();
    final kodeController = TextEditingController(text: perlakuan?.kodePerlakuan ?? '');
    final namaController = TextEditingController(text: perlakuan?.namaPerlakuan ?? '');
    final deskripsiController = TextEditingController(text: perlakuan?.deskripsi ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Perlakuan Pupuk' : 'Tambah Perlakuan Pupuk'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: kodeController,
                  decoration: const InputDecoration(
                    labelText: 'Kode Perlakuan',
                    border: OutlineInputBorder(),
                    hintText: 'Contoh: CEF_PTH',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kode perlakuan harus diisi';
                    }
                    if (value.length < 2) {
                      return 'Kode perlakuan minimal 2 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Perlakuan',
                    border: OutlineInputBorder(),
                    hintText: 'Contoh: Pupuk CEF + PTh',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama perlakuan harus diisi';
                    }
                    if (value.length < 3) {
                      return 'Nama perlakuan minimal 3 karakter';
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
                    hintText: 'Deskripsi perlakuan pupuk',
                  ),
                  maxLines: 3,
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
                final userId = context.read<AuthProvider>().user?.idPengguna ?? 'unknown';
                bool success;
                
                if (isEdit) {
                  success = await context.read<PerlakuanPupukProvider>().updatePerlakuanPupuk(
                    perlakuan.idPerlakuan,
                    {
                      'kode_perlakuan': kodeController.text.trim(),
                      'nama_perlakuan': namaController.text.trim(),
                      'deskripsi': deskripsiController.text.trim().isEmpty 
                          ? null 
                          : deskripsiController.text.trim(),
                      'diupdate_oleh': userId,
                    },
                  );
                } else {
                  success = await context.read<PerlakuanPupukProvider>().addPerlakuanPupuk(
                    kodePerlakuan: kodeController.text.trim(),
                    namaPerlakuan: namaController.text.trim(),
                    deskripsi: deskripsiController.text.trim().isEmpty 
                        ? null 
                        : deskripsiController.text.trim(),
                    dibuatOleh: userId,
                  );
                }
                
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEdit 
                          ? 'Perlakuan pupuk berhasil diupdate' 
                          : 'Perlakuan pupuk berhasil ditambahkan'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.read<PerlakuanPupukProvider>().error ?? 'Terjadi kesalahan'),
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

  void _showDeactivateDialog(PerlakuanPupukModel perlakuan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nonaktifkan Perlakuan Pupuk'),
        content: Text(
          'Apakah Anda yakin ingin menonaktifkan perlakuan pupuk "${perlakuan.namaPerlakuan}"?\n\n'
          'Perlakuan pupuk yang dinonaktifkan tidak akan muncul dalam pilihan dropdown.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final userId = context.read<AuthProvider>().user?.idPengguna ?? 'unknown';
              final success = await context.read<PerlakuanPupukProvider>()
                  .softDeletePerlakuanPupuk(perlakuan.idPerlakuan, userId);
              
              Navigator.pop(context);
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Perlakuan pupuk berhasil dinonaktifkan'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.read<PerlakuanPupukProvider>().error ?? 'Terjadi kesalahan'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Nonaktifkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showActivateDialog(PerlakuanPupukModel perlakuan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aktifkan Perlakuan Pupuk'),
        content: Text(
          'Apakah Anda yakin ingin mengaktifkan kembali perlakuan pupuk "${perlakuan.namaPerlakuan}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final userId = context.read<AuthProvider>().user?.idPengguna ?? 'unknown';
              final success = await context.read<PerlakuanPupukProvider>()
                  .restorePerlakuanPupuk(perlakuan.idPerlakuan, userId);
              
              Navigator.pop(context);
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Perlakuan pupuk berhasil diaktifkan'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.read<PerlakuanPupukProvider>().error ?? 'Terjadi kesalahan'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Aktifkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(PerlakuanPupukModel perlakuan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Permanen'),
        content: Text(
          'Apakah Anda yakin ingin menghapus permanen perlakuan pupuk "${perlakuan.namaPerlakuan}"?\n\n'
          'PERINGATAN: Data yang dihapus tidak dapat dikembalikan!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await context.read<PerlakuanPupukProvider>()
                  .deletePerlakuanPupuk(perlakuan.idPerlakuan);
              
              Navigator.pop(context);
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Perlakuan pupuk berhasil dihapus'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.read<PerlakuanPupukProvider>().error ?? 'Terjadi kesalahan'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus Permanen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}