import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/jadwal_pemupukan_model.dart';
import '../providers/jadwal_pemupukan_provider.dart';
import '../providers/auth_provider.dart';


class JadwalPemupukanScreen extends StatefulWidget {
  const JadwalPemupukanScreen({super.key});

  @override
  State<JadwalPemupukanScreen> createState() => _JadwalPemupukanScreenState();
}

class _JadwalPemupukanScreenState extends State<JadwalPemupukanScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JadwalPemupukanProvider>().loadJadwalByBulan(_selectedMonth);
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
        title: const Text('Jadwal Pemupukan Bulanan'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [

          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<JadwalPemupukanProvider>().refresh();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'generate':
                  _showGenerateDialog();
                  break;
                case 'statistics':
                  _showStatisticsDialog();
                  break;
                case 'upcoming':
                  context.read<JadwalPemupukanProvider>().loadJadwalMendatang();
                  break;
                case 'overdue':
                  context.read<JadwalPemupukanProvider>().loadJadwalTerlambat();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'generate',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Generate Jadwal'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'statistics',
                child: Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Statistik'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'upcoming',
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Jadwal Mendatang'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'overdue',
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Jadwal Terlambat'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(
            child: Consumer<JadwalPemupukanProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${provider.error}',
                          style: TextStyle(color: Colors.red[700]),
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

                if (provider.jadwalList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada jadwal pemupukan',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showAddDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah Jadwal'),
                        ),
                      ],
                    ),
                  );
                }

                return _buildJadwalList(provider.getJadwalByPriority());
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border(bottom: BorderSide(color: Colors.green[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _selectMonth,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down, color: Colors.green[700]),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Consumer<JadwalPemupukanProvider>(
            builder: (context, provider, child) {
              final counts = provider.getCountByStatus();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total: ${counts['total']}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        _buildStatusChip('Selesai', counts['selesai']!, Colors.green),
                        const SizedBox(width: 4),
                        _buildStatusChip('Terlambat', counts['terlambat']!, Colors.red),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari nama sayur...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context.read<JadwalPemupukanProvider>().setSearchQuery('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              context.read<JadwalPemupukanProvider>().setSearchQuery(value);
            },
          ),
          const SizedBox(height: 12),
          // Filter chips
          Consumer<JadwalPemupukanProvider>(
            builder: (context, provider, child) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      'Semua',
                      provider.statusFilter == 'semua',
                      () => provider.setStatusFilter('semua'),
                    ),
                    _buildFilterChip(
                      'Selesai',
                      provider.statusFilter == 'selesai',
                      () => provider.setStatusFilter('selesai'),
                    ),
                    _buildFilterChip(
                      'Belum Selesai',
                      provider.statusFilter == 'belum_selesai',
                      () => provider.setStatusFilter('belum_selesai'),
                    ),
                    _buildFilterChip(
                      'Terlambat',
                      provider.statusFilter == 'terlambat',
                      () => provider.setStatusFilter('terlambat'),
                    ),
                    const SizedBox(width: 8),
                    // Minggu filter
                    DropdownButton<int>(
                      value: provider.mingguFilter,
                      hint: const Text('Minggu'),
                      items: [
                        const DropdownMenuItem(value: 0, child: Text('Semua Minggu')),
                        ...provider.getOptionsMinggu().map((option) =>
                          DropdownMenuItem<int>(
                            value: option['value'] as int,
                            child: Text(option['label'] as String),
                          ),
                        ),
                      ],
                      onChanged: (value) => provider.setMingguFilter(value ?? 0),
                    ),
                    const SizedBox(width: 8),
                    // Hari filter
                    DropdownButton<int>(
                      value: provider.hariFilter,
                      hint: const Text('Hari'),
                      items: [
                        const DropdownMenuItem(value: 0, child: Text('Semua Hari')),
                        ...provider.getOptionsHari().map((option) =>
                          DropdownMenuItem<int>(
                            value: option['value'] as int,
                            child: Text(option['label'] as String),
                          ),
                        ),
                      ],
                      onChanged: (value) => provider.setHariFilter(value ?? 0),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: Colors.green[100],
        checkmarkColor: Colors.green[700],
      ),
    );
  }

  Widget _buildJadwalList(List<JadwalPemupukanModel> jadwalList) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: jadwalList.length,
      itemBuilder: (context, index) {
        final jadwal = jadwalList[index];
        return _buildJadwalCard(jadwal);
      },
    );
  }

  Widget _buildJadwalCard(JadwalPemupukanModel jadwal) {
    final targetDate = jadwal.getTanggalTarget();
    final isOverdue = jadwal.isOverdue();
    final priority = jadwal.getPriority();
    
    Color borderColor = Colors.grey[300]!;
    Color statusColor = Colors.grey;
    
    if (jadwal.sudahSelesai) {
      borderColor = Colors.green[300]!;
      statusColor = Colors.green;
    } else if (isOverdue) {
      borderColor = Colors.red[300]!;
      statusColor = Colors.red;
    } else if (priority > 1) {
      borderColor = Colors.orange[300]!;
      statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetailDialog(jadwal),
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
                          'Minggu ${jadwal.mingguKe} - ${JadwalPemupukanModel.getNamaHari(jadwal.hariDalamMinggu)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMMM yyyy', 'id_ID').format(targetDate),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      JadwalPemupukanModel.getStatusText(jadwal.sudahSelesai),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer<JadwalPemupukanProvider>(
                      builder: (context, provider, child) {
                        final displayName = jadwal.getDisplayNamaSayur(provider.penanamanSayurList);
                        return Row(
                          children: [
                            Icon(Icons.eco, size: 16, color: Colors.green[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    Consumer<JadwalPemupukanProvider>(
                      builder: (context, provider, child) {
                        final List<Widget> relationWidgets = [];
                        
                        // Show planting relationship
                        if (jadwal.idPenanaman != null) {
                          final detailPenanaman = jadwal.getDisplayDetailPenanaman(provider.penanamanSayurList);
                          relationWidgets.add(
                            Row(
                              children: [
                                Icon(Icons.agriculture, size: 16, color: Colors.blue[700]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Penanaman: $detailPenanaman',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        // Show seeding relationship
                        if (jadwal.idPembenihan != null) {
                          final namaPembenihan = provider.getCatatanPembenihanName(jadwal.idPembenihan!);
                          relationWidgets.add(
                            Row(
                              children: [
                                Icon(Icons.eco, size: 16, color: Colors.teal[700]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Pembenihan: ${namaPembenihan ?? 'Data tidak ditemukan'}',
                                    style: TextStyle(
                                      color: Colors.teal[700],
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        if (relationWidgets.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        
                        return Column(
                          children: [
                            const SizedBox(height: 8),
                            ...relationWidgets.map((widget) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: widget,
                            )),
                          ],
                        );
                      },
                    ),

                    if (jadwal.catatan != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.note, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              jadwal.catatan!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (jadwal.sudahSelesai) ...[
                    Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Selesai ${DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(jadwal.diselesaikanPada!)}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                      ),
                    ),
                  ] else ...[
                    if (isOverdue) ...[
                      Icon(Icons.warning, size: 16, color: Colors.red[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Terlambat',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else ...[
                      Icon(Icons.schedule, size: 16, color: Colors.orange[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Menunggu',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!jadwal.sudahSelesai) ...[
                        IconButton(
                          icon: Icon(Icons.check, color: Colors.green[700]),
                          onPressed: () => _markAsCompleted(jadwal),
                          tooltip: 'Tandai Selesai',
                        ),
                      ] else ...[
                        IconButton(
                          icon: Icon(Icons.undo, color: Colors.orange[700]),
                          onPressed: () => _markAsIncomplete(jadwal),
                          tooltip: 'Batalkan Selesai',
                        ),
                      ],
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue[700]),
                        onPressed: () => _showEditDialog(jadwal),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red[700]),
                        onPressed: () => _confirmDelete(jadwal),
                        tooltip: 'Hapus',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );
    
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
      });
      context.read<JadwalPemupukanProvider>().setSelectedMonth(_selectedMonth);
    }
  }

  void _showAddDialog() {
    _showJadwalDialog();
  }

  void _showEditDialog(JadwalPemupukanModel jadwal) {
    _showJadwalDialog(jadwal: jadwal);
  }

  void _showJadwalDialog({JadwalPemupukanModel? jadwal}) {
    final isEdit = jadwal != null;
    final formKey = GlobalKey<FormState>();
    
    DateTime selectedBulanTahun = jadwal?.bulanTahun ?? _selectedMonth;
    int selectedMinggu = jadwal?.mingguKe ?? 1;
    int selectedHari = jadwal?.hariDalamMinggu ?? 1;
    String namaSayur = jadwal?.namaSayur ?? '';
    String? selectedPembenihan = jadwal?.idPembenihan;
    String? selectedPenanaman = jadwal?.idPenanaman;
    String catatan = jadwal?.catatan ?? '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit Jadwal Pemupukan' : 'Tambah Jadwal Pemupukan'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bulan Tahun
                  ListTile(
                    title: const Text('Bulan/Tahun'),
                    subtitle: Text(DateFormat('MMMM yyyy', 'id_ID').format(selectedBulanTahun)),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedBulanTahun,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        initialDatePickerMode: DatePickerMode.year,
                      );
                      if (picked != null) {
                        setState(() {
                          selectedBulanTahun = DateTime(picked.year, picked.month, 1);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Minggu
                  Consumer<JadwalPemupukanProvider>(
                    builder: (context, provider, child) {
                      return DropdownButtonFormField<int>(
                        value: selectedMinggu,
                        decoration: const InputDecoration(
                          labelText: 'Minggu',
                          border: OutlineInputBorder(),
                        ),
                        items: provider.getOptionsMinggu().map((option) =>
                          DropdownMenuItem<int>(
                            value: option['value'] as int,
                            child: Text(option['label'] as String),
                          ),
                        ).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedMinggu = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null) return 'Pilih minggu';
                          return null;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Hari
                  Consumer<JadwalPemupukanProvider>(
                    builder: (context, provider, child) {
                      return DropdownButtonFormField<int>(
                        value: selectedHari,
                        decoration: const InputDecoration(
                          labelText: 'Hari',
                          border: OutlineInputBorder(),
                        ),
                        items: provider.getOptionsHari().map((option) =>
                          DropdownMenuItem<int>(
                            value: option['value'] as int,
                            child: Text(option['label'] as String),
                          ),
                        ).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedHari = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null) return 'Pilih hari';
                          return null;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Nama Sayur
                  TextFormField(
                    initialValue: namaSayur,
                    decoration: const InputDecoration(
                      labelText: 'Nama Sayur',
                      border: OutlineInputBorder(),
                      hintText: 'Masukkan nama sayur yang akan dipupuk',
                    ),
                    onChanged: (value) => namaSayur = value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama sayur harus diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Pembenihan Terkait
                  Consumer<JadwalPemupukanProvider>(
                    builder: (context, provider, child) {
                      final activePembenihan = provider.getActiveCatatanPembenihan();
                      
                      return DropdownButtonFormField<String>(
                        value: selectedPembenihan,
                        decoration: const InputDecoration(
                          labelText: 'Pembenihan Terkait (Opsional)',
                          border: OutlineInputBorder(),
                          hintText: 'Pilih pembenihan yang akan dipupuk',
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Tidak terkait dengan pembenihan'),
                          ),
                          ...activePembenihan.map((pembenihan) =>
                            DropdownMenuItem<String>(
                              value: pembenihan.idPembenihan,
                              child: Text('${pembenihan.kodeBatch} - ${pembenihan.status}'),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedPembenihan = value;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Penanaman Sayur Terkait
                  Consumer<JadwalPemupukanProvider>(
                    builder: (context, provider, child) {
                      final activePenanaman = provider.getActivePenanamanSayur();
                      
                      return DropdownButtonFormField<String>(
                        value: selectedPenanaman,
                        decoration: const InputDecoration(
                          labelText: 'Penanaman Sayur Terkait (Opsional)',
                          border: OutlineInputBorder(),
                          hintText: 'Pilih penanaman sayur yang akan dipupuk',
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Tidak terkait dengan penanaman'),
                          ),
                          ...activePenanaman.map((penanaman) {
                            final displayName = provider.getPenanamanSayurName(penanaman.idPenanaman);
                            return DropdownMenuItem<String>(
                              value: penanaman.idPenanaman,
                              child: Text(displayName),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedPenanaman = value;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Catatan
                  TextFormField(
                    initialValue: catatan,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (Opsional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) => catatan = value,
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
                  bool success;
                  
                  if (isEdit) {
                    success = await context.read<JadwalPemupukanProvider>().updateJadwalPemupukan(
                      jadwal.idJadwal,
                      {
                        'bulan_tahun': selectedBulanTahun,
                        'minggu_ke': selectedMinggu,
                        'hari_dalam_minggu': selectedHari,
                        'nama_sayur': namaSayur,
                        'id_pembenihan': selectedPembenihan,
                        'id_penanaman': selectedPenanaman,
                        'catatan': catatan.isEmpty ? null : catatan,
                      },
                    );
                  } else {
                    success = await context.read<JadwalPemupukanProvider>().tambahJadwalPemupukan(
                      bulanTahun: selectedBulanTahun,
                      mingguKe: selectedMinggu,
                      hariDalamMinggu: selectedHari,
                      namaSayur: namaSayur,
                      idPembenihan: selectedPembenihan,
                      idPenanaman: selectedPenanaman,
                      catatan: catatan.isEmpty ? null : catatan,
                    );
                  }
                  
                  if (success) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit ? 'Jadwal berhasil diupdate' : 'Jadwal berhasil ditambahkan'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.read<JadwalPemupukanProvider>().error ?? 'Terjadi kesalahan'),
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

  void _showDetailDialog(JadwalPemupukanModel jadwal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail Jadwal - Minggu ${jadwal.mingguKe}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Bulan/Tahun', DateFormat('MMMM yyyy', 'id_ID').format(jadwal.bulanTahun)),
              _buildDetailRow('Minggu', 'Minggu ke-${jadwal.mingguKe}'),
              _buildDetailRow('Hari', JadwalPemupukanModel.getNamaHari(jadwal.hariDalamMinggu)),
              _buildDetailRow('Tanggal Target', DateFormat('dd MMMM yyyy', 'id_ID').format(jadwal.getTanggalTarget())),
              _buildDetailRow('Nama Sayur', jadwal.namaSayur),
              Consumer<JadwalPemupukanProvider>(
                builder: (context, provider, child) {
                  if (jadwal.idPembenihan != null) {
                    final namaPembenihan = provider.getCatatanPembenihanName(jadwal.idPembenihan!);
                    return _buildDetailRow('Pembenihan Terkait', namaPembenihan ?? 'Data tidak ditemukan');
                  }
                  return const SizedBox.shrink();
                },
              ),

              if (jadwal.catatan != null)
                _buildDetailRow('Catatan', jadwal.catatan!),
              _buildDetailRow('Status', JadwalPemupukanModel.getStatusText(jadwal.sudahSelesai)),
              if (jadwal.sudahSelesai) ...[
                _buildDetailRow('Diselesaikan Oleh', jadwal.diselesaikanOleh ?? '-'),
                _buildDetailRow('Diselesaikan Pada', 
                  jadwal.diselesaikanPada != null 
                    ? DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(jadwal.diselesaikanPada!) 
                    : '-'),
              ],
              _buildDetailRow('Dibuat Oleh', jadwal.dibuatOleh),
              _buildDetailRow('Dibuat Pada', DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(jadwal.dibuatPada)),
            ],
          ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showGenerateDialog() {
    DateTime selectedMonth = _selectedMonth;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Generate Jadwal Bulanan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pilih bulan untuk generate jadwal otomatis:'),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Bulan/Tahun'),
                subtitle: Text(DateFormat('MMMM yyyy', 'id_ID').format(selectedMonth)),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedMonth,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    initialDatePickerMode: DatePickerMode.year,
                  );
                  if (picked != null) {
                    setState(() {
                      selectedMonth = DateTime(picked.year, picked.month, 1);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Ini akan membuat jadwal template untuk 4 minggu dengan perlakuan pupuk standar.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Simpan referensi ScaffoldMessenger sebelum menutup dialog
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final success = await context.read<JadwalPemupukanProvider>().generateJadwalBulanan(selectedMonth);
                Navigator.pop(context);
                
                if (success) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Jadwal bulanan berhasil digenerate'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(context.read<JadwalPemupukanProvider>().error ?? 'Gagal generate jadwal'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatisticsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistik Jadwal Pemupukan'),
        content: Consumer<JadwalPemupukanProvider>(
          builder: (context, provider, child) {
            final statistik = provider.statistik;
            if (statistik == null) {
              return const Text('Data statistik tidak tersedia');
            }
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bulan: ${statistik['bulan_tahun']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                _buildStatRow('Total Jadwal', '${statistik['total_jadwal']}'),
                _buildStatRow('Selesai', '${statistik['selesai']}', Colors.green),
                _buildStatRow('Belum Selesai', '${statistik['belum_selesai']}', Colors.orange),
                _buildStatRow('Terlambat', '${statistik['terlambat']}', Colors.red),
                const Divider(),
                _buildStatRow('Persentase Selesai', '${statistik['persentase_selesai'].toStringAsFixed(1)}%', Colors.blue),
              ],
            );
          },
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

  Widget _buildStatRow(String label, String value, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _markAsCompleted(JadwalPemupukanModel jadwal) async {
    final success = await context.read<JadwalPemupukanProvider>().tandaiSelesai(jadwal.idJadwal);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jadwal ditandai sebagai selesai'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<JadwalPemupukanProvider>().error ?? 'Gagal menandai jadwal sebagai selesai'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _markAsIncomplete(JadwalPemupukanModel jadwal) async {
    final success = await context.read<JadwalPemupukanProvider>().batalkanSelesai(jadwal.idJadwal);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status selesai dibatalkan'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<JadwalPemupukanProvider>().error ?? 'Gagal membatalkan status selesai'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDelete(JadwalPemupukanModel jadwal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus jadwal minggu ${jadwal.mingguKe} - ${JadwalPemupukanModel.getNamaHari(jadwal.hariDalamMinggu)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Simpan referensi ScaffoldMessenger sebelum menutup dialog
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              
              final success = await context.read<JadwalPemupukanProvider>().hapusJadwalPemupukan(jadwal.idJadwal);
              if (success) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Jadwal berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(context.read<JadwalPemupukanProvider>().error ?? 'Gagal menghapus jadwal'),
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
}