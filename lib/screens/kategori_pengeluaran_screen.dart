import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/kategori_pengeluaran_model.dart';
import '../providers/kategori_pengeluaran_provider.dart';

class KategoriPengeluaranScreen extends StatefulWidget {
  const KategoriPengeluaranScreen({super.key});

  @override
  State<KategoriPengeluaranScreen> createState() => _KategoriPengeluaranScreenState();
}

class _KategoriPengeluaranScreenState extends State<KategoriPengeluaranScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    if (!_isInitialized) {
      final provider = Provider.of<KategoriPengeluaranProvider>(context, listen: false);
      await provider.loadKategori();
      setState(() {
        _isInitialized = true;
      });
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
        title: const Text('Kategori Pengeluaran'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshData(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'statistics':
                  _showStatistics();
                  break;
                case 'initialize':
                  _initializeDefaultCategories();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'statistics',
                child: Row(
                  children: [
                    Icon(Icons.analytics),
                    SizedBox(width: 8),
                    Text('Statistik'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'initialize',
                child: Row(
                  children: [
                    Icon(Icons.settings_backup_restore),
                    SizedBox(width: 8),
                    Text('Inisialisasi Default'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<KategoriPengeluaranProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && !_isInitialized) {
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
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearError();
                      _refreshData();
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildSearchAndFilter(provider),
              _buildSummaryCards(provider),
              Expanded(
                child: _buildKategoriList(provider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddKategoriDialog(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilter(KategoriPengeluaranProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari kategori...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        provider.clearSearch();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) => provider.searchKategori(value),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Hanya Aktif'),
                  value: provider.showActiveOnly,
                  onChanged: (value) => provider.setShowActiveOnly(value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(KategoriPengeluaranProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Total',
              provider.totalKategori.toString(),
              Icons.category,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              'Aktif',
              provider.activeKategoriCount.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              'Tidak Aktif',
              provider.inactiveKategoriCount.toString(),
              Icons.cancel,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
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
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKategoriList(KategoriPengeluaranProvider provider) {
    if (provider.kategoriList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              provider.searchQuery.isNotEmpty
                  ? 'Tidak ada kategori yang ditemukan'
                  : 'Belum ada kategori',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (provider.searchQuery.isEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _showAddKategoriDialog(),
                child: const Text('Tambah Kategori Pertama'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.kategoriList.length,
        itemBuilder: (context, index) {
          final kategori = provider.kategoriList[index];
          final usageCount = provider.getUsageCount(kategori.id!);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: kategori.categoryColor.withOpacity(0.2),
                child: Icon(
                  kategori.categoryIcon,
                  color: kategori.categoryColor,
                ),
              ),
              title: Text(
                kategori.displayTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(kategori.displaySubtitle),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        kategori.statusIcon,
                        size: 16,
                        color: kategori.statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        kategori.statusText,
                        style: TextStyle(
                          color: kategori.statusColor,
                          fontSize: 12,
                        ),
                      ),
                      if (usageCount > 0) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.receipt,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$usageCount kali digunakan',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value, kategori),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility),
                        SizedBox(width: 8),
                        Text('Lihat Detail'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  if (kategori.aktif)
                    const PopupMenuItem(
                      value: 'deactivate',
                      child: Row(
                        children: [
                          Icon(Icons.block),
                          SizedBox(width: 8),
                          Text('Nonaktifkan'),
                        ],
                      ),
                    )
                  else
                    const PopupMenuItem(
                      value: 'activate',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle),
                          SizedBox(width: 8),
                          Text('Aktifkan'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Hapus', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
              onTap: () => _showKategoriDetail(kategori),
            ),
          );
        },
      ),
    );
  }

  void _handleMenuAction(String action, KategoriPengeluaranModel kategori) {
    switch (action) {
      case 'view':
        _showKategoriDetail(kategori);
        break;
      case 'edit':
        _showEditKategoriDialog(kategori);
        break;
      case 'activate':
        _activateKategori(kategori.id!);
        break;
      case 'deactivate':
        _deactivateKategori(kategori.id!);
        break;
      case 'delete':
        _showDeleteConfirmation(kategori);
        break;
    }
  }

  Future<void> _refreshData() async {
    final provider = Provider.of<KategoriPengeluaranProvider>(context, listen: false);
    await provider.refresh();
  }

  void _showAddKategoriDialog() {
    _showKategoriDialog();
  }

  void _showEditKategoriDialog(KategoriPengeluaranModel kategori) {
    _showKategoriDialog(kategori: kategori);
  }

  void _showKategoriDialog({KategoriPengeluaranModel? kategori}) {
    final isEdit = kategori != null;
    final namaController = TextEditingController(text: kategori?.namaKategori ?? '');
    final keteranganController = TextEditingController(text: kategori?.keterangan ?? '');
    bool aktif = kategori?.aktif ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit Kategori' : 'Tambah Kategori'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kategori *',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: keteranganController,
                  decoration: const InputDecoration(
                    labelText: 'Keterangan',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Aktif'),
                  value: aktif,
                  onChanged: (value) {
                    setState(() {
                      aktif = value ?? true;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => _saveKategori(
                context,
                namaController.text,
                keteranganController.text,
                aktif,
                kategori?.id,
              ),
              child: Text(isEdit ? 'Update' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveKategori(
    BuildContext context,
    String nama,
    String keterangan,
    bool aktif,
    String? id,
  ) async {
    if (nama.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama kategori harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = Provider.of<KategoriPengeluaranProvider>(context, listen: false);
    final kategori = KategoriPengeluaranModel(
      id: id ?? '', // Use empty string for new categories, will be set by Firestore
      namaKategori: nama.trim(),
      keterangan: keterangan.trim().isEmpty ? null : keterangan.trim(),
      aktif: aktif,
    );

    bool success;
    if (id != null) {
      success = await provider.updateKategori(id, kategori);
    } else {
      success = await provider.addKategori(kategori);
    }

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(id != null ? 'Kategori berhasil diupdate' : 'Kategori berhasil ditambahkan'),
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

  void _showKategoriDetail(KategoriPengeluaranModel kategori) {
    final provider = Provider.of<KategoriPengeluaranProvider>(context, listen: false);
    final usageCount = provider.getUsageCount(kategori.id!);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(kategori.displayTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('ID', kategori.id ?? '-'),
            _buildDetailRow('Nama', kategori.namaKategori),
            _buildDetailRow('Keterangan', kategori.keterangan ?? 'Tidak ada keterangan'),
            _buildDetailRow('Status', kategori.statusText),
            _buildDetailRow('Digunakan', '$usageCount kali'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditKategoriDialog(kategori);
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
            width: 80,
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

  Future<void> _activateKategori(String id) async {
    final provider = Provider.of<KategoriPengeluaranProvider>(context, listen: false);
    final success = await provider.activateKategori(id);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kategori berhasil diaktifkan'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Gagal mengaktifkan kategori'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deactivateKategori(String id) async {
    final provider = Provider.of<KategoriPengeluaranProvider>(context, listen: false);
    final success = await provider.deactivateKategori(id);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kategori berhasil dinonaktifkan'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Gagal menonaktifkan kategori'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(KategoriPengeluaranModel kategori) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus kategori "${kategori.namaKategori}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteKategori(kategori.id!);
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

  Future<void> _deleteKategori(String id) async {
    final provider = Provider.of<KategoriPengeluaranProvider>(context, listen: false);
    final success = await provider.deleteKategori(id);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kategori berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Gagal menghapus kategori'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showStatistics() {
    final provider = Provider.of<KategoriPengeluaranProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistik Kategori'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Total Kategori', provider.totalKategori.toString()),
            _buildStatRow('Kategori Aktif', provider.activeKategoriCount.toString()),
            _buildStatRow('Kategori Tidak Aktif', provider.inactiveKategoriCount.toString()),
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeDefaultCategories() async {
    final provider = Provider.of<KategoriPengeluaranProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inisialisasi Kategori Default'),
        content: const Text('Apakah Anda ingin menambahkan kategori default?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.initializeDefaultKategori();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kategori default berhasil ditambahkan'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Ya'),
          ),
        ],
      ),
    );
  }
}