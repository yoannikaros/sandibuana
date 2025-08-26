import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
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
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
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
                          ),
                          // Tampilkan stok pupuk jika ada yang dipilih
                          if (selectedPupukId != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Builder(
                                builder: (context) {
                                  final selectedPupuk = pupukProvider.jenisPupukAktif
                                      .firstWhere((pupuk) => pupuk.id == selectedPupukId);
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blue.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.inventory_2,
                                          color: Colors.blue.shade600,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Stok tersedia: ${selectedPupuk.stok.toStringAsFixed(1)} kg',
                                          style: TextStyle(
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
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
                  final navigator = Navigator.of(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  
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
                    success = await pupukProvider.updatePenggunaanPupuk(penggunaan.id, newPenggunaan);
                  } else {
                    success = await pupukProvider.tambahPenggunaanPupuk(newPenggunaan);
                  }

                  if (success) {
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(isEdit ? 'Penggunaan pupuk berhasil diupdate' : 'Penggunaan pupuk berhasil ditambahkan'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    scaffoldMessenger.showSnackBar(
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
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              
              final success = await pupukProvider.hapusPenggunaanPupuk(penggunaan.id);
              
              navigator.pop();
              
              if (success) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Penggunaan pupuk berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                scaffoldMessenger.showSnackBar(
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

  Future<void> _generatePDFReport() async {
    try {
      // Extract provider before async operations
      final pupukProvider = Provider.of<PupukProvider>(context, listen: false);
      final penggunaanList = pupukProvider.penggunaanPupukList;
      final jenisPupukList = pupukProvider.jenisPupukList;
      
      // For modern Android versions (API 30+), we use scoped storage
      // No need to request storage permission for app-specific directories
      bool hasPermission = true;
      
      if (Platform.isAndroid) {
        // Check Android version and handle permissions accordingly
        try {
          // For Android 13+ (API 33+), we use MANAGE_EXTERNAL_STORAGE or scoped storage
          if (await Permission.manageExternalStorage.isGranted) {
            hasPermission = true;
          } else {
            // Try to request MANAGE_EXTERNAL_STORAGE permission
            var status = await Permission.manageExternalStorage.request();
            if (status.isGranted) {
              hasPermission = true;
            } else if (status.isPermanentlyDenied) {
              // Show dialog to open app settings
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Izin Diperlukan'),
                    content: const Text('Aplikasi memerlukan izin untuk mengelola file eksternal agar dapat menyimpan PDF ke folder Download. Silakan aktifkan izin "Kelola semua file" di pengaturan aplikasi.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          openAppSettings();
                        },
                        child: const Text('Buka Pengaturan'),
                      ),
                    ],
                  ),
                );
              }
              return;
            } else {
              // Permission denied, but we can still save to app directory
              hasPermission = false;
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('File akan disimpan di direktori aplikasi karena izin tidak diberikan'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            }
          }
        } catch (e) {
          // Fallback: use app directory without external storage permission
          hasPermission = false;
        }
      }

      if (penggunaanList.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak ada data untuk dibuat laporan'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Membuat laporan PDF...'),
              ],
            ),
          ),
        );
      }

      // Create PDF document
      final pdf = pw.Document();
      
      // Calculate statistics
      final totalPenggunaan = penggunaanList.length;
      final totalJumlah = penggunaanList.fold<double>(0, (sum, item) => sum + item.jumlahDigunakan);
      
      // Group by pupuk
      final Map<String, List<PenggunaanPupukModel>> groupedByPupuk = {};
      for (final penggunaan in penggunaanList) {
        if (!groupedByPupuk.containsKey(penggunaan.idPupuk)) {
          groupedByPupuk[penggunaan.idPupuk] = [];
        }
        groupedByPupuk[penggunaan.idPupuk]!.add(penggunaan);
      }

      // Group by date
      final Map<String, List<PenggunaanPupukModel>> groupedByDate = {};
      for (final penggunaan in penggunaanList) {
        final dateKey = DateFormat('yyyy-MM-dd').format(penggunaan.tanggalPakai);
        if (!groupedByDate.containsKey(dateKey)) {
          groupedByDate[dateKey] = [];
        }
        groupedByDate[dateKey]!.add(penggunaan);
      }

      // Add pages to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'LAPORAN PENGGUNAAN PUPUK HARIAN',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Sandi Buana Farm',
                          style: pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Tanggal Cetak:',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Filter Information
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'INFORMASI FILTER',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            'Periode: ${_selectedStartDate != null && _selectedEndDate != null ? '${DateFormat('dd/MM/yyyy').format(_selectedStartDate!)} - ${DateFormat('dd/MM/yyyy').format(_selectedEndDate!)}' : 'Semua Data'}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            'Jenis Pupuk: ${_selectedPupukId != null ? jenisPupukList.firstWhere((p) => p.id == _selectedPupukId, orElse: () => JenisPupukModel(id: '', namaPupuk: 'Tidak ditemukan', kodePupuk: '', tipe: 'makro', stok: 0, aktif: false)).namaPupuk : 'Semua Jenis'}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Summary Statistics
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  border: pw.Border.all(color: PdfColors.blue200),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'RINGKASAN STATISTIK',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Total Penggunaan',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.grey600,
                                ),
                              ),
                              pw.Text(
                                '$totalPenggunaan kali',
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.blue800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Total Jumlah',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.grey600,
                                ),
                              ),
                              pw.Text(
                                '${totalJumlah.toStringAsFixed(2)} kg',
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.blue800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Jenis Pupuk Digunakan',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.grey600,
                                ),
                              ),
                              pw.Text(
                                '${groupedByPupuk.length} jenis',
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.blue800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Hari Aktif',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.grey600,
                                ),
                              ),
                              pw.Text(
                                '${groupedByDate.length} hari',
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.blue800,
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
              
              pw.SizedBox(height: 20),
              
              // Summary by Pupuk Type
              pw.Text(
                'RINGKASAN BERDASARKAN JENIS PUPUK',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                  4: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Nama Pupuk',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Frekuensi',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Total (kg)',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Rata-rata',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Stok Sisa',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  ...groupedByPupuk.entries.map((entry) {
                    final pupuk = jenisPupukList.firstWhere(
                      (p) => p.id == entry.key,
                      orElse: () => JenisPupukModel(
                        id: entry.key,
                        namaPupuk: 'Pupuk tidak ditemukan',
                        kodePupuk: '',
                        tipe: 'makro',
                        stok: 0,
                        aktif: false,
                      ),
                    );
                    final penggunaanPupuk = entry.value;
                    final totalPupuk = penggunaanPupuk.fold<double>(0, (sum, item) => sum + item.jumlahDigunakan);
                    final rataRata = totalPupuk / penggunaanPupuk.length;
                    
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${pupuk.namaPupuk}\n(${pupuk.kodePupuk ?? '-'})',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${penggunaanPupuk.length}x',
                            style: const pw.TextStyle(fontSize: 9),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            totalPupuk.toStringAsFixed(2),
                            style: const pw.TextStyle(fontSize: 9),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            rataRata.toStringAsFixed(2),
                            style: const pw.TextStyle(fontSize: 9),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            pupuk.stok.toStringAsFixed(1),
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: pupuk.stok <= 0 ? PdfColors.red : pupuk.stok <= 10 ? PdfColors.orange : PdfColors.green,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              // Detail Data
              pw.Text(
                'DETAIL DATA PENGGUNAAN PUPUK',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                  4: const pw.FlexColumnWidth(3),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Tanggal',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Jenis Pupuk',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Jumlah',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Satuan',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Catatan',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                  ...penggunaanList.map((penggunaan) {
                    final pupuk = jenisPupukList.firstWhere(
                      (p) => p.id == penggunaan.idPupuk,
                      orElse: () => JenisPupukModel(
                        id: penggunaan.idPupuk,
                        namaPupuk: 'Pupuk tidak ditemukan',
                        kodePupuk: '',
                        tipe: 'makro',
                        stok: 0,
                        aktif: false,
                      ),
                    );
                    
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            DateFormat('dd/MM/yyyy').format(penggunaan.tanggalPakai),
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            '${pupuk.namaPupuk}\n(${pupuk.kodePupuk ?? '-'})',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            penggunaan.jumlahDigunakan.toStringAsFixed(2),
                            style: const pw.TextStyle(fontSize: 8),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            penggunaan.satuan ?? 'kg',
                            style: const pw.TextStyle(fontSize: 8),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            penggunaan.catatan ?? '-',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ];
          },
        ),
      );

      // Save PDF file
      Directory directory;
      String fileName = 'Laporan_Penggunaan_Pupuk_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      
      if (Platform.isAndroid) {
        if (hasPermission) {
          try {
            // Try to save to Downloads folder
            directory = Directory('/storage/emulated/0/Download');
            if (!await directory.exists()) {
              // Create Downloads directory if it doesn't exist
              try {
                await directory.create(recursive: true);
              } catch (e) {
                // If can't create, fallback to external storage
                directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
              }
            }
          } catch (e) {
            // Fallback to external storage directory
            try {
              directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
            } catch (e2) {
              // Final fallback to app documents directory
              directory = await getApplicationDocumentsDirectory();
            }
          }
        } else {
          // Use app-specific directory (no permission needed)
          // This works on all Android versions without permission
          directory = await getApplicationDocumentsDirectory();
        }
      } else {
        // For iOS and other platforms
        directory = await getApplicationDocumentsDirectory();
      }
      
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();

        // Show success message and open file
        String locationMessage;
        if (Platform.isAndroid) {
          if (hasPermission && directory.path.contains('Download')) {
            locationMessage = 'Laporan PDF berhasil disimpan di folder Download: $fileName';
          } else {
            locationMessage = 'Laporan PDF berhasil disimpan: $fileName\nLokasi: ${directory.path}';
          }
        } else {
          locationMessage = 'Laporan PDF berhasil dibuat: $fileName';
        }
            
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locationMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Buka',
              textColor: Colors.white,
              onPressed: () {
                OpenFile.open(file.path);
              },
            ),
          ),
        );
      }

      // Automatically open the file
      await OpenFile.open(file.path);

    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat laporan PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStokColor(double stok) {
    if (stok <= 0) {
      return Colors.red[600]!;
    } else if (stok <= 10) {
      return Colors.orange[600]!;
    } else {
      return Colors.green[600]!;
    }
  }

  IconData _getStokIcon(double stok) {
    if (stok <= 0) {
      return Icons.warning;
    } else if (stok <= 10) {
      return Icons.info;
    } else {
      return Icons.check;
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
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Buat Laporan PDF',
            onPressed: _generatePDFReport,
          ),
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
                        }),
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
                        const SizedBox(width: 8),
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _generatePDFReport,
                            icon: const Icon(Icons.picture_as_pdf, size: 18),
                            label: const Text('Laporan PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              foregroundColor: Colors.white,
                            ),
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
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              pupuk?.namaPupuk ?? 'Pupuk tidak ditemukan',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          if (pupuk != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _getStokColor(pupuk.stok),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    _getStokIcon(pupuk.stok),
                                                    size: 14,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Stok: ${pupuk.stok.toStringAsFixed(1)} kg',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
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