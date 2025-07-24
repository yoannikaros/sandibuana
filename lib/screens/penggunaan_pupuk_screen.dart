import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/penggunaan_pupuk_model.dart';
import '../models/jenis_pupuk_model.dart';
import '../providers/pupuk_provider.dart';
import '../providers/auth_provider.dart';

class PenggunaanPupukScreen extends StatefulWidget {
  const PenggunaanPupukScreen({super.key});

  @override
  State<PenggunaanPupukScreen> createState() => _PenggunaanPupukScreenState();
}

class _PenggunaanPupukScreenState extends State<PenggunaanPupukScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String? _selectedPupukId;

  @override
  void initState() {
    super.initState();
    // Initialize Indonesian locale for DateFormat
    initializeDateFormatting('id_ID', null);
    // Load data saat screen pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pupukProvider = Provider.of<PupukProvider>(context, listen: false);
      pupukProvider.loadJenisPupuk();
      pupukProvider.loadPenggunaanPupuk();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditDialog({PenggunaanPupukModel? penggunaan}) {
    final isEdit = penggunaan != null;
    final formKey = GlobalKey<FormState>();
    
    final jumlahController = TextEditingController(
      text: penggunaan?.jumlahDigunakan.toString() ?? ''
    );
    final catatanController = TextEditingController(text: penggunaan?.catatan ?? '');
    
    DateTime selectedDate = penggunaan?.tanggalPakai ?? DateTime.now();
    String? selectedPupukId = penggunaan?.idPupuk;
    String selectedSatuan = penggunaan?.satuan ?? 'kg';
    
    final satuanOptions = ['kg', 'liter', 'gram', 'ml'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit Penggunaan Pupuk' : 'Tambah Penggunaan Pupuk'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tanggal
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tanggal Pakai'),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy').format(selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          selectedDate = date;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Jenis Pupuk
                  Consumer<PupukProvider>(
                    builder: (context, pupukProvider, child) {
                      return DropdownButtonFormField<String>(
                        value: selectedPupukId,
                        decoration: const InputDecoration(
                          labelText: 'Jenis Pupuk',
                          border: OutlineInputBorder(),
                        ),
                        items: pupukProvider.jenisPupukAktif.map((pupuk) {
                          return DropdownMenuItem(
                            value: pupuk.id,
                            child: Text('${pupuk.namaPupuk} (${pupuk.kodePupuk ?? '-'})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedPupukId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Jenis pupuk harus dipilih';
                          }
                          return null;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Jumlah dan Satuan
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: jumlahController,
                          decoration: const InputDecoration(
                            labelText: 'Jumlah',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Jumlah harus diisi';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Jumlah harus berupa angka';
                            }
                            if (double.parse(value) <= 0) {
                              return 'Jumlah harus lebih dari 0';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedSatuan,
                          decoration: const InputDecoration(
                            labelText: 'Satuan',
                            border: OutlineInputBorder(),
                          ),
                          items: satuanOptions.map((satuan) {
                            return DropdownMenuItem(
                              value: satuan,
                              child: Text(satuan),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedSatuan = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Catatan
                  TextFormField(
                    controller: catatanController,
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final pupukProvider = Provider.of<PupukProvider>(context, listen: false);
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  
                  final newPenggunaan = PenggunaanPupukModel(
                    id: penggunaan?.id ?? '',
                    tanggalPakai: selectedDate,
                    idPupuk: selectedPupukId!,
                    jumlahDigunakan: double.parse(jumlahController.text),
                    satuan: selectedSatuan,
                    catatan: catatanController.text.isEmpty ? null : catatanController.text,
                    dicatatOleh: authProvider.user?.idPengguna ?? '',
                    dicatatPada: penggunaan?.dicatatPada ?? DateTime.now(),
                  );

                  bool success;
                  if (isEdit) {
                    success = await pupukProvider.updatePenggunaanPupuk(penggunaan!.id, newPenggunaan);
                  } else {
                    success = await pupukProvider.tambahPenggunaanPupuk(newPenggunaan);
                  }

                  if (success) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit ? 'Penggunaan pupuk berhasil diupdate' : 'Penggunaan pupuk berhasil ditambahkan'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(pupukProvider.error ?? 'Terjadi kesalahan'),
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

  void _showDeleteConfirmation(PenggunaanPupukModel penggunaan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus data penggunaan pupuk ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final pupukProvider = Provider.of<PupukProvider>(context, listen: false);
              final success = await pupukProvider.hapusPenggunaanPupuk(penggunaan.id);
              
              Navigator.of(context).pop();
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Penggunaan pupuk berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(pupukProvider.error ?? 'Gagal menghapus penggunaan pupuk'),
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
    final pupukProvider = Provider.of<PupukProvider>(context, listen: false);
    
    if (_selectedStartDate != null && _selectedEndDate != null) {
      pupukProvider.loadPenggunaanPupukByTanggal(_selectedStartDate!, _selectedEndDate!);
    } else if (_selectedPupukId != null) {
      pupukProvider.loadPenggunaanPupukByJenis(_selectedPupukId!);
    } else {
      pupukProvider.loadPenggunaanPupuk();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Penggunaan Pupuk Harian'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<PupukProvider>().loadPenggunaanPupuk();
            },
          ),
        ],
      ),
      body: Consumer<PupukProvider>(
        builder: (context, pupukProvider, child) {
          return Column(
            children: [
              // Search and Filter Section
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.grey[100],
                child: Column(
                  children: [
                    // Date Range Filter
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Tanggal Mulai'),
                            subtitle: Text(
                              _selectedStartDate != null
                                  ? DateFormat('dd/MM/yyyy').format(_selectedStartDate!)
                                  : 'Pilih tanggal',
                            ),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _selectedStartDate ?? DateTime.now().subtract(const Duration(days: 30)),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() {
                                  _selectedStartDate = date;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Tanggal Akhir'),
                            subtitle: Text(
                              _selectedEndDate != null
                                  ? DateFormat('dd/MM/yyyy').format(_selectedEndDate!)
                                  : 'Pilih tanggal',
                            ),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _selectedEndDate ?? DateTime.now(),
                                firstDate: _selectedStartDate ?? DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() {
                                  _selectedEndDate = date;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Pupuk Filter
                    DropdownButtonFormField<String>(
                      value: _selectedPupukId,
                      decoration: const InputDecoration(
                        labelText: 'Filter berdasarkan Jenis Pupuk',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Semua Jenis Pupuk'),
                        ),
                        ...pupukProvider.jenisPupukAktif.map((pupuk) {
                          return DropdownMenuItem(
                            value: pupuk.id,
                            child: Text('${pupuk.namaPupuk} (${pupuk.kodePupuk ?? '-'})'),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedPupukId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Filter Actions
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _applyFilters,
                            child: const Text('Terapkan Filter'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _selectedStartDate = null;
                                _selectedEndDate = null;
                                _selectedPupukId = null;
                              });
                              pupukProvider.loadPenggunaanPupuk();
                            },
                            child: const Text('Reset Filter'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: pupukProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : pupukProvider.error != null
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
                                  'Error: ${pupukProvider.error}',
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    pupukProvider.clearError();
                                    pupukProvider.loadPenggunaanPupuk();
                                  },
                                  child: const Text('Coba Lagi'),
                                ),
                              ],
                            ),
                          )
                        : pupukProvider.penggunaanPupukList.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.eco_outlined,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Belum ada data penggunaan pupuk',
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
                                itemCount: pupukProvider.penggunaanPupukList.length,
                                itemBuilder: (context, index) {
                                  final penggunaan = pupukProvider.penggunaanPupukList[index];
                                  final pupuk = pupukProvider.jenisPupukList
                                      .where((p) => p.id == penggunaan.idPupuk)
                                      .firstOrNull;
                                  
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    elevation: 2,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.green,
                                        child: const Icon(
                                          Icons.eco,
                                          color: Colors.white,
                                        ),
                                      ),
                                      title: Text(
                                        pupuk?.namaPupuk ?? 'Pupuk tidak ditemukan',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Tanggal: ${DateFormat('dd/MM/yyyy').format(penggunaan.tanggalPakai)}',
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                          Text(
                                            'Jumlah: ${penggunaan.jumlahDigunakan} ${penggunaan.satuan ?? ''}',
                                            style: TextStyle(
                                              color: Colors.green[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (penggunaan.catatan != null)
                                            Text(
                                              'Catatan: ${penggunaan.catatan}',
                                              style: const TextStyle(fontStyle: FontStyle.italic),
                                            ),
                                          Text(
                                            'Dicatat: ${DateFormat('dd/MM/yyyy HH:mm').format(penggunaan.dicatatPada)}',
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
                                              _showAddEditDialog(penggunaan: penggunaan);
                                              break;
                                            case 'delete':
                                              _showDeleteConfirmation(penggunaan);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}