import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/monitoring_nutrisi_model.dart';
import '../models/tandon_air_model.dart';
import '../providers/monitoring_nutrisi_provider.dart';
import '../providers/auth_provider.dart';
import 'monitoring_nutrisi_form_screen.dart';
import 'monitoring_nutrisi_detail_screen.dart';

class MonitoringNutrisiScreen extends StatefulWidget {
  const MonitoringNutrisiScreen({super.key});

  @override
  State<MonitoringNutrisiScreen> createState() => _MonitoringNutrisiScreenState();
}

class _MonitoringNutrisiScreenState extends State<MonitoringNutrisiScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedPembenihanId;
  String? _selectedPenanamanId;
  String _selectedFilterType = 'pembenihan'; // 'pembenihan' or 'penanaman'

  @override
  void initState() {
    super.initState();
    // Initialize Indonesian locale for DateFormat
    initializeDateFormatting('id_ID', null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    try {
      final provider = context.read<MonitoringNutrisiProvider>();
      await provider.initialize();
    } catch (e) {
      print('Error initializing monitoring nutrisi data: $e');
    }
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
              context.read<MonitoringNutrisiProvider>().refresh();
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
                            context.read<MonitoringNutrisiProvider>().search('');
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
                  context.read<MonitoringNutrisiProvider>().search(value);
                },
              ),
            ),
            
            // Filter Chips
            if (_selectedDate != null || _selectedPembenihanId != null || _selectedPenanamanId != null)
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
                    if (_selectedPembenihanId != null)
                      Consumer<MonitoringNutrisiProvider>(
                        builder: (context, provider, child) {
                          final pembenihanName = provider.getPembenihanName(_selectedPembenihanId!);
                          return FilterChip(
                            label: Text('Pembenihan: $pembenihanName'),
                            selected: true,
                            onSelected: (bool selected) {
                              if (!selected) {
                                setState(() {
                                  _selectedPembenihanId = null;
                                });
                                _applyFilters();
                              }
                            },
                            onDeleted: () {
                              setState(() {
                                _selectedPembenihanId = null;
                              });
                              _applyFilters();
                            },
                          );
                        },
                      ),
                    if (_selectedPenanamanId != null)
                      Consumer<MonitoringNutrisiProvider>(
                        builder: (context, provider, child) {
                          final penanamanName = provider.getPenanamanName(_selectedPenanamanId!);
                          return FilterChip(
                            label: Text('Penanaman: $penanamanName'),
                            selected: true,
                            onSelected: (bool selected) {
                              if (!selected) {
                                setState(() {
                                  _selectedPenanamanId = null;
                                });
                                _applyFilters();
                              }
                            },
                            onDeleted: () {
                              setState(() {
                                _selectedPenanamanId = null;
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
                child: Consumer<MonitoringNutrisiProvider>(
                  builder: (context, monitoringProvider, child) {
                    if (monitoringProvider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (monitoringProvider.error != null) {
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
                              monitoringProvider.error!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                monitoringProvider.refresh();
                              },
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      );
                    }

                    final monitoringList = monitoringProvider.filteredMonitoringList;

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
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const MonitoringNutrisiFormScreen(),
                                  ),
                                );
                                if (result == true) {
                                  context.read<MonitoringNutrisiProvider>().refresh();
                                }
                              },
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
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MonitoringNutrisiFormScreen(),
            ),
          );
          if (result == true) {
            // Refresh data if needed
            context.read<MonitoringNutrisiProvider>().refresh();
          }
        },
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
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MonitoringNutrisiDetailScreen(
                monitoring: monitoring,
              ),
            ),
          );
          if (result == true) {
            // Refresh data if needed
            context.read<MonitoringNutrisiProvider>().refresh();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nama Paket
              Text(
                monitoring.nama,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              
              // Tanggal
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd MMMM yyyy', 'id_ID').format(monitoring.tanggalMonitoring),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Dicatat oleh
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dicatat oleh: ${monitoring.dicatatOleh}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
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
              const SizedBox(height: 16),
              
              // Filter Type Selection
              DropdownButtonFormField<String>(
                value: _selectedFilterType,
                decoration: const InputDecoration(
                  labelText: 'Tipe Filter',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'pembenihan',
                    child: Text('Berdasarkan Pembenihan'),
                  ),
                  DropdownMenuItem(
                    value: 'penanaman',
                    child: Text('Berdasarkan Penanaman'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedFilterType = value!;
                    _selectedPembenihanId = null;
                    _selectedPenanamanId = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Dynamic Filter based on type
              Consumer<MonitoringNutrisiProvider>(
                builder: (context, provider, child) {
                  if (_selectedFilterType == 'pembenihan') {
                    return DropdownButtonFormField<String>(
                      value: _selectedPembenihanId,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Pembenihan',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Semua pembenihan'),
                        ),
                        ...provider.pembenihanList.map(
                          (pembenihan) => DropdownMenuItem<String>(
                            value: pembenihan.idPembenihan,
                            child: Text('${pembenihan.kodeBatch} - ${pembenihan.idBenih}'),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedPembenihanId = value;
                        });
                      },
                    );
                  } else {
                    return DropdownButtonFormField<String>(
                      value: _selectedPenanamanId,
                      decoration: const InputDecoration(
                        labelText: 'Penanaman Sayur',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Semua penanaman'),
                        ),
                        ...provider.penanamanList.map(
                          (penanaman) => DropdownMenuItem<String>(
                            value: penanaman.idPenanaman,
                            child: Text('${penanaman.jenisSayur} - ${DateFormat('dd/MM/yyyy').format(penanaman.tanggalTanam)}'),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedPenanamanId = value;
                        });
                      },
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedDate = null;
                  _selectedPembenihanId = null;
                  _selectedPenanamanId = null;
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
    final provider = context.read<MonitoringNutrisiProvider>();
    
    if (_selectedDate != null) {
      provider.filterByDate(_selectedDate!);
    }
    
    if (_selectedPembenihanId != null) {
      provider.filterByPembenihan(_selectedPembenihanId!);
    } else if (_selectedPenanamanId != null) {
      provider.filterByPenanaman(_selectedPenanamanId!);
    }
    
    if (_selectedDate == null && _selectedPembenihanId == null && _selectedPenanamanId == null) {
      provider.clearFilters();
    }
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
                  .read<MonitoringNutrisiProvider>()
                  .deleteMonitoring(monitoring.id!);

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
                      context.read<MonitoringNutrisiProvider>().error ??
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