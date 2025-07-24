import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dropdown_option_model.dart';
import '../providers/dropdown_provider.dart';

class DropdownManagementScreen extends StatefulWidget {
  const DropdownManagementScreen({Key? key}) : super(key: key);

  @override
  State<DropdownManagementScreen> createState() => _DropdownManagementScreenState();
}

class _DropdownManagementScreenState extends State<DropdownManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: DropdownCategories.allCategories.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DropdownProvider>().refreshAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Dropdown Options'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: DropdownCategories.allCategories.map((category) {
            return Tab(
              text: DropdownCategories.getCategoryDisplayName(category),
            );
          }).toList(),
        ),
        actions: [
          IconButton(
            icon: Icon(_showInactive ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _showInactive = !_showInactive;
              });
              context.read<DropdownProvider>().loadAllCategories(activeOnly: !_showInactive);
            },
            tooltip: _showInactive ? 'Sembunyikan Tidak Aktif' : 'Tampilkan Tidak Aktif',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DropdownProvider>().refreshAll();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: DropdownCategories.allCategories.map((category) {
                return _buildCategoryTab(category);
              }).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptionDialog(),
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border(bottom: BorderSide(color: Colors.green[200]!)),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari opsi...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
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
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildCategoryTab(String category) {
    return Consumer<DropdownProvider>(builder: (context, provider, child) {
      if (provider.isLoading(category)) {
        return const Center(child: CircularProgressIndicator());
      }

      final error = provider.getError(category);
      if (error != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error: $error',
                style: TextStyle(color: Colors.red[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => provider.loadOptions(category, forceRefresh: true),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        );
      }

      final options = provider.getOptions(category);
      final filteredOptions = _searchQuery.isEmpty
          ? options
          : options.where((option) {
              return option.value.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                     (option.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
            }).toList();

      if (filteredOptions.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.list_alt, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty ? 'Belum ada opsi' : 'Tidak ada hasil pencarian',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isEmpty
                    ? 'Tap tombol + untuk menambah opsi'
                    : 'Coba kata kunci lain',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          _buildStatsCard(category, provider),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.loadOptions(category, forceRefresh: true),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredOptions.length,
                itemBuilder: (context, index) {
                  final option = filteredOptions[index];
                  return _buildOptionCard(option, category);
                },
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStatsCard(String category, DropdownProvider provider) {
    final stats = provider.getStats(category);
    if (stats.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', stats['total'] ?? 0, Colors.blue),
          _buildStatItem('Aktif', stats['active'] ?? 0, Colors.green),
          _buildStatItem('Tidak Aktif', stats['inactive'] ?? 0, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard(DropdownOptionModel option, String category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: option.isActive ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: option.isActive ? Colors.green[100] : Colors.orange[100],
          child: Icon(
            option.isActive ? Icons.check_circle : Icons.pause_circle,
            color: option.isActive ? Colors.green[700] : Colors.orange[700],
          ),
        ),
        title: Text(
          option.value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: option.isActive ? Colors.black : Colors.grey[600],
          ),
        ),
        subtitle: option.description != null
            ? Text(
                option.description!,
                style: TextStyle(
                  color: option.isActive ? Colors.grey[600] : Colors.grey[500],
                ),
              )
            : null,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditOptionDialog(option);
                break;
              case 'toggle':
                _toggleOptionStatus(option.id!);
                break;
              case 'delete':
                _showDeleteConfirmDialog(option);
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
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    option.isActive ? Icons.pause : Icons.play_arrow,
                    size: 20,
                    color: option.isActive ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    option.isActive ? 'Nonaktifkan' : 'Aktifkan',
                    style: TextStyle(
                      color: option.isActive ? Colors.orange : Colors.green,
                    ),
                  ),
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
      ),
    );
  }

  void _showAddOptionDialog() {
    final currentCategory = DropdownCategories.allCategories[_tabController.index];
    _showOptionFormDialog(null, currentCategory);
  }

  void _showEditOptionDialog(DropdownOptionModel option) {
    _showOptionFormDialog(option, option.category);
  }

  void _showOptionFormDialog(DropdownOptionModel? option, String category) {
    final isEdit = option != null;
    final formKey = GlobalKey<FormState>();
    final valueController = TextEditingController(text: option?.value ?? '');
    final descriptionController = TextEditingController(text: option?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Opsi' : 'Tambah Opsi Baru'),
        content: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Kategori: ${DropdownCategories.getCategoryDisplayName(category)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: valueController,
                  decoration: const InputDecoration(
                    labelText: 'Nilai *',
                    border: OutlineInputBorder(),
                    hintText: 'Masukkan nilai opsi',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nilai tidak boleh kosong';
                    }
                    if (value.trim().length < 2) {
                      return 'Nilai minimal 2 karakter';
                    }
                    if (value.trim().length > 100) {
                      return 'Nilai maksimal 100 karakter';
                    }
                    
                    // Check if value already exists
                    final provider = context.read<DropdownProvider>();
                    if (provider.isValueExists(category, value.trim(), excludeId: option?.id)) {
                      return 'Nilai sudah ada';
                    }
                    
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (Opsional)',
                    border: OutlineInputBorder(),
                    hintText: 'Masukkan deskripsi opsi',
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value != null && value.length > 255) {
                      return 'Deskripsi maksimal 255 karakter';
                    }
                    return null;
                  },
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
                final provider = context.read<DropdownProvider>();
                bool success;
                
                if (isEdit) {
                  success = await provider.updateOption(
                    option.id!,
                    valueController.text.trim(),
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                  );
                } else {
                  success = await provider.addOption(
                    category,
                    valueController.text.trim(),
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                  );
                }
                
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEdit ? 'Opsi berhasil diperbarui' : 'Opsi berhasil ditambahkan'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.getError(category) ?? 'Terjadi kesalahan'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(isEdit ? 'Perbarui' : 'Tambah'),
          ),
        ],
      ),
    );
  }

  void _toggleOptionStatus(int id) async {
    final provider = context.read<DropdownProvider>();
    final success = await provider.toggleOptionStatus(id);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status opsi berhasil diubah'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengubah status opsi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmDialog(DropdownOptionModel option) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus opsi "${option.value}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<DropdownProvider>();
              final success = await provider.deleteOption(option.id!);
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opsi berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gagal menghapus opsi'),
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