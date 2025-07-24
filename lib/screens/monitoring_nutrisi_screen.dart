import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/monitoring_nutrisi_model.dart';
import '../providers/tandon_provider.dart';

class MonitoringNutrisiScreen extends StatefulWidget {
  const MonitoringNutrisiScreen({super.key});

  @override
  State<MonitoringNutrisiScreen> createState() => _MonitoringNutrisiScreenState();
}

class _MonitoringNutrisiScreenState extends State<MonitoringNutrisiScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedTandonId;

  @override
  void initState() {
    super.initState();
    // Initialize Indonesian locale for DateFormat
    initializeDateFormatting('id_ID', null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TandonProvider>();
      provider.loadTandonAir();
      provider.loadMonitoringNutrisi();
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
        title: const Text('Monitoring Nutrisi'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<TandonProvider>().loadMonitoringNutrisi();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade600,
              Colors.green.shade50,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: Column(
          children: [
            // Search Section
            Container(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari monitoring nutrisi...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            context.read<TandonProvider>().searchMonitoringNutrisi('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  context.read<TandonProvider>().searchMonitoringNutrisi(value);
                },
              ),
            ),
            
            // Filter Chips
            if (_selectedDate != null || _selectedTandonId != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (_selectedDate != null)
                      FilterChip(
                        label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate!)),
                        selected: true,
                        onSelected: (bool selected) {
                          if (!selected) {
                            setState(() {
                              _selectedDate = null;
                            });
                            _applyFilters();
                          }
                        },
                        onDeleted: () {
                          setState(() {
                            _selectedDate = null;
                          });
                          _applyFilters();
                        },
                      ),
                    if (_selectedTandonId != null)
                      Consumer<TandonProvider>(
                        builder: (context, provider, child) {
                          final tandonName = provider.getTandonName(_selectedTandonId!);
                          return FilterChip(
                            label: Text(tandonName),
                            selected: true,
                            onSelected: (bool selected) {
                              if (!selected) {
                                setState(() {
                                  _selectedTandonId = null;
                                });
                                _applyFilters();
                              }
                            },
                            onDeleted: () {
                              setState(() {
                                _selectedTandonId = null;
                              });
                              _applyFilters();
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            
            // Content Section
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Consumer<TandonProvider>(
                  builder: (context, tandonProvider, child) {
                    if (tandonProvider.isLoadingMonitoringNutrisi) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (tandonProvider.monitoringNutrisiError != null) {
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
                              'Terjadi Kesalahan',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tandonProvider.monitoringNutrisiError!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                tandonProvider.loadMonitoringNutrisi();
                              },
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      );
                    }

                    final monitoringList = tandonProvider.monitoringNutrisiList;

                    if (monitoringList.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.science_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum Ada Data Monitoring',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tambahkan data monitoring nutrisi pertama Anda',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showAddEditDialog(),
                              icon: const Icon(Icons.add),
                              label: const Text('Tambah Monitoring'),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: monitoringList.length,
                      itemBuilder: (context, index) {
                        final monitoring = monitoringList[index];
                        return _buildMonitoringCard(monitoring);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.green.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMonitoringCard(MonitoringNutrisiModel monitoring) {
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
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.green[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd/MM/yyyy').format(monitoring.tanggalMonitoring),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Consumer<TandonProvider>(
                            builder: (context, provider, child) {
                              final tandonName = provider.getTandonName(monitoring.idTandon);
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  tandonName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showAddEditDialog(monitoring: monitoring);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(monitoring);
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
            
            // Monitoring Data Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                if (monitoring.nilaiPpm != null)
                  _buildDataItem('PPM', '${monitoring.nilaiPpm!.toStringAsFixed(1)}', Icons.science),
                if (monitoring.tingkatPh != null)
                  _buildDataItem('pH', monitoring.tingkatPh!.toStringAsFixed(1), Icons.water_drop),
                if (monitoring.suhuAir != null)
                  _buildDataItem('Suhu', '${monitoring.suhuAir!.toStringAsFixed(1)}°C', Icons.thermostat),
                if (monitoring.airDitambah != null)
                  _buildDataItem('Air', '${monitoring.airDitambah!.toStringAsFixed(0)}L', Icons.water),
                if (monitoring.nutrisiDitambah != null)
                  _buildDataItem('Nutrisi', '${monitoring.nutrisiDitambah!.toStringAsFixed(1)}ml', Icons.local_drink),
              ],
            ),
            
            if (monitoring.catatan != null && monitoring.catatan!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.note,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Catatan:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      monitoring.catatan!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
            
            if (monitoring.dicatatOleh != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Dicatat oleh: ${monitoring.dicatatOleh}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  if (monitoring.dicatatPada != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(monitoring.dicatatPada!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.green[600],
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Tanggal'),
                subtitle: Text(
                  _selectedDate != null
                      ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                      : 'Semua tanggal',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
              ),
              Consumer<TandonProvider>(
                builder: (context, provider, child) {
                  return DropdownButtonFormField<String>(
                    value: _selectedTandonId,
                    decoration: const InputDecoration(
                      labelText: 'Tandon Air',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Semua tandon'),
                      ),
                      ...provider.tandonAirList.map(
                        (tandon) => DropdownMenuItem<String>(
                          value: tandon.id,
                          child: Text('${tandon.kodeTandon} - ${tandon.namaTandon ?? ''}'),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedTandonId = value;
                      });
                    },
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedDate = null;
                  _selectedTandonId = null;
                });
              },
              child: const Text('Reset'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _applyFilters();
              },
              child: const Text('Terapkan'),
            ),
          ],
        ),
      ),
    );
  }

  void _applyFilters() {
    context.read<TandonProvider>().filterMonitoringNutrisi(
          tanggal: _selectedDate,
          idTandon: _selectedTandonId,
        );
  }

  void _showAddEditDialog({MonitoringNutrisiModel? monitoring}) {
    final isEdit = monitoring != null;
    final formKey = GlobalKey<FormState>();
    
    DateTime selectedDate = monitoring?.tanggalMonitoring ?? DateTime.now();
    String? selectedTandonId = monitoring?.idTandon;
    final nilaiPpmController = TextEditingController(
        text: monitoring?.nilaiPpm?.toString() ?? '');
    final airDitambahController = TextEditingController(
        text: monitoring?.airDitambah?.toString() ?? '');
    final nutrisiDitambahController = TextEditingController(
        text: monitoring?.nutrisiDitambah?.toString() ?? '');
    final tingkatPhController = TextEditingController(
        text: monitoring?.tingkatPh?.toString() ?? '');
    final suhuAirController = TextEditingController(
        text: monitoring?.suhuAir?.toString() ?? '');
    final catatanController = TextEditingController(
        text: monitoring?.catatan ?? '');
    final dicatatOlehController = TextEditingController(
        text: monitoring?.dicatatOleh ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit Monitoring Nutrisi' : 'Tambah Monitoring Nutrisi'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tanggal
                  ListTile(
                    title: const Text('Tanggal Monitoring *'),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
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
                  
                  // Tandon Air
                  Consumer<TandonProvider>(
                    builder: (context, provider, child) {
                      return DropdownButtonFormField<String>(
                        value: selectedTandonId,
                        decoration: const InputDecoration(
                          labelText: 'Tandon Air *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Tandon air harus dipilih';
                          }
                          return null;
                        },
                        items: provider.tandonAirList.map(
                          (tandon) => DropdownMenuItem<String>(
                            value: tandon.id,
                            child: Text('${tandon.kodeTandon} - ${tandon.namaTandon ?? ''}'),
                          ),
                        ).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedTandonId = value;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Nilai PPM
                  TextFormField(
                    controller: nilaiPpmController,
                    decoration: const InputDecoration(
                      labelText: 'Nilai PPM',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  
                  // Air Ditambah
                  TextFormField(
                    controller: airDitambahController,
                    decoration: const InputDecoration(
                      labelText: 'Air Ditambah (Liter)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  
                  // Nutrisi Ditambah
                  TextFormField(
                    controller: nutrisiDitambahController,
                    decoration: const InputDecoration(
                      labelText: 'Nutrisi Ditambah (ml)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  
                  // Tingkat pH
                  TextFormField(
                    controller: tingkatPhController,
                    decoration: const InputDecoration(
                      labelText: 'Tingkat pH',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  
                  // Suhu Air
                  TextFormField(
                    controller: suhuAirController,
                    decoration: const InputDecoration(
                      labelText: 'Suhu Air (°C)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  
                  // Catatan
                  TextFormField(
                    controller: catatanController,
                    decoration: const InputDecoration(
                      labelText: 'Catatan',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  
                  // Dicatat Oleh
                  TextFormField(
                    controller: dicatatOlehController,
                    decoration: const InputDecoration(
                      labelText: 'Dicatat Oleh',
                      border: OutlineInputBorder(),
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
                  final newMonitoring = MonitoringNutrisiModel(
                    id: monitoring?.id ?? '',
                    tanggalMonitoring: selectedDate,
                    idTandon: selectedTandonId!,
                    nilaiPpm: nilaiPpmController.text.trim().isEmpty
                        ? null
                        : double.tryParse(nilaiPpmController.text.trim()),
                    airDitambah: airDitambahController.text.trim().isEmpty
                        ? null
                        : double.tryParse(airDitambahController.text.trim()),
                    nutrisiDitambah: nutrisiDitambahController.text.trim().isEmpty
                        ? null
                        : double.tryParse(nutrisiDitambahController.text.trim()),
                    tingkatPh: tingkatPhController.text.trim().isEmpty
                        ? null
                        : double.tryParse(tingkatPhController.text.trim()),
                    suhuAir: suhuAirController.text.trim().isEmpty
                        ? null
                        : double.tryParse(suhuAirController.text.trim()),
                    catatan: catatanController.text.trim().isEmpty
                        ? null
                        : catatanController.text.trim(),
                    dicatatOleh: dicatatOlehController.text.trim().isEmpty
                        ? null
                        : dicatatOlehController.text.trim(),
                    dicatatPada: DateTime.now(),
                  );

                  bool success;
                  if (isEdit) {
                    success = await context
                        .read<TandonProvider>()
                        .updateMonitoringNutrisi(newMonitoring);
                  } else {
                    success = await context
                        .read<TandonProvider>()
                        .tambahMonitoringNutrisi(newMonitoring);
                  }

                  if (success && context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEdit
                              ? 'Monitoring nutrisi berhasil diupdate'
                              : 'Monitoring nutrisi berhasil ditambahkan',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.read<TandonProvider>().monitoringNutrisiError ??
                              'Terjadi kesalahan',
                        ),
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

  void _showDeleteConfirmation(MonitoringNutrisiModel monitoring) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Apakah Anda yakin ingin menghapus data monitoring tanggal ${DateFormat('dd/MM/yyyy').format(monitoring.tanggalMonitoring)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await context
                  .read<TandonProvider>()
                  .hapusMonitoringNutrisi(monitoring.id);

              if (success && context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Monitoring nutrisi berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.read<TandonProvider>().monitoringNutrisiError ??
                          'Gagal menghapus monitoring nutrisi',
                    ),
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