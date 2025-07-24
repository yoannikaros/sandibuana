import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/catatan_perlakuan_model.dart';
import '../providers/catatan_perlakuan_provider.dart';

class CatatanPerlakuanScreen extends StatefulWidget {
  const CatatanPerlakuanScreen({Key? key}) : super(key: key);

  @override
  State<CatatanPerlakuanScreen> createState() => _CatatanPerlakuanScreenState();
}

class _CatatanPerlakuanScreenState extends State<CatatanPerlakuanScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialize Indonesian locale for DateFormat
    initializeDateFormatting('id_ID', null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatatanPerlakuanProvider>().loadCatatanPerlakuan();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Perlakuan'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showStatistikDialog(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'refresh':
                  context.read<CatatanPerlakuanProvider>().refresh();
                  break;
                case 'clear_filters':
                  context.read<CatatanPerlakuanProvider>().clearFilters();
                  _searchController.clear();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_filters',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
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
          Expanded(
            child: Consumer<CatatanPerlakuanProvider>(
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

                if (provider.catatanPerlakuan.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_add_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada catatan perlakuan',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap tombol + untuk menambah catatan',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.refresh(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.catatanPerlakuan.length,
                    itemBuilder: (context, index) {
                      final perlakuan = provider.catatanPerlakuan[index];
                      return _buildCatatanPerlakuanCard(perlakuan);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTambahCatatanDialog(context),
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border(
          bottom: BorderSide(color: Colors.green[200]!),
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari catatan perlakuan...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context.read<CatatanPerlakuanProvider>().setSearchQuery('');
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
              context.read<CatatanPerlakuanProvider>().setSearchQuery(value);
            },
          ),
          const SizedBox(height: 12),
          Consumer<CatatanPerlakuanProvider>(
            builder: (context, provider, child) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      'Jenis: ${provider.selectedJenis}',
                      provider.selectedJenis != 'Semua',
                      () => _showJenisFilterDialog(context),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Area: ${provider.selectedArea}',
                      provider.selectedArea != 'Semua',
                      () => _showAreaFilterDialog(context),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Rating: ${provider.selectedRating ?? 'Semua'}',
                      provider.selectedRating != null,
                      () => _showRatingFilterDialog(context),
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

  Widget _buildFilterChip(String label, bool isActive, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.white,
      selectedColor: Colors.green[100],
      checkmarkColor: Colors.green[700],
    );
  }

  Widget _buildCatatanPerlakuanCard(CatatanPerlakuanModel perlakuan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: perlakuan.getStatusColor().withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetailDialog(context, perlakuan),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: perlakuan.getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: perlakuan.getStatusColor().withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          perlakuan.getStatusIcon(),
                          size: 16,
                          color: perlakuan.getStatusColor(),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          perlakuan.jenisPerlakuan,
                          style: TextStyle(
                            color: perlakuan.getStatusColor(),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditCatatanDialog(context, perlakuan);
                          break;
                        case 'delete':
                          _showDeleteConfirmDialog(context, perlakuan);
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
                ],
              ),
              const SizedBox(height: 12),
              Text(
                perlakuan.getDisplayTitle(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                perlakuan.getDisplaySubtitle(),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              if (perlakuan.catatan?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.note, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          perlakuan.catatan!,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    perlakuan.formattedTanggalPerlakuan,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (perlakuan.ratingEfektivitas != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: perlakuan.getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: perlakuan.getStatusColor(),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${perlakuan.ratingEfektivitas}',
                            style: TextStyle(
                              color: perlakuan.getStatusColor(),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Catatan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Filter by Jenis'),
              onTap: () {
                Navigator.pop(context);
                _showJenisFilterDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Filter by Area'),
              onTap: () {
                Navigator.pop(context);
                _showAreaFilterDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Filter by Rating'),
              onTap: () {
                Navigator.pop(context);
                _showRatingFilterDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Filter by Tanggal'),
              onTap: () {
                Navigator.pop(context);
                _showDateRangeDialog(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<CatatanPerlakuanProvider>().clearFilters();
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showJenisFilterDialog(BuildContext context) {
    final provider = context.read<CatatanPerlakuanProvider>();
    final jenisOptions = provider.getUniqueJenisPerlakuan();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Jenis Perlakuan'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: jenisOptions.length,
            itemBuilder: (context, index) {
              final jenis = jenisOptions[index];
              return RadioListTile<String>(
                title: Text(jenis),
                value: jenis,
                groupValue: provider.selectedJenis,
                onChanged: (value) {
                  if (value != null) {
                    provider.setJenisFilter(value);
                    Navigator.pop(context);
                  }
                },
              );
            },
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

  void _showAreaFilterDialog(BuildContext context) {
    final provider = context.read<CatatanPerlakuanProvider>();
    final areaOptions = provider.getUniqueAreaTanaman();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Area Tanaman'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: areaOptions.length,
            itemBuilder: (context, index) {
              final area = areaOptions[index];
              return RadioListTile<String>(
                title: Text(area),
                value: area,
                groupValue: provider.selectedArea,
                onChanged: (value) {
                  if (value != null) {
                    provider.setAreaFilter(value);
                    Navigator.pop(context);
                  }
                },
              );
            },
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

  void _showRatingFilterDialog(BuildContext context) {
    final provider = context.read<CatatanPerlakuanProvider>();
    final ratingOptions = [null, ...provider.getUniqueRatings()];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Rating'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: ratingOptions.length,
            itemBuilder: (context, index) {
              final rating = ratingOptions[index];
              return RadioListTile<int?>(
                title: Text(rating == null ? 'Semua' : 'Rating $rating'),
                value: rating,
                groupValue: provider.selectedRating,
                onChanged: (value) {
                  provider.setRatingFilter(value);
                  Navigator.pop(context);
                },
              );
            },
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

  void _showDateRangeDialog(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: context.read<CatatanPerlakuanProvider>().startDate != null &&
              context.read<CatatanPerlakuanProvider>().endDate != null
          ? DateTimeRange(
              start: context.read<CatatanPerlakuanProvider>().startDate!,
              end: context.read<CatatanPerlakuanProvider>().endDate!,
            )
          : null,
    );

    if (picked != null) {
      context.read<CatatanPerlakuanProvider>().loadCatatanPerlakuanByDateRange(
            picked.start,
            picked.end,
          );
    }
  }

  void _showStatistikDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistik & Laporan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.pie_chart),
              title: const Text('Statistik by Jenis'),
              onTap: () {
                Navigator.pop(context);
                _showStatistikJenisDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Statistik by Area'),
              onTap: () {
                Navigator.pop(context);
                _showStatistikAreaDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.assessment),
              title: const Text('Laporan Efektivitas'),
              onTap: () {
                Navigator.pop(context);
                _showLaporanEfektivitasDialog(context);
              },
            ),
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

  void _showStatistikJenisDialog(BuildContext context) async {
    final provider = context.read<CatatanPerlakuanProvider>();
    final statistik = await provider.getStatistikByJenis();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistik by Jenis'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Perlakuan: ${statistik['total_perlakuan'] ?? 0}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Jumlah per Jenis:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...((statistik['jenis_count'] as Map<String, dynamic>?) ?? {})
                    .entries
                    .map((entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(entry.key)),
                              Text('${entry.value}'),
                            ],
                          ),
                        )),
                const SizedBox(height: 16),
                const Text(
                  'Rata-rata Rating:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...((statistik['jenis_avg_rating'] as Map<String, dynamic>?) ?? {})
                    .entries
                    .map((entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(entry.key)),
                              Text('${(entry.value as double).toStringAsFixed(1)}'),
                            ],
                          ),
                        )),
              ],
            ),
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

  void _showStatistikAreaDialog(BuildContext context) async {
    final provider = context.read<CatatanPerlakuanProvider>();
    final statistik = await provider.getStatistikByArea();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistik by Area'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jumlah per Area:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...((statistik['area_count'] as Map<String, dynamic>?) ?? {})
                    .entries
                    .map((entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(entry.key)),
                              Text('${entry.value}'),
                            ],
                          ),
                        )),
                const SizedBox(height: 16),
                const Text(
                  'Rata-rata Rating:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...((statistik['area_avg_rating'] as Map<String, dynamic>?) ?? {})
                    .entries
                    .map((entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(entry.key)),
                              Text('${(entry.value as double).toStringAsFixed(1)}'),
                            ],
                          ),
                        )),
              ],
            ),
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

  void _showLaporanEfektivitasDialog(BuildContext context) async {
    final provider = context.read<CatatanPerlakuanProvider>();
    final laporan = await provider.getLaporanEfektivitas();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Laporan Efektivitas'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Perlakuan: ${laporan['total_perlakuan'] ?? 0}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Dengan Rating: ${laporan['perlakuan_dengan_rating'] ?? 0}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Rata-rata Rating: ${(laporan['rata_rata_rating'] as double? ?? 0).toStringAsFixed(1)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Distribusi Rating:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...((laporan['distribusi_rating'] as Map<int, int>?) ?? {})
                    .entries
                    .map((entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Rating ${entry.key}'),
                              Text('${entry.value}'),
                            ],
                          ),
                        )),
                const SizedBox(height: 16),
                const Text(
                  'Perlakuan Terbaik (Rating 5):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...((laporan['perlakuan_terbaik'] as List?) ?? [])
                    .take(5)
                    .map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '• ${item['jenis_perlakuan']} - ${item['area_tanaman']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        )),
                const SizedBox(height: 16),
                const Text(
                  'Perlakuan Perlu Perhatian (Rating ≤2):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...((laporan['perlakuan_terburuk'] as List?) ?? [])
                    .take(5)
                    .map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '• ${item['jenis_perlakuan']} - ${item['area_tanaman']} (Rating ${item['rating']})',
                            style: const TextStyle(fontSize: 12, color: Colors.red),
                          ),
                        )),
              ],
            ),
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

  void _showDetailDialog(BuildContext context, CatatanPerlakuanModel perlakuan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(perlakuan.jenisPerlakuan),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Tanggal Perlakuan', perlakuan.formattedTanggalPerlakuan),
                _buildDetailRow('Area Tanaman', perlakuan.displayAreaTanaman),
                _buildDetailRow('Bahan Digunakan', perlakuan.displayBahanDigunakan),
                _buildDetailRow('Jumlah', perlakuan.formattedJumlahDigunakan),
                _buildDetailRow('Metode', perlakuan.displayMetode),
                _buildDetailRow('Kondisi Cuaca', perlakuan.displayKondisiCuaca),
                if (perlakuan.ratingEfektivitas != null)
                  _buildDetailRow('Rating Efektivitas', 
                      '${perlakuan.ratingEfektivitas} - ${CatatanPerlakuanModel.getRatingText(perlakuan.ratingEfektivitas)}'),
                _buildDetailRow('Catatan', perlakuan.displayCatatan),
                _buildDetailRow('Dicatat Pada', perlakuan.formattedDicatatPada),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditCatatanDialog(context, perlakuan);
            },
            child: const Text('Edit'),
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

  void _showTambahCatatanDialog(BuildContext context) {
    _showCatatanFormDialog(context, null);
  }

  void _showEditCatatanDialog(BuildContext context, CatatanPerlakuanModel perlakuan) {
    _showCatatanFormDialog(context, perlakuan);
  }

  void _showCatatanFormDialog(BuildContext context, CatatanPerlakuanModel? perlakuan) {
    final isEdit = perlakuan != null;
    final formKey = GlobalKey<FormState>();
    
    DateTime selectedDate = perlakuan?.tanggalPerlakuan ?? DateTime.now();
    String selectedJenis = perlakuan?.jenisPerlakuan ?? CatatanPerlakuanModel.getJenisPerlakuanOptions().first;
    String? selectedArea = perlakuan?.areaTanaman;
    String? selectedBahan = perlakuan?.bahanDigunakan;
    double? jumlahDigunakan = perlakuan?.jumlahDigunakan;
    String? selectedSatuan = perlakuan?.satuan;
    String? selectedMetode = perlakuan?.metode;
    String? selectedCuaca = perlakuan?.kondisiCuaca;
    int? selectedRating = perlakuan?.ratingEfektivitas;
    String? catatan = perlakuan?.catatan;

    final bahanController = TextEditingController(text: selectedBahan);
    final jumlahController = TextEditingController(text: jumlahDigunakan?.toString());
    final catatanController = TextEditingController(text: catatan);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit Catatan Perlakuan' : 'Tambah Catatan Perlakuan'),
          content: SizedBox(
            width: double.maxFinite,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tanggal Perlakuan
                    ListTile(
                      title: const Text('Tanggal Perlakuan'),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Jenis Perlakuan
                    DropdownButtonFormField<String>(
                      value: selectedJenis,
                      decoration: const InputDecoration(
                        labelText: 'Jenis Perlakuan *',
                        border: OutlineInputBorder(),
                      ),
                      items: CatatanPerlakuanModel.getJenisPerlakuanOptions()
                          .map((jenis) => DropdownMenuItem(
                                value: jenis,
                                child: Text(jenis),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedJenis = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Jenis perlakuan harus dipilih';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Area Tanaman
                    DropdownButtonFormField<String>(
                      value: selectedArea,
                      decoration: const InputDecoration(
                        labelText: 'Area Tanaman',
                        border: OutlineInputBorder(),
                      ),
                      items: [null, ...CatatanPerlakuanModel.getAreaTanamanOptions()]
                          .map((area) => DropdownMenuItem(
                                value: area,
                                child: Text(area ?? 'Pilih Area'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedArea = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Bahan Digunakan
                    TextFormField(
                      controller: bahanController,
                      decoration: const InputDecoration(
                        labelText: 'Bahan Digunakan',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        selectedBahan = value.isEmpty ? null : value;
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
                            onChanged: (value) {
                              jumlahDigunakan = double.tryParse(value);
                            },
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final number = double.tryParse(value);
                                if (number == null || number < 0) {
                                  return 'Jumlah harus berupa angka positif';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedSatuan,
                            decoration: const InputDecoration(
                              labelText: 'Satuan',
                              border: OutlineInputBorder(),
                            ),
                            items: [null, ...CatatanPerlakuanModel.getSatuanOptions()]
                                .map((satuan) => DropdownMenuItem(
                                      value: satuan,
                                      child: Text(satuan ?? 'Pilih'),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedSatuan = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Metode
                    DropdownButtonFormField<String>(
                      value: selectedMetode,
                      decoration: const InputDecoration(
                        labelText: 'Metode',
                        border: OutlineInputBorder(),
                      ),
                      items: [null, ...CatatanPerlakuanModel.getMetodeOptions()]
                          .map((metode) => DropdownMenuItem(
                                value: metode,
                                child: Text(metode ?? 'Pilih Metode'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedMetode = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Kondisi Cuaca
                    DropdownButtonFormField<String>(
                      value: selectedCuaca,
                      decoration: const InputDecoration(
                        labelText: 'Kondisi Cuaca',
                        border: OutlineInputBorder(),
                      ),
                      items: [null, ...CatatanPerlakuanModel.getKondisiCuacaOptions()]
                          .map((cuaca) => DropdownMenuItem(
                                value: cuaca,
                                child: Text(cuaca ?? 'Pilih Cuaca'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCuaca = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Rating Efektivitas
                    const Text(
                      'Rating Efektivitas',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (index) {
                        final rating = index + 1;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedRating = selectedRating == rating ? null : rating;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: selectedRating == rating
                                  ? CatatanPerlakuanModel.getRatingColor(rating)
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  CatatanPerlakuanModel.getRatingIcon(rating),
                                  color: selectedRating == rating
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                                Text(
                                  '$rating',
                                  style: TextStyle(
                                    color: selectedRating == rating
                                        ? Colors.white
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
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
                      onChanged: (value) {
                        catatan = value.isEmpty ? null : value;
                      },
                    ),
                  ],
                ),
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
                  final provider = context.read<CatatanPerlakuanProvider>();
                  bool success;
                  
                  if (isEdit) {
                    final updateData = {
                      'tanggal_perlakuan': Timestamp.fromDate(selectedDate),
                      'jenis_perlakuan': selectedJenis,
                      if (selectedArea != null) 'area_tanaman': selectedArea,
                      if (selectedBahan != null) 'bahan_digunakan': selectedBahan,
                      if (jumlahDigunakan != null) 'jumlah_digunakan': jumlahDigunakan,
                      if (selectedSatuan != null) 'satuan': selectedSatuan,
                      if (selectedMetode != null) 'metode': selectedMetode,
                      if (selectedCuaca != null) 'kondisi_cuaca': selectedCuaca,
                      if (selectedRating != null) 'rating_efektivitas': selectedRating,
                      if (catatan != null) 'catatan': catatan,
                    };
                    success = await provider.updateCatatanPerlakuan(perlakuan!.idPerlakuan!, updateData);
                  } else {
                    success = await provider.tambahCatatanPerlakuan(
                      tanggalPerlakuan: selectedDate,
                      jenisPerlakuan: selectedJenis,
                      areaTanaman: selectedArea,
                      bahanDigunakan: selectedBahan,
                      jumlahDigunakan: jumlahDigunakan,
                      satuan: selectedSatuan,
                      metode: selectedMetode,
                      kondisiCuaca: selectedCuaca,
                      ratingEfektivitas: selectedRating,
                      catatan: catatan,
                    );
                  }
                  
                  if (success) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit ? 'Catatan berhasil diupdate' : 'Catatan berhasil ditambahkan'),
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
              child: Text(isEdit ? 'Update' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, CatatanPerlakuanModel perlakuan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus catatan perlakuan "${perlakuan.jenisPerlakuan}" pada ${perlakuan.formattedTanggalPerlakuan}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = context.read<CatatanPerlakuanProvider>();
              final success = await provider.hapusCatatanPerlakuan(perlakuan.idPerlakuan!);
              
              Navigator.pop(context);
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Catatan berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(provider.error ?? 'Gagal menghapus catatan'),
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