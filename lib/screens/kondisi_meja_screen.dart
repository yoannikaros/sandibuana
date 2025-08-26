import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/kondisi_meja_model.dart';
import '../providers/kondisi_meja_provider.dart';
import '../providers/penanaman_sayur_provider.dart';

class KondisiMejaScreen extends StatefulWidget {
  const KondisiMejaScreen({super.key});

  @override
  State<KondisiMejaScreen> createState() => _KondisiMejaScreenState();
}

class _KondisiMejaScreenState extends State<KondisiMejaScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedKondisi;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KondisiMejaProvider>().loadKondisiMeja();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showTambahMejaDialog() {
    showDialog(
      context: context,
      builder: (context) => const _TambahMejaDialog(),
    );
  }

  void _showEditMejaDialog(KondisiMejaModel meja) {
    showDialog(
      context: context,
      builder: (context) => _EditMejaDialog(meja: meja),
    );
  }

  void _showUpdateStatusDialog(KondisiMejaModel meja) {
    showDialog(
      context: context,
      builder: (context) => _UpdateStatusDialog(meja: meja),
    );
  }

  void _applyFilters() {
    final provider = context.read<KondisiMejaProvider>();
    final keyword = _searchController.text;
    
    if (keyword.isNotEmpty) {
      provider.searchKondisiMeja(keyword);
    } else {
      provider.loadKondisiMeja();
    }
  }

  Color _getKondisiColor(String kondisi) {
    switch (kondisi) {
      case 'kosong':
        return Colors.grey;
      case 'tanam':
        return Colors.green;
      case 'panen':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _getKondisiIcon(String kondisi) {
    switch (kondisi) {
      case 'kosong':
        return Icons.crop_free;
      case 'tanam':
        return Icons.eco;
      case 'panen':
        return Icons.agriculture;
      default:
        return Icons.table_restaurant;
    }
  }

  String _getKondisiText(String kondisi) {
    switch (kondisi) {
      case 'kosong':
        return 'Kosong';
      case 'tanam':
        return 'Sedang Tanam';
      case 'panen':
        return 'Sedang Panen';
      default:
        return kondisi;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kondisi Meja'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<KondisiMejaProvider>().refresh();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'statistik':
                  _showStatistikDialog();
                  break;
                case 'clear_filters':
                  setState(() {
                    _searchController.clear();
                    _selectedKondisi = null;
                  });
                  context.read<KondisiMejaProvider>().loadKondisiMeja();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'statistik',
                child: Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Statistik'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_filters',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Clear Filters'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilterBar(),
          _buildStatistikCards(),
          Expanded(
            child: Consumer<KondisiMejaProvider>(
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
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Terjadi kesalahan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            provider.clearError();
                            provider.refresh();
                          },
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                final filteredList = _selectedKondisi != null
                    ? provider.getKondisiMejaByKondisi(_selectedKondisi!)
                    : provider.kondisiMejaList;

                if (filteredList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.table_restaurant,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada data meja',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tambahkan meja pertama Anda',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _showTambahMejaDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah Meja'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final meja = filteredList[index];
                    return _buildMejaCard(meja);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showTambahMejaDialog,
        backgroundColor: Colors.green.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari nama meja atau jenis sayur...',
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
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              _applyFilters();
            },
          ),
          const SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Semua'),
                  selected: _selectedKondisi == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedKondisi = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Kosong'),
                  selected: _selectedKondisi == 'kosong',
                  onSelected: (selected) {
                    setState(() {
                      _selectedKondisi = selected ? 'kosong' : null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Sedang Tanam'),
                  selected: _selectedKondisi == 'tanam',
                  onSelected: (selected) {
                    setState(() {
                      _selectedKondisi = selected ? 'tanam' : null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Sedang Panen'),
                  selected: _selectedKondisi == 'panen',
                  onSelected: (selected) {
                    setState(() {
                      _selectedKondisi = selected ? 'panen' : null;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistikCards() {
    return Consumer<KondisiMejaProvider>(
      builder: (context, provider, child) {
        final statistik = provider.getStatistik();
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Meja',
                  statistik['total'].toString(),
                  Icons.table_restaurant,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Kosong',
                  statistik['kosong'].toString(),
                  Icons.crop_free,
                  Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Tanam',
                  statistik['tanam'].toString(),
                  Icons.eco,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Siap Panen',
                  statistik['siap_panen'].toString(),
                  Icons.agriculture,
                  Colors.orange,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMejaCard(KondisiMejaModel meja) {
    final kondisiColor = _getKondisiColor(meja.kondisi);
    final kondisiIcon = _getKondisiIcon(meja.kondisi);
    final kondisiText = _getKondisiText(meja.kondisi);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showEditMejaDialog(meja),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kondisiColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      kondisiIcon,
                      color: kondisiColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meja.namaMeja,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: kondisiColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: kondisiColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            kondisiText,
                            style: TextStyle(
                              color: kondisiColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditMejaDialog(meja);
                          break;
                        case 'update_status':
                          _showUpdateStatusDialog(meja);
                          break;
                        case 'delete':
                          _showDeleteConfirmation(meja);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'update_status',
                        child: Row(
                          children: [
                            Icon(Icons.update, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Update Status'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (meja.kondisi == 'tanam' && meja.tanggalTanam != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (meja.jenisSayur != null)
                        Row(
                          children: [
                            const Icon(Icons.eco, size: 16, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              'Jenis: ${meja.jenisSayur}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            'Tanam: ${DateFormat('dd/MM/yyyy').format(meja.tanggalTanam!)}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 16, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            'Usia: ${meja.usiaTanamanHari ?? 0} hari',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: meja.siapPanen ? Colors.orange.shade700 : Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      if (meja.targetHariPanen != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              meja.siapPanen ? Icons.agriculture : Icons.timer,
                              size: 16,
                              color: meja.siapPanen ? Colors.orange : Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              meja.siapPanen
                                  ? 'SIAP PANEN!'
                                  : 'Sisa: ${meja.sisaHariPanen} hari',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: meja.siapPanen ? Colors.orange.shade700 : Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (meja.catatan != null && meja.catatan!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.note, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          meja.catatan!,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(KondisiMejaModel meja) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus meja "${meja.namaMeja}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<KondisiMejaProvider>();
              final success = await provider.hapusKondisiMeja(meja.id);
              if (success && mounted) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Meja berhasil dihapus'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showStatistikDialog() {
    final provider = context.read<KondisiMejaProvider>();
    final statistik = provider.getStatistik();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistik Kondisi Meja'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Total Meja', statistik['total'].toString(), Colors.blue),
            _buildStatRow('Meja Kosong', statistik['kosong'].toString(), Colors.grey),
            _buildStatRow('Sedang Tanam', statistik['tanam'].toString(), Colors.green),
            _buildStatRow('Sedang Panen', statistik['panen'].toString(), Colors.orange),
            _buildStatRow('Siap Panen', statistik['siap_panen'].toString(), Colors.red),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Dialog untuk tambah meja
class _TambahMejaDialog extends StatefulWidget {
  const _TambahMejaDialog();

  @override
  State<_TambahMejaDialog> createState() => _TambahMejaDialogState();
}

class _TambahMejaDialogState extends State<_TambahMejaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _namaMejaController = TextEditingController();
  final _jenisSayurController = TextEditingController();
  final _targetHariPanenController = TextEditingController();
  final _catatanController = TextEditingController();
  
  String _kondisi = 'kosong';
  DateTime? _tanggalTanam;
  String? _selectedJenisSayur;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load available jenis sayur when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAvailableJenisSayur();
    });
  }

  Future<void> _loadAvailableJenisSayur() async {
    try {
      await context.read<PenanamanSayurProvider>().loadAvailableJenisSayur();
    } catch (e) {
      print('Error loading available jenis sayur: $e');
    }
  }

  @override
  void dispose() {
    _namaMejaController.dispose();
    _jenisSayurController.dispose();
    _targetHariPanenController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Meja Baru'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _namaMejaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Meja *',
                  hintText: 'Contoh: Meja 1, Meja A, dll',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama meja harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _kondisi,
                decoration: const InputDecoration(
                  labelText: 'Kondisi Meja *',
                ),
                items: const [
                  DropdownMenuItem(value: 'kosong', child: Text('Kosong')),
                  DropdownMenuItem(value: 'tanam', child: Text('Sedang Tanam')),
                  DropdownMenuItem(value: 'panen', child: Text('Sedang Panen')),
                ],
                onChanged: (value) {
                  setState(() {
                    _kondisi = value!;
                    if (_kondisi == 'kosong') {
                      _tanggalTanam = null;
                      _jenisSayurController.clear();
                      _targetHariPanenController.clear();
                    }
                  });
                },
              ),
              if (_kondisi == 'tanam') ...[
                const SizedBox(height: 16),
                Consumer<PenanamanSayurProvider>(
                  builder: (context, provider, child) {
                    final availableJenisSayur = provider.availableJenisSayur;
                    
                    return Column(
                      children: [
                        if (availableJenisSayur.isNotEmpty)
                          DropdownButtonFormField<String>(
                            value: _selectedJenisSayur,
                            decoration: const InputDecoration(
                              labelText: 'Jenis Sayur (dari Penanaman)',
                              hintText: 'Pilih jenis sayur yang sudah ditanam',
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Pilih jenis sayur...'),
                              ),
                              ...availableJenisSayur.map((jenis) {
                                return DropdownMenuItem<String>(
                                  value: jenis,
                                  child: Text(jenis),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedJenisSayur = value;
                                if (value != null) {
                                  _jenisSayurController.text = value;
                                } else {
                                  _jenisSayurController.clear();
                                }
                              });
                            },
                          ),
                        if (availableJenisSayur.isEmpty)
                          TextFormField(
                            controller: _jenisSayurController,
                            decoration: const InputDecoration(
                              labelText: 'Jenis Sayur',
                              hintText: 'Belum ada data penanaman, input manual',
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          availableJenisSayur.isNotEmpty 
                              ? 'Atau input jenis sayur baru:'
                              : 'Tambahkan data penanaman sayur terlebih dahulu untuk pilihan otomatis',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _jenisSayurController,
                          decoration: const InputDecoration(
                            labelText: 'Jenis Sayur Manual (Opsional)',
                            hintText: 'Contoh: Kangkung, Bayam, dll',
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              setState(() {
                                _selectedJenisSayur = null;
                              });
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _tanggalTanam ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _tanggalTanam = date;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Tanam',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _tanggalTanam != null
                          ? DateFormat('dd/MM/yyyy').format(_tanggalTanam!)
                          : 'Pilih tanggal tanam',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _targetHariPanenController,
                  decoration: const InputDecoration(
                    labelText: 'Target Hari Panen',
                    hintText: 'Contoh: 30 (hari)',
                    suffixText: 'hari',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final number = int.tryParse(value);
                      if (number == null || number <= 0) {
                        return 'Masukkan angka yang valid';
                      }
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _catatanController,
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                  hintText: 'Catatan tambahan (opsional)',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _simpanMeja,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }

  Future<void> _simpanMeja() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await context.read<KondisiMejaProvider>().tambahKondisiMeja(
        namaMeja: _namaMejaController.text,
        kondisi: _kondisi,
        tanggalTanam: _tanggalTanam,
        jenisSayur: _jenisSayurController.text.isNotEmpty ? _jenisSayurController.text : null,
        targetHariPanen: _targetHariPanenController.text.isNotEmpty
            ? int.tryParse(_targetHariPanenController.text)
            : null,
        catatan: _catatanController.text.isNotEmpty ? _catatanController.text : null,
      );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meja berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan meja: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

// Dialog untuk edit meja
class _EditMejaDialog extends StatefulWidget {
  final KondisiMejaModel meja;

  const _EditMejaDialog({required this.meja});

  @override
  State<_EditMejaDialog> createState() => _EditMejaDialogState();
}

class _EditMejaDialogState extends State<_EditMejaDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaMejaController;
  late final TextEditingController _jenisSayurController;
  late final TextEditingController _targetHariPanenController;
  late final TextEditingController _catatanController;
  
  late String _kondisi;
  DateTime? _tanggalTanam;
  String? _selectedJenisSayur;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _namaMejaController = TextEditingController(text: widget.meja.namaMeja);
    _jenisSayurController = TextEditingController(text: widget.meja.jenisSayur ?? '');
    _targetHariPanenController = TextEditingController(
      text: widget.meja.targetHariPanen?.toString() ?? '',
    );
    _catatanController = TextEditingController(text: widget.meja.catatan ?? '');
    _kondisi = widget.meja.kondisi;
    _tanggalTanam = widget.meja.tanggalTanam;
    
    // Load available jenis sayur when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PenanamanSayurProvider>().loadAvailableJenisSayur().then((_) {
        // Set selected jenis sayur if it exists in available list
        final availableJenisSayur = context.read<PenanamanSayurProvider>().availableJenisSayur;
        if (widget.meja.jenisSayur != null && availableJenisSayur.contains(widget.meja.jenisSayur)) {
          setState(() {
            _selectedJenisSayur = widget.meja.jenisSayur;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _namaMejaController.dispose();
    _jenisSayurController.dispose();
    _targetHariPanenController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.meja.namaMeja}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _namaMejaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Meja *',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama meja harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _kondisi,
                decoration: const InputDecoration(
                  labelText: 'Kondisi Meja *',
                ),
                items: const [
                  DropdownMenuItem(value: 'kosong', child: Text('Kosong')),
                  DropdownMenuItem(value: 'tanam', child: Text('Sedang Tanam')),
                  DropdownMenuItem(value: 'panen', child: Text('Sedang Panen')),
                ],
                onChanged: (value) {
                  setState(() {
                    _kondisi = value!;
                    if (_kondisi == 'kosong') {
                      _tanggalTanam = null;
                      _jenisSayurController.clear();
                      _targetHariPanenController.clear();
                    }
                  });
                },
              ),
              if (_kondisi == 'tanam') ...[
                const SizedBox(height: 16),
                Consumer<PenanamanSayurProvider>(
                  builder: (context, provider, child) {
                    final availableJenisSayur = provider.availableJenisSayur;
                    
                    return Column(
                      children: [
                        if (availableJenisSayur.isNotEmpty)
                          DropdownButtonFormField<String>(
                            value: _selectedJenisSayur,
                            decoration: const InputDecoration(
                              labelText: 'Jenis Sayur (dari Penanaman)',
                              hintText: 'Pilih jenis sayur yang sudah ditanam',
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Pilih jenis sayur...'),
                              ),
                              ...availableJenisSayur.map((jenis) {
                                return DropdownMenuItem<String>(
                                  value: jenis,
                                  child: Text(jenis),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedJenisSayur = value;
                                if (value != null) {
                                  _jenisSayurController.text = value;
                                } else {
                                  _jenisSayurController.clear();
                                }
                              });
                            },
                          ),
                        if (availableJenisSayur.isEmpty)
                          TextFormField(
                            controller: _jenisSayurController,
                            decoration: const InputDecoration(
                              labelText: 'Jenis Sayur',
                              hintText: 'Belum ada data penanaman, input manual',
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          availableJenisSayur.isNotEmpty 
                              ? 'Atau input jenis sayur baru:'
                              : 'Tambahkan data penanaman sayur terlebih dahulu untuk pilihan otomatis',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _jenisSayurController,
                          decoration: const InputDecoration(
                            labelText: 'Jenis Sayur Manual (Opsional)',
                            hintText: 'Contoh: Kangkung, Bayam, dll',
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              setState(() {
                                _selectedJenisSayur = null;
                              });
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _tanggalTanam ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _tanggalTanam = date;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Tanam',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _tanggalTanam != null
                          ? DateFormat('dd/MM/yyyy').format(_tanggalTanam!)
                          : 'Pilih tanggal tanam',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _targetHariPanenController,
                  decoration: const InputDecoration(
                    labelText: 'Target Hari Panen',
                    suffixText: 'hari',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final number = int.tryParse(value);
                      if (number == null || number <= 0) {
                        return 'Masukkan angka yang valid';
                      }
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _catatanController,
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateMeja,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _updateMeja() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await context.read<KondisiMejaProvider>().updateKondisiMeja(
        id: widget.meja.id,
        namaMeja: _namaMejaController.text,
        kondisi: _kondisi,
        tanggalTanam: _tanggalTanam,
        jenisSayur: _jenisSayurController.text.isNotEmpty ? _jenisSayurController.text : null,
        targetHariPanen: _targetHariPanenController.text.isNotEmpty
            ? int.tryParse(_targetHariPanenController.text)
            : null,
        catatan: _catatanController.text.isNotEmpty ? _catatanController.text : null,
      );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meja berhasil diupdate'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengupdate meja: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

// Dialog untuk update status saja
class _UpdateStatusDialog extends StatefulWidget {
  final KondisiMejaModel meja;

  const _UpdateStatusDialog({required this.meja});

  @override
  State<_UpdateStatusDialog> createState() => _UpdateStatusDialogState();
}

class _UpdateStatusDialogState extends State<_UpdateStatusDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _jenisSayurController;
  late final TextEditingController _targetHariPanenController;
  late final TextEditingController _catatanController;
  
  late String _kondisi;
  DateTime? _tanggalTanam;
  String? _selectedJenisSayur;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _jenisSayurController = TextEditingController(text: widget.meja.jenisSayur ?? '');
    _targetHariPanenController = TextEditingController(
      text: widget.meja.targetHariPanen?.toString() ?? '',
    );
    _catatanController = TextEditingController(text: widget.meja.catatan ?? '');
    _kondisi = widget.meja.kondisi;
    _tanggalTanam = widget.meja.tanggalTanam;
    
    // Load available jenis sayur when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PenanamanSayurProvider>().loadAvailableJenisSayur().then((_) {
        // Set selected jenis sayur if it exists in available list
        final availableJenisSayur = context.read<PenanamanSayurProvider>().availableJenisSayur;
        if (widget.meja.jenisSayur != null && availableJenisSayur.contains(widget.meja.jenisSayur)) {
          setState(() {
            _selectedJenisSayur = widget.meja.jenisSayur;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _jenisSayurController.dispose();
    _targetHariPanenController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update Status ${widget.meja.namaMeja}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _kondisi,
                decoration: const InputDecoration(
                  labelText: 'Kondisi Meja *',
                ),
                items: const [
                  DropdownMenuItem(value: 'kosong', child: Text('Kosong')),
                  DropdownMenuItem(value: 'tanam', child: Text('Sedang Tanam')),
                  DropdownMenuItem(value: 'panen', child: Text('Sedang Panen')),
                ],
                onChanged: (value) {
                  setState(() {
                    _kondisi = value!;
                    if (_kondisi == 'kosong') {
                      _tanggalTanam = null;
                      _jenisSayurController.clear();
                      _targetHariPanenController.clear();
                    } else if (_kondisi == 'tanam' && _tanggalTanam == null) {
                      _tanggalTanam = DateTime.now();
                    }
                  });
                },
              ),
              if (_kondisi == 'tanam') ...[
                const SizedBox(height: 16),
                Consumer<PenanamanSayurProvider>(
                  builder: (context, provider, child) {
                    final availableJenisSayur = provider.availableJenisSayur;
                    
                    return Column(
                      children: [
                        if (availableJenisSayur.isNotEmpty)
                          DropdownButtonFormField<String>(
                            value: _selectedJenisSayur,
                            decoration: const InputDecoration(
                              labelText: 'Jenis Sayur (dari Penanaman)',
                              hintText: 'Pilih jenis sayur yang sudah ditanam',
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Pilih jenis sayur...'),
                              ),
                              ...availableJenisSayur.map((jenis) {
                                return DropdownMenuItem<String>(
                                  value: jenis,
                                  child: Text(jenis),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedJenisSayur = value;
                                if (value != null) {
                                  _jenisSayurController.text = value;
                                } else {
                                  _jenisSayurController.clear();
                                }
                              });
                            },
                          ),
                        if (availableJenisSayur.isEmpty)
                          TextFormField(
                            controller: _jenisSayurController,
                            decoration: const InputDecoration(
                              labelText: 'Jenis Sayur',
                              hintText: 'Belum ada data penanaman, input manual',
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          availableJenisSayur.isNotEmpty 
                              ? 'Atau input jenis sayur baru:'
                              : 'Tambahkan data penanaman sayur terlebih dahulu untuk pilihan otomatis',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _jenisSayurController,
                          decoration: const InputDecoration(
                            labelText: 'Jenis Sayur Manual (Opsional)',
                            hintText: 'Contoh: Kangkung, Bayam, dll',
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              setState(() {
                                _selectedJenisSayur = null;
                              });
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _tanggalTanam ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _tanggalTanam = date;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Tanam',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _tanggalTanam != null
                          ? DateFormat('dd/MM/yyyy').format(_tanggalTanam!)
                          : 'Pilih tanggal tanam',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _targetHariPanenController,
                  decoration: const InputDecoration(
                    labelText: 'Target Hari Panen',
                    suffixText: 'hari',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final number = int.tryParse(value);
                      if (number == null || number <= 0) {
                        return 'Masukkan angka yang valid';
                      }
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _catatanController,
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateStatus,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _updateStatus() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await context.read<KondisiMejaProvider>().updateStatusKondisiMeja(
        id: widget.meja.id,
        kondisi: _kondisi,
        tanggalTanam: _tanggalTanam,
        jenisSayur: _jenisSayurController.text.isNotEmpty ? _jenisSayurController.text : null,
        targetHariPanen: _targetHariPanenController.text.isNotEmpty
            ? int.tryParse(_targetHariPanenController.text)
            : null,
        catatan: _catatanController.text.isNotEmpty ? _catatanController.text : null,
      );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status meja berhasil diupdate'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengupdate status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}