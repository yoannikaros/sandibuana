import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/monitoring_nutrisi_model.dart';
import '../models/tandon_air_model.dart';
import '../providers/monitoring_nutrisi_provider.dart';
import '../providers/auth_provider.dart';

class MonitoringNutrisiHarianScreen extends StatefulWidget {
  const MonitoringNutrisiHarianScreen({super.key});

  @override
  State<MonitoringNutrisiHarianScreen> createState() => _MonitoringNutrisiHarianScreenState();
}

class _MonitoringNutrisiHarianScreenState extends State<MonitoringNutrisiHarianScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String? _selectedTandonId;

  @override
  void initState() {
    super.initState();
    // Initialize Indonesian locale for DateFormat
    initializeDateFormatting('id_ID', null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MonitoringNutrisiProvider>().initialize();
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
        title: const Text('Monitoring Nutrisi Harian'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<MonitoringNutrisiProvider>().refresh();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          _buildSummaryCard(),
          Expanded(
            child: _buildMonitoringList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.blue.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari berdasarkan catatan...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context.read<MonitoringNutrisiProvider>().searchMonitoring('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              context.read<MonitoringNutrisiProvider>().searchMonitoring(value);
            },
          ),
          const SizedBox(height: 12),
          // Filter row
          Row(
            children: [
              // Tandon filter
              Expanded(
                child: Consumer<MonitoringNutrisiProvider>(
                  builder: (context, provider, child) {
                    return DropdownButtonFormField<String>(
                      value: _selectedTandonId,
                      decoration: InputDecoration(
                        labelText: 'Tandon Air',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Semua Tandon'),
                        ),
                        ...provider.tandonList.map((tandon) {
                          return DropdownMenuItem(
                            value: tandon.id,
                            child: Text(tandon.namaTandon ?? 'Tandon ${tandon.kodeTandon}'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedTandonId = value;
                        });
                        provider.filterByTandon(value);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Date filter button
              ElevatedButton.icon(
                onPressed: _showDateRangeFilter,
                icon: const Icon(Icons.date_range),
                label: Text(
                  _selectedStartDate != null && _selectedEndDate != null
                      ? '${DateFormat('dd/MM').format(_selectedStartDate!)} - ${DateFormat('dd/MM').format(_selectedEndDate!)}'
                      : 'Filter Tanggal',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Consumer<MonitoringNutrisiProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    'Rata-rata PPM',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '${provider.averagePpm.toStringAsFixed(1)} ppm',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.blue.shade200,
              ),
              Column(
                children: [
                  Text(
                    'Rata-rata pH',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    provider.averagePh.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.blue.shade200,
              ),
              Column(
                children: [
                  Text(
                    'Total Monitoring',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '${provider.totalCount}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonitoringList() {
    return Consumer<MonitoringNutrisiProvider>(
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

        if (provider.monitoringList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.water_drop_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada data monitoring',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap tombol + untuk menambah monitoring baru',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.monitoringList.length,
          itemBuilder: (context, index) {
            final monitoring = provider.monitoringList[index];
            return _buildMonitoringCard(monitoring, provider);
          },
        );
      },
    );
  }

  Widget _buildMonitoringCard(MonitoringNutrisiModel monitoring, MonitoringNutrisiProvider provider) {
    final tandonName = provider.getTandonName(monitoring.idTandon);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAddEditDialog(monitoring: monitoring),
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
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(monitoring.tanggalMonitoring),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                tandonName,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Monitoring values grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildValueCard(
                                'PPM',
                                '${monitoring.nilaiPpm ?? 0}',
                                Icons.opacity,
                                _getPpmColor(monitoring.nilaiPpm ?? 0),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildValueCard(
                                'pH',
                                (monitoring.tingkatPh ?? 0).toStringAsFixed(1),
                                Icons.science,
                                _getPhColor(monitoring.tingkatPh ?? 0),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildValueCard(
                                'Suhu',
                                '${(monitoring.suhuAir ?? 0).toStringAsFixed(1)}°C',
                                Icons.thermostat,
                                _getTempColor(monitoring.suhuAir ?? 0),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showAddEditDialog(monitoring: monitoring);
                          break;
                        case 'delete':
                          _showDeleteConfirmation(monitoring);
                          break;
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
              if ((monitoring.airDitambah ?? 0) > 0 || (monitoring.nutrisiDitambah ?? 0) > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if ((monitoring.airDitambah ?? 0) > 0) ...[
                      Icon(
                        Icons.water,
                        size: 16,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Air: ${monitoring.airDitambah}L',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if ((monitoring.nutrisiDitambah ?? 0) > 0) ...[
                      Icon(
                        Icons.eco,
                        size: 16,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Nutrisi: ${monitoring.nutrisiDitambah}ml',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              if (monitoring.catatan != null && monitoring.catatan!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.note,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          monitoring.catatan!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
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

  Widget _buildValueCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPpmColor(double ppm) {
    if (ppm < 800) return Colors.red;
    if (ppm > 1200) return Colors.orange;
    return Colors.green;
  }

  Color _getPhColor(double ph) {
    if (ph < 5.5 || ph > 6.5) return Colors.red;
    return Colors.green;
  }

  Color _getTempColor(double temp) {
    if (temp < 18 || temp > 25) return Colors.orange;
    return Colors.green;
  }

  void _showDateRangeFilter() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedStartDate != null && _selectedEndDate != null
          ? DateTimeRange(start: _selectedStartDate!, end: _selectedEndDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
      });
      context.read<MonitoringNutrisiProvider>().filterByDateRange(picked.start, picked.end);
    }
  }

  void _showAddEditDialog({MonitoringNutrisiModel? monitoring}) {
    final isEdit = monitoring != null;
    final tanggalController = TextEditingController(
      text: isEdit ? DateFormat('yyyy-MM-dd HH:mm').format(monitoring.tanggalMonitoring) : DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
    );
    final nilaiPpmController = TextEditingController(text: monitoring?.nilaiPpm?.toString() ?? '');
    final airDitambahController = TextEditingController(text: monitoring?.airDitambah?.toString() ?? '0');
    final nutrisiDitambahController = TextEditingController(text: monitoring?.nutrisiDitambah?.toString() ?? '0');
    final tingkatPhController = TextEditingController(text: monitoring?.tingkatPh?.toString() ?? '');
    final suhuAirController = TextEditingController(text: monitoring?.suhuAir?.toString() ?? '');
    final catatanController = TextEditingController(text: monitoring?.catatan ?? '');
    
    String? selectedTandonId = monitoring?.idTandon;
    DateTime selectedDate = monitoring?.tanggalMonitoring ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit Monitoring' : 'Tambah Monitoring'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date picker
                ListTile(
                  title: const Text('Tanggal & Waktu'),
                  subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDate),
                      );
                      if (time != null) {
                        setState(() {
                          selectedDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                          tanggalController.text = DateFormat('yyyy-MM-dd HH:mm').format(selectedDate);
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Tandon dropdown
                Consumer<MonitoringNutrisiProvider>(
                  builder: (context, provider, child) {
                    return DropdownButtonFormField<String>(
                      value: selectedTandonId,
                      decoration: const InputDecoration(
                        labelText: 'Tandon Air *',
                        border: OutlineInputBorder(),
                      ),
                      items: provider.tandonList.map((tandon) {
                        return DropdownMenuItem(
                          value: tandon.id,
                          child: Text(tandon.namaTandon ?? 'Tandon ${tandon.kodeTandon}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedTandonId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Tandon harus dipilih';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                // PPM value
                TextField(
                  controller: nilaiPpmController,
                  decoration: const InputDecoration(
                    labelText: 'Nilai PPM *',
                    border: OutlineInputBorder(),
                    suffixText: 'ppm',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                // pH level
                TextField(
                  controller: tingkatPhController,
                  decoration: const InputDecoration(
                    labelText: 'Tingkat pH *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                // Water temperature
                TextField(
                  controller: suhuAirController,
                  decoration: const InputDecoration(
                    labelText: 'Suhu Air *',
                    border: OutlineInputBorder(),
                    suffixText: '°C',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                // Water added
                TextField(
                  controller: airDitambahController,
                  decoration: const InputDecoration(
                    labelText: 'Air Ditambah',
                    border: OutlineInputBorder(),
                    suffixText: 'L',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                // Nutrient added
                TextField(
                  controller: nutrisiDitambahController,
                  decoration: const InputDecoration(
                    labelText: 'Nutrisi Ditambah',
                    border: OutlineInputBorder(),
                    suffixText: 'ml',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                // Notes
                TextField(
                  controller: catatanController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedTandonId == null || selectedTandonId!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tandon harus dipilih')),
                  );
                  return;
                }
                if (nilaiPpmController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nilai PPM harus diisi')),
                  );
                  return;
                }
                if (tingkatPhController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tingkat pH harus diisi')),
                  );
                  return;
                }
                if (suhuAirController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Suhu air harus diisi')),
                  );
                  return;
                }

                final authProvider = context.read<AuthProvider>();
                final monitoringProvider = context.read<MonitoringNutrisiProvider>();

                final newMonitoring = MonitoringNutrisiModel(
                  id: monitoring?.id ?? '',
                  tanggalMonitoring: selectedDate,
                  idTandon: selectedTandonId!,
                  nilaiPpm: double.tryParse(nilaiPpmController.text.trim()),
                  airDitambah: double.tryParse(airDitambahController.text.trim()),
                  nutrisiDitambah: double.tryParse(nutrisiDitambahController.text.trim()),
                   tingkatPh: double.tryParse(tingkatPhController.text.trim()),
                   suhuAir: double.tryParse(suhuAirController.text.trim()),
                  catatan: catatanController.text.trim().isEmpty ? null : catatanController.text.trim(),
                  dicatatOleh: authProvider.user?.idPengguna,
                  dicatatPada: monitoring?.dicatatPada ?? DateTime.now(),
                );

                bool success;
                if (isEdit) {
                  success = await monitoringProvider.updateMonitoring(newMonitoring);
                } else {
                  success = await monitoringProvider.tambahMonitoring(newMonitoring);
                }

                if (success) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEdit ? 'Monitoring berhasil diupdate' : 'Monitoring berhasil ditambahkan'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(monitoringProvider.error ?? 'Terjadi kesalahan'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(isEdit ? 'Update' : 'Simpan'),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Apakah Anda yakin ingin menghapus data monitoring ini?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(monitoring.tanggalMonitoring),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'PPM: ${monitoring.nilaiPpm ?? 0}, pH: ${monitoring.tingkatPh ?? 0}, Suhu: ${monitoring.suhuAir ?? 0}°C',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await context.read<MonitoringNutrisiProvider>().hapusMonitoring(monitoring.id);
              Navigator.of(context).pop();
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Monitoring berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gagal menghapus monitoring'),
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