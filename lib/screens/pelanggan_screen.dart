import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/pelanggan_model.dart';
import '../providers/pelanggan_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/jenis_pelanggan_provider.dart';

import 'jenis_pelanggan_screen.dart';

class PelangganScreen extends StatefulWidget {
  const PelangganScreen({super.key});

  @override
  State<PelangganScreen> createState() => _PelangganScreenState();
}

class _PelangganScreenState extends State<PelangganScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedJenis;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize Indonesian locale for DateFormat
    initializeDateFormatting('id_ID', null);
    // Load data saat screen pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    try {
      final pelangganProvider = Provider.of<PelangganProvider>(context, listen: false);
      await pelangganProvider.loadPelangganAktif();
      // Enable real-time updates
      pelangganProvider.listenToRealtimeUpdates();

    } catch (e) {
      print('Error initializing pelanggan data: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Auto refresh when app becomes active
      _refreshData();
    }
  }

  void _refreshData() async {
    try {
      final pelangganProvider = Provider.of<PelangganProvider>(context, listen: false);
      await pelangganProvider.loadPelangganAktif();

    } catch (e) {
      print('Error refreshing data: $e');
    }
  }



  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditDialog({PelangganModel? pelanggan}) {
    final isEdit = pelanggan != null;
    final formKey = GlobalKey<FormState>();
    
    final namaController = TextEditingController(text: pelanggan?.namaPelanggan ?? '');
    final namaTempatUsahaController = TextEditingController(text: pelanggan?.namaTempatUsaha ?? '');
    final kontakController = TextEditingController(text: pelanggan?.kontakPerson ?? '');
    final teleponController = TextEditingController(text: pelanggan?.telepon ?? '');
    final alamatController = TextEditingController(text: pelanggan?.alamat ?? '');
    String? selectedJenis = pelanggan?.jenisPelanggan;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit Pelanggan' : 'Tambah Pelanggan'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: namaController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Pelanggan',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama pelanggan harus diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Consumer<JenisPelangganProvider>(
                    builder: (context, jenisPelangganProvider, child) {
                      final jenisPelangganOptions = jenisPelangganProvider.jenisPelangganOptions;
                      final jenisPelangganDisplayOptions = jenisPelangganProvider.jenisPelangganDisplayOptions;
                      
                      // Ensure selectedJenis is valid
                      if (selectedJenis == null || !jenisPelangganOptions.contains(selectedJenis)) {
                        selectedJenis = jenisPelangganOptions.isNotEmpty ? jenisPelangganOptions.first : 'restoran';
                      }
                      
                      return DropdownButtonFormField<String>(
                        value: selectedJenis,
                        decoration: const InputDecoration(
                          labelText: 'Jenis Pelanggan',
                          border: OutlineInputBorder(),
                        ),
                        items: jenisPelangganOptions.asMap().entries
                            .map((entry) => DropdownMenuItem(
                                  value: entry.value,
                                  child: Text(jenisPelangganDisplayOptions.length > entry.key 
                                      ? jenisPelangganDisplayOptions[entry.key]
                                      : entry.value),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedJenis = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Jenis pelanggan harus dipilih';
                          }
                          return null;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: namaTempatUsahaController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Tempat Usaha',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: kontakController,
                    decoration: const InputDecoration(
                      labelText: 'Kontak Person',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: teleponController,
                    decoration: const InputDecoration(
                      labelText: 'Telepon',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: alamatController,
                    decoration: const InputDecoration(
                      labelText: 'Alamat',
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
                  final pelangganProvider = Provider.of<PelangganProvider>(context, listen: false);
                  
                  final newPelanggan = PelangganModel(
                    id: pelanggan?.id ?? '',
                    namaPelanggan: namaController.text,
                    jenisPelanggan: selectedJenis ?? 'restoran',
                    namaTempatUsaha: namaTempatUsahaController.text.isEmpty ? null : namaTempatUsahaController.text,
                    kontakPerson: kontakController.text.isEmpty ? null : kontakController.text,
                    telepon: teleponController.text.isEmpty ? null : teleponController.text,
                    alamat: alamatController.text.isEmpty ? null : alamatController.text,
                    aktif: pelanggan?.aktif ?? true,
                    dibuatPada: pelanggan?.dibuatPada ?? DateTime.now(),
                  );

                  bool success;
                  if (isEdit) {
                    success = await pelangganProvider.updatePelanggan(pelanggan!.id, newPelanggan);
                  } else {
                    success = await pelangganProvider.tambahPelanggan(newPelanggan);
                  }

                  if (success) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit ? 'Pelanggan berhasil diupdate' : 'Pelanggan berhasil ditambahkan'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(pelangganProvider.error ?? 'Terjadi kesalahan'),
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
      ),
    );
  }

  void _showDeleteConfirmation(PelangganModel pelanggan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus pelanggan "${pelanggan.namaPelanggan}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final pelangganProvider = Provider.of<PelangganProvider>(context, listen: false);
              final success = await pelangganProvider.hapusPelanggan(pelanggan.id);
              
              Navigator.of(context).pop();
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pelanggan berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(pelangganProvider.error ?? 'Gagal menghapus pelanggan'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _applyFilters() {
    final pelangganProvider = Provider.of<PelangganProvider>(context, listen: false);
    
    if (_selectedJenis != null) {
      pelangganProvider.filterPelangganByJenis(_selectedJenis!);
    } else {
      pelangganProvider.clearFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Pelanggan'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Kelola Jenis Pelanggan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const JenisPelangganScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sinkronisasi Firebase',
            onPressed: () async {
              final pelangganProvider = context.read<PelangganProvider>();
              
              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 16),
                      Text('Menyinkronkan data...'),
                    ],
                  ),
                  duration: Duration(seconds: 3),
                ),
              );
              
              try {
                // Force refresh from Firebase
                await pelangganProvider.forceRefresh();
                
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data berhasil disinkronkan dengan Firebase'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal sinkronisasi: $e'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () async {
              final pelangganProvider = context.read<PelangganProvider>();
              await pelangganProvider.loadPelangganAktif();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data berhasil diperbarui'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<PelangganProvider>(
        builder: (context, pelangganProvider, child) {
          return Column(
            children: [
              // Search and Filter Section
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.grey[100],
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari pelanggan...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  pelangganProvider.loadPelangganAktif();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        if (value.isEmpty) {
                          pelangganProvider.loadPelangganAktif();
                        } else {
                          pelangganProvider.searchPelanggan(value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('Semua'),
                            selected: _selectedJenis == null,
                            onSelected: (selected) {
                              setState(() {
                                _selectedJenis = null;
                              });
                              _applyFilters();
                            },
                          ),
                          const SizedBox(width: 8),
                          Consumer<JenisPelangganProvider>(
                            builder: (context, jenisPelangganProvider, child) {
                              final jenisPelangganOptions = jenisPelangganProvider.jenisPelangganOptions;
                              final jenisPelangganDisplayOptions = jenisPelangganProvider.jenisPelangganDisplayOptions;
                              
                              return Row(
                                children: jenisPelangganOptions.asMap().entries.map((entry) {
                                  final jenis = entry.value;
                                  final displayName = jenisPelangganDisplayOptions.length > entry.key 
                                      ? jenisPelangganDisplayOptions[entry.key]
                                      : jenis;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(displayName),
                                      selected: _selectedJenis == jenis,
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedJenis = selected ? jenis : null;
                                        });
                                        _applyFilters();
                                      },
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Sync Status Indicator removed
              
              // Content
              Expanded(
                child: pelangganProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : pelangganProvider.error != null
                        ? Center(
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
                                  'Error: ${pelangganProvider.error}',
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        pelangganProvider.clearError();
                                        pelangganProvider.loadPelangganAktif();
                                      },
                                      child: const Text('Coba Lagi'),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        try {
                                          await pelangganProvider.forceRefresh();
                                        } catch (e) {
                                          // Error handled by provider
                                        }
                                      },
                                      icon: const Icon(Icons.sync),
                                      label: const Text('Sync Firebase'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : pelangganProvider.pelangganList.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Belum ada data pelanggan',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: pelangganProvider.pelangganList.length,
                                itemBuilder: (context, index) {
                                  final pelanggan = pelangganProvider.pelangganList[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    elevation: 2,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: _getJenisColor(pelanggan.jenisPelanggan),
                                        child: Icon(
                                          _getJenisIcon(pelanggan.jenisPelanggan),
                                          color: Colors.white,
                                        ),
                                      ),
                                      title: Text(
                                        pelanggan.namaPelanggan,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pelanggan.jenisPelangganDisplay,
                                            style: TextStyle(
                                              color: _getJenisColor(pelanggan.jenisPelanggan),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (pelanggan.namaTempatUsaha != null)
                                            Text('Tempat Usaha: ${pelanggan.namaTempatUsaha}'),
                                          if (pelanggan.kontakPerson != null)
                                            Text('Kontak: ${pelanggan.kontakPerson}'),
                                          if (pelanggan.telepon != null)
                                            Text('Telepon: ${pelanggan.telepon}'),
                                          Text(
                                            'Dibuat: ${DateFormat('dd/MM/yyyy').format(pelanggan.dibuatPada)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: PopupMenuButton<String>(
                                        onSelected: (value) {
                                          switch (value) {
                                            case 'edit':
                                              _showAddEditDialog(pelanggan: pelanggan);
                                              break;
                                            case 'delete':
                                              _showDeleteConfirmation(pelanggan);
                                              break;
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit, size: 20),
                                                SizedBox(width: 8),
                                                Text('Edit'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete, size: 20, color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('Hapus', style: TextStyle(color: Colors.red)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      isThreeLine: true,
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border(top: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Consumer<PelangganProvider>(
          builder: (context, pelangganProvider, child) {
            final totalPelanggan = pelangganProvider.pelangganList.length;
            
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$totalPelanggan pelanggan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      pelangganProvider.error == null ? Icons.check_circle : Icons.error,
                      size: 16,
                      color: pelangganProvider.error == null ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      pelangganProvider.error == null 
                          ? 'Tersinkronisasi'
                          : 'Error sinkronisasi',
                      style: TextStyle(
                        fontSize: 12,
                        color: pelangganProvider.error == null ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Color _getJenisColor(String jenis) {
    switch (jenis) {
      case 'restoran':
        return Colors.orange;
      case 'hotel':
        return Colors.blue;
      case 'individu':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getJenisIcon(String jenis) {
    switch (jenis) {
      case 'restoran':
        return Icons.restaurant;
      case 'hotel':
        return Icons.hotel;
      case 'individu':
        return Icons.person;
      default:
        return Icons.business;
    }
  }
}