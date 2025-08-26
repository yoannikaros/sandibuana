import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/monitoring_nutrisi_model.dart';
import '../models/tandon_air_model.dart';
import '../models/tandon_monitoring_data_model.dart';
import '../providers/monitoring_nutrisi_provider.dart';
import '../providers/auth_provider.dart';

class MonitoringNutrisiFormScreen extends StatefulWidget {
  final MonitoringNutrisiModel? monitoring;
  final bool isEdit;

  const MonitoringNutrisiFormScreen({
    Key? key,
    this.monitoring,
    this.isEdit = false,
  }) : super(key: key);

  @override
  State<MonitoringNutrisiFormScreen> createState() => _MonitoringNutrisiFormScreenState();
}

class _MonitoringNutrisiFormScreenState extends State<MonitoringNutrisiFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _tanggalController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedFilterType = 'pembenihan';
  String? _selectedPembenihanId;
  String? _selectedPenanamanId;
  List<TandonMonitoringDataModel> _tandonDataList = [];
  bool _isLoading = false;
  
  // Controllers untuk setiap tandon akan dibuat dinamis
  Map<String, Map<String, TextEditingController>> _tandonControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.isEdit && widget.monitoring != null) {
      final monitoring = widget.monitoring!;
      _namaController.text = monitoring.nama;
      _selectedDate = monitoring.tanggalMonitoring;
      _tanggalController.text = '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
      
      if (monitoring.idPembenihan != null) {
        _selectedFilterType = 'pembenihan';
        _selectedPembenihanId = monitoring.idPembenihan;
      } else if (monitoring.idPenanaman != null) {
        _selectedFilterType = 'penanaman';
        _selectedPenanamanId = monitoring.idPenanaman;
      }
      
      _tandonDataList = monitoring.tandonData ?? [];
      _initializeTandonControllers();
    } else {
      _tanggalController.text = '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
    }
  }
  
  void _initializeTandonControllers() {
    _tandonControllers.clear();
    for (var tandonData in _tandonDataList) {
      _tandonControllers[tandonData.idTandon] = {
        'ppm': TextEditingController(text: tandonData.nilaiPpm?.toString() ?? ''),
        'air': TextEditingController(text: tandonData.airDitambah?.toString() ?? ''),
        'nutrisi': TextEditingController(text: tandonData.nutrisiDitambah?.toString() ?? ''),
        'ph': TextEditingController(text: tandonData.tingkatPh?.toString() ?? ''),
        'suhu': TextEditingController(text: tandonData.suhuAir?.toString() ?? ''),
        'catatan': TextEditingController(text: tandonData.catatan ?? ''),
      };
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _tanggalController.dispose();
    // Dispose semua controllers tandon
    for (var controllers in _tandonControllers.values) {
      for (var controller in controllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _tanggalController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _showTandonSelectionDialog() async {
    final provider = Provider.of<MonitoringNutrisiProvider>(context, listen: false);
    List<String> tempSelectedIds = _tandonDataList.map((e) => e.idTandon).toList();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Pilih Tandon'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: provider.tandonList.length,
              itemBuilder: (context, index) {
                final TandonAirModel tandon = provider.tandonList[index];
                final isSelected = tempSelectedIds.contains(tandon.id);
                
                return CheckboxListTile(
                  title: Text('${tandon.namaTandon ?? 'Tandon'} (${tandon.kodeTandon})'),
                  subtitle: Text('Kapasitas: ${tandon.kapasitas} L'),
                  value: isSelected,
                  onChanged: (bool? value) {
                    setDialogState(() {
                      if (value == true) {
                        tempSelectedIds.add(tandon.id!);
                      } else {
                        tempSelectedIds.remove(tandon.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateTandonDataList(tempSelectedIds, provider);
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _updateTandonDataList(List<String> selectedIds, MonitoringNutrisiProvider provider) {
    setState(() {
      // Hapus tandon yang tidak dipilih
      _tandonDataList.removeWhere((data) => !selectedIds.contains(data.idTandon));
      
      // Tambah tandon baru yang dipilih
      for (String tandonId in selectedIds) {
        if (!_tandonDataList.any((data) => data.idTandon == tandonId)) {
          final tandon = provider.tandonList.firstWhere((t) => t.id == tandonId);
          _tandonDataList.add(TandonMonitoringDataModel(
            idTandon: tandonId,
            namaTandon: '${tandon.namaTandon ?? 'Tandon'} (${tandon.kodeTandon})',
          ));
        }
      }
      
      // Update controllers
      _initializeTandonControllers();
    });
  }

  Future<void> _saveMonitoring() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tandonDataList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu tandon')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<MonitoringNutrisiProvider>(context, listen: false);
      
      // Update tandon data dengan nilai dari controllers
      List<TandonMonitoringDataModel> updatedTandonData = [];
      for (var tandonData in _tandonDataList) {
        final controllers = _tandonControllers[tandonData.idTandon]!;
        updatedTandonData.add(tandonData.copyWith(
          nilaiPpm: double.tryParse(controllers['ppm']!.text),
          airDitambah: double.tryParse(controllers['air']!.text),
          nutrisiDitambah: double.tryParse(controllers['nutrisi']!.text),
          tingkatPh: double.tryParse(controllers['ph']!.text),
          suhuAir: double.tryParse(controllers['suhu']!.text),
          catatan: controllers['catatan']!.text.isEmpty ? null : controllers['catatan']!.text,
        ));
      }
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;
      
      final monitoring = MonitoringNutrisiModel(
        id: widget.isEdit ? widget.monitoring!.id : '',
        nama: _namaController.text,
        tanggalMonitoring: _selectedDate,
        idPembenihan: _selectedFilterType == 'pembenihan' ? _selectedPembenihanId : null,
        idPenanaman: _selectedFilterType == 'penanaman' ? _selectedPenanamanId : null,
        tandonData: updatedTandonData,
        dicatatOleh: currentUser?.namaPengguna ?? 'Unknown User',
        dicatatPada: DateTime.now(),
      );

      if (widget.isEdit) {
        await provider.updateMonitoring(monitoring);
      } else {
        await provider.tambahMonitoring(monitoring);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdit 
              ? 'Monitoring berhasil diperbarui' 
              : 'Monitoring berhasil ditambahkan'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Monitoring Nutrisi' : 'Tambah Monitoring Nutrisi'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(
              onPressed: _saveMonitoring,
              icon: const Icon(Icons.save),
            ),
        ],
      ),
      body: Consumer<MonitoringNutrisiProvider>(
        builder: (context, provider, child) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Nama Paket
                TextFormField(
                  controller: _namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Paket',
                    border: OutlineInputBorder(),
                    hintText: 'Masukkan nama paket monitoring',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama paket harus diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Tanggal Monitoring
                TextFormField(
                  controller: _tanggalController,
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Monitoring',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: _selectDate,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Tanggal monitoring harus diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Tipe Relasi
                DropdownButtonFormField<String>(
                  value: _selectedFilterType,
                  decoration: const InputDecoration(
                    labelText: 'Tipe Relasi',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'pembenihan', child: Text('Pembenihan')),
                    DropdownMenuItem(value: 'penanaman', child: Text('Penanaman')),
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

                // Pemilihan ID berdasarkan tipe
                if (_selectedFilterType == 'pembenihan')
                  DropdownButtonFormField<String>(
                    value: _selectedPembenihanId,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Pembenihan',
                      border: OutlineInputBorder(),
                    ),
                    items: provider.pembenihanList.map((pembenihan) {
                      return DropdownMenuItem<String>(
                        value: pembenihan.idPembenihan,
                        child: Text('${pembenihan.kodeBatch} - ${pembenihan.tanggalSemai.day}/${pembenihan.tanggalSemai.month}/${pembenihan.tanggalSemai.year}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPembenihanId = value;
                      });
                    },
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _selectedPenanamanId,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Penanaman',
                      border: OutlineInputBorder(),
                    ),
                    items: provider.penanamanList.map((penanaman) {
                      return DropdownMenuItem<String>(
                        value: penanaman.idPenanaman,
                        child: Text('${penanaman.jenisSayur} - ${penanaman.tanggalTanam.day}/${penanaman.tanggalTanam.month}/${penanaman.tanggalTanam.year}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPenanamanId = value;
                      });
                    },
                  ),
                const SizedBox(height: 16),

                // Pilih Tandon
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Pilih Tandon',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            ElevatedButton.icon(
                              onPressed: _showTandonSelectionDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Pilih Tandon'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_tandonDataList.isEmpty)
                          const Text(
                            'Belum ada tandon dipilih',
                            style: TextStyle(color: Colors.grey),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            children: _tandonDataList.map((tandonData) {
                              return Chip(
                                label: Text(tandonData.namaTandon),
                                deleteIcon: const Icon(Icons.close, size: 18),
                                onDeleted: () {
                                  setState(() {
                                    _tandonDataList.removeWhere((data) => data.idTandon == tandonData.idTandon);
                                    _tandonControllers.remove(tandonData.idTandon);
                                  });
                                },
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Form Input per Tandon
                ..._tandonDataList.map((tandonData) => _buildTandonForm(tandonData)).toList(),
                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveMonitoring,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(widget.isEdit ? 'Update Monitoring' : 'Simpan Monitoring'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildTandonForm(TandonMonitoringDataModel tandonData) {
    final controllers = _tandonControllers[tandonData.idTandon]!;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tandonData.namaTandon,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            
            // Nilai PPM
            TextFormField(
              controller: controllers['ppm'],
              decoration: const InputDecoration(
                labelText: 'Nilai PPM',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.analytics),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            
            // Air Ditambah
            TextFormField(
              controller: controllers['air'],
              decoration: const InputDecoration(
                labelText: 'Air Ditambah (Liter)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.water_drop),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            
            // Nutrisi Ditambah
            TextFormField(
              controller: controllers['nutrisi'],
              decoration: const InputDecoration(
                labelText: 'Nutrisi Ditambah (Liter)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.eco),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            
            // Tingkat pH
            TextFormField(
              controller: controllers['ph'],
              decoration: const InputDecoration(
                labelText: 'Tingkat pH',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.science),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            
            // Suhu Air
            TextFormField(
              controller: controllers['suhu'],
              decoration: const InputDecoration(
                labelText: 'Suhu Air (°C)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.thermostat),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            
            // Catatan
            TextFormField(
              controller: controllers['catatan'],
              decoration: const InputDecoration(
                labelText: 'Catatan',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}