import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../providers/transaksi_provider.dart';
import '../providers/pelanggan_provider.dart';
import '../models/transaksi_model.dart';
import '../models/pelanggan_model.dart';

class LaporanTransaksiScreen extends StatefulWidget {
  const LaporanTransaksiScreen({super.key});

  @override
  State<LaporanTransaksiScreen> createState() => _LaporanTransaksiScreenState();
}

class _LaporanTransaksiScreenState extends State<LaporanTransaksiScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedJenisPelanggan;
  String? _selectedPelangganId;
  List<TransaksiModel> _filteredTransaksi = [];
  List<TransaksiModel> _allTransaksi = [];
  Map<String, PelangganModel> _pelangganMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    // Defer loading until after the build is complete to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load pelanggan data first
      final pelangganProvider = Provider.of<PelangganProvider>(context, listen: false);
      await pelangganProvider.loadPelanggan();
      
      // Create pelanggan map for quick lookup
      _pelangganMap = {};
      for (var pelanggan in pelangganProvider.pelangganList) {
        _pelangganMap[pelanggan.id] = pelanggan;
      }
      
      // Load transaksi data
      final transaksiProvider = Provider.of<TransaksiProvider>(context, listen: false);
      await transaksiProvider.loadAllTransaksi();
      
      setState(() {
        _allTransaksi = transaksiProvider.transaksiList;
        _filteredTransaksi = _allTransaksi;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memuat data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterTransaksi() {
    setState(() {
      _filteredTransaksi = _allTransaksi.where((transaksi) {
        // Filter by search query
        bool matchesSearch = _searchController.text.isEmpty ||
            transaksi.namaPelanggan.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            transaksi.id.toLowerCase().contains(_searchController.text.toLowerCase());

        // Filter by date range
        bool matchesDateRange = true;
        if (_startDate != null && _endDate != null) {
          matchesDateRange = transaksi.tanggalBeli.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
              transaksi.tanggalBeli.isBefore(_endDate!.add(const Duration(days: 1)));
        }
        
        // Filter by jenis pelanggan
        bool matchesJenisPelanggan = true;
        if (_selectedJenisPelanggan != null && _selectedJenisPelanggan!.isNotEmpty) {
          final pelanggan = _pelangganMap[transaksi.idPelanggan];
          matchesJenisPelanggan = pelanggan?.jenisPelanggan == _selectedJenisPelanggan;
        }
        
        // Filter by specific pelanggan
        bool matchesPelanggan = true;
        if (_selectedPelangganId != null && _selectedPelangganId!.isNotEmpty) {
          matchesPelanggan = transaksi.idPelanggan == _selectedPelangganId;
        }

        return matchesSearch && matchesDateRange && matchesJenisPelanggan && matchesPelanggan;
      }).toList();
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _filterTransaksi();
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _startDate = null;
      _endDate = null;
      _selectedJenisPelanggan = null;
      _selectedPelangganId = null;
      _filteredTransaksi = _allTransaksi;
    });
  }

  Future<void> _generateSingleTransactionPDF(TransaksiModel transaksi) async {
    try {
      final pdf = pw.Document();
      final pelanggan = _pelangganMap[transaksi.idPelanggan];
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'STRUK TRANSAKSI',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Sandibuana Hidroponik',
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'ID Transaksi: ${transaksi.id}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Customer Info
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'INFORMASI PELANGGAN',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Nama:', style: pw.TextStyle(fontSize: 10)),
                            pw.Text(transaksi.namaPelanggan, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text('Tanggal:', style: pw.TextStyle(fontSize: 10)),
                            pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(transaksi.tanggalBeli), 
                              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    if (pelanggan?.jenisPelanggan != null) ...[
                      pw.SizedBox(height: 4),
                      pw.Text('Jenis Pelanggan: ${pelanggan!.jenisPelanggan}', 
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                    ],
                    if (pelanggan?.namaTempatUsaha != null) ...[
                      pw.SizedBox(height: 2),
                      pw.Text('Usaha: ${pelanggan!.namaTempatUsaha}', 
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic)),
                    ],
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Items Table
              pw.Text(
                'DETAIL PEMBELIAN',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(2),
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Jenis Sayur', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Jumlah', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Harga', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                    ],
                  ),
                  // Items
                  ...transaksi.items.asMap().entries.map((entry) {
                    int index = entry.key;
                    var item = entry.value;
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${index + 1}', style: pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(item.jenisSayur, style: pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${item.jumlah} ${item.satuan}', style: pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Rp ${NumberFormat('#,###').format(item.harga)}', style: pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Rp ${NumberFormat('#,###').format(item.totalHarga)}', 
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              // Additional Info
              if (transaksi.informasiLain != null && transaksi.informasiLain!.isNotEmpty) ...[
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    border: pw.Border.all(color: PdfColors.blue200),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'INFORMASI TAMBAHAN:',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        transaksi.informasiLain!,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
              ],
              
              // Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  border: pw.Border.all(color: PdfColors.green200),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Item:', style: pw.TextStyle(fontSize: 12)),
                        pw.Text('${transaksi.items.fold(0.0, (sum, item) => sum + item.jumlah).toStringAsFixed(transaksi.items.fold(0.0, (sum, item) => sum + item.jumlah) == transaksi.items.fold(0.0, (sum, item) => sum + item.jumlah).truncateToDouble() ? 0 : 1)} item', 
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Divider(color: PdfColors.green300),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('TOTAL PEMBAYARAN:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Rp ${NumberFormat('#,###').format(transaksi.totalHarga)}', 
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 30),
              
              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Terima kasih atas kepercayaan Anda',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Sandibuana Hidroponik',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Dicetak pada: ${DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(DateTime.now())}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      );
      
      // Save and open PDF
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/transaksi_${transaksi.id}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF berhasil dibuat: ${file.path}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Buka',
              textColor: Colors.white,
              onPressed: () => OpenFile.open(file.path),
            ),
          ),
        );
        
        // Auto open PDF
        await OpenFile.open(file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error membuat PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generatePDFReportByCustomer() async {
    if (_selectedPelangganId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih pelanggan terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    try {
      // Filter transaksi berdasarkan pelanggan yang dipilih
      final pelangganTransaksi = _allTransaksi.where((transaksi) => 
          transaksi.idPelanggan == _selectedPelangganId).toList();
      
      if (pelangganTransaksi.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada transaksi untuk pelanggan yang dipilih'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      final selectedPelanggan = _pelangganMap[_selectedPelangganId!];
      final pdf = pw.Document();
      
      // Calculate summary data for selected customer
      double totalRevenue = pelangganTransaksi.fold(0, (sum, transaksi) => sum + transaksi.totalHarga);
      int totalTransactions = pelangganTransaksi.length;
      double totalItems = pelangganTransaksi.fold(0.0, (sum, transaksi) => 
          sum + transaksi.items.fold(0.0, (itemSum, item) => itemSum + item.jumlah));
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'LAPORAN TRANSAKSI PELANGGAN',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Sandibuana Hidroponik',
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Tanggal: ${DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now())}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Customer Info Section
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'INFORMASI PELANGGAN',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Nama:', style: pw.TextStyle(fontSize: 12)),
                            pw.Text(selectedPelanggan?.namaPelanggan ?? 'N/A', 
                              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 4),
                            pw.Text('Jenis Pelanggan:', style: pw.TextStyle(fontSize: 12)),
                            pw.Text(selectedPelanggan?.jenisPelanggan ?? 'N/A', 
                              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text('Telepon:', style: pw.TextStyle(fontSize: 12)),
                            pw.Text(selectedPelanggan?.telepon ?? 'N/A', 
                              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 4),
                            if (selectedPelanggan?.namaTempatUsaha != null) ...[
                              pw.Text('Usaha:', style: pw.TextStyle(fontSize: 12)),
                              pw.Text(selectedPelanggan!.namaTempatUsaha!, 
                                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Summary Section
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'RINGKASAN TRANSAKSI',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Total Transaksi:', style: pw.TextStyle(fontSize: 12)),
                            pw.Text('$totalTransactions', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Total Item:', style: pw.TextStyle(fontSize: 12)),
                            pw.Text('${totalItems.toStringAsFixed(totalItems == totalItems.truncateToDouble() ? 0 : 1)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text('Total Pendapatan:', style: pw.TextStyle(fontSize: 12)),
                            pw.Text('Rp ${NumberFormat('#,###').format(totalRevenue)}', 
                              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Transaction Table
              pw.Text(
                'DETAIL TRANSAKSI',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              
              // Transaction Details with Items
               ...pelangganTransaksi.asMap().entries.map((entry) {
                 int index = entry.key;
                 TransaksiModel transaksi = entry.value;
                 
                 return pw.Column(
                   crossAxisAlignment: pw.CrossAxisAlignment.start,
                   children: [
                     // Transaction Header
                     pw.Container(
                       padding: const pw.EdgeInsets.all(12),
                       margin: const pw.EdgeInsets.only(bottom: 8),
                       decoration: pw.BoxDecoration(
                         color: PdfColors.grey100,
                         borderRadius: pw.BorderRadius.circular(8),
                       ),
                       child: pw.Row(
                         mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                         children: [
                           pw.Column(
                             crossAxisAlignment: pw.CrossAxisAlignment.start,
                             children: [
                               pw.Text(
                                 'Transaksi #${index + 1}',
                                 style: pw.TextStyle(
                                   fontSize: 14,
                                   fontWeight: pw.FontWeight.bold,
                                 ),
                               ),
                               pw.Text(
                                 'ID: ${transaksi.id}',
                                 style: pw.TextStyle(
                                   fontSize: 10,
                                   color: PdfColors.grey600,
                                 ),
                               ),
                             ],
                           ),
                           pw.Column(
                             crossAxisAlignment: pw.CrossAxisAlignment.end,
                             children: [
                               pw.Text(
                                 DateFormat('dd/MM/yyyy HH:mm').format(transaksi.tanggalBeli),
                                 style: pw.TextStyle(
                                   fontSize: 12,
                                   fontWeight: pw.FontWeight.bold,
                                 ),
                               ),
                               pw.Text(
                                 'Rp ${NumberFormat('#,###').format(transaksi.totalHarga)}',
                                 style: pw.TextStyle(
                                   fontSize: 14,
                                   fontWeight: pw.FontWeight.bold,
                                   color: PdfColors.green,
                                 ),
                               ),
                             ],
                           ),
                         ],
                       ),
                     ),
                     
                     // Items Table for this transaction
                     pw.Table(
                       border: pw.TableBorder.all(color: PdfColors.grey300),
                       columnWidths: {
                         0: const pw.FlexColumnWidth(1),
                         1: const pw.FlexColumnWidth(3),
                         2: const pw.FlexColumnWidth(1.5),
                         3: const pw.FlexColumnWidth(1.5),
                         4: const pw.FlexColumnWidth(2),
                       },
                       children: [
                         // Header
                         pw.TableRow(
                           decoration: pw.BoxDecoration(color: PdfColors.grey200),
                           children: [
                             pw.Padding(
                               padding: const pw.EdgeInsets.all(6),
                               child: pw.Text('No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                             ),
                             pw.Padding(
                               padding: const pw.EdgeInsets.all(6),
                               child: pw.Text('Jenis Sayur', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                             ),
                             pw.Padding(
                               padding: const pw.EdgeInsets.all(6),
                               child: pw.Text('Jumlah', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                             ),
                             pw.Padding(
                               padding: const pw.EdgeInsets.all(6),
                               child: pw.Text('Harga', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                             ),
                             pw.Padding(
                               padding: const pw.EdgeInsets.all(6),
                               child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                             ),
                           ],
                         ),
                         // Items
                         ...transaksi.items.asMap().entries.map((itemEntry) {
                           int itemIndex = itemEntry.key;
                           var item = itemEntry.value;
                           return pw.TableRow(
                             children: [
                               pw.Padding(
                                 padding: const pw.EdgeInsets.all(6),
                                 child: pw.Text('${itemIndex + 1}', style: pw.TextStyle(fontSize: 8)),
                               ),
                               pw.Padding(
                                 padding: const pw.EdgeInsets.all(6),
                                 child: pw.Text(item.jenisSayur, style: pw.TextStyle(fontSize: 8)),
                               ),
                               pw.Padding(
                                 padding: const pw.EdgeInsets.all(6),
                                 child: pw.Text('${item.jumlah}', style: pw.TextStyle(fontSize: 8)),
                               ),
                               pw.Padding(
                                 padding: const pw.EdgeInsets.all(6),
                                 child: pw.Text('Rp ${NumberFormat('#,###').format(item.harga)}', style: pw.TextStyle(fontSize: 8)),
                               ),
                               pw.Padding(
                                 padding: const pw.EdgeInsets.all(6),
                                 child: pw.Text('Rp ${NumberFormat('#,###').format(item.totalHarga)}', 
                                   style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                               ),
                             ],
                           );
                         }).toList(),
                       ],
                     ),
                     
                     pw.SizedBox(height: 16),
                   ],
                 );
               }).toList(),
              
              pw.SizedBox(height: 20),
              
              // Footer
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Terima kasih atas kepercayaan Anda',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Sandibuana Hidroponik',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Dicetak pada: ${DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(DateTime.now())}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      );
      
      // Save and open PDF
      final output = await getTemporaryDirectory();
      final customerName = selectedPelanggan?.namaPelanggan.replaceAll(' ', '_') ?? 'unknown';
      final file = File('${output.path}/laporan_transaksi_${customerName}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF berhasil dibuat: ${file.path}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Buka',
              textColor: Colors.white,
              onPressed: () => OpenFile.open(file.path),
            ),
          ),
        );
        
        // Auto open PDF
        await OpenFile.open(file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error membuat PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generatePDFReport() async {
    try {
      final pdf = pw.Document();
      
      // Calculate summary data
      double totalRevenue = _filteredTransaksi.fold(0, (sum, transaksi) => sum + transaksi.totalHarga);
      int totalTransactions = _filteredTransaksi.length;
      double totalItems = _filteredTransaksi.fold(0.0, (sum, transaksi) => 
          sum + transaksi.items.fold(0.0, (itemSum, item) => itemSum + item.jumlah));
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'LAPORAN TRANSAKSI',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Sandibuana Hidroponik',
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Tanggal: ${DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now())}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.white,
                      ),
                    ),
                    if (_startDate != null && _endDate != null)
                      pw.Text(
                      'Periode: ${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.white,
                      ),
                    ),
                    if (_selectedJenisPelanggan != null)
                      pw.Text(
                        'Jenis Pelanggan: $_selectedJenisPelanggan',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.white,
                        ),
                      ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Summary Section
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'RINGKASAN',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Total Transaksi:', style: pw.TextStyle(fontSize: 12)),
                            pw.Text('$totalTransactions', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Total Item:', style: pw.TextStyle(fontSize: 12)),
                            pw.Text('$totalItems', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text('Total Pendapatan:', style: pw.TextStyle(fontSize: 12)),
                            pw.Text('Rp ${NumberFormat('#,###').format(totalRevenue)}', 
                              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Transaction Table
              pw.Text(
                'DETAIL TRANSAKSI',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              
              // Transaction Details with Items
               ..._filteredTransaksi.asMap().entries.map((entry) {
                 int index = entry.key;
                 TransaksiModel transaksi = entry.value;
                 
                 return pw.Column(
                   crossAxisAlignment: pw.CrossAxisAlignment.start,
                   children: [
                     // Transaction Header
                     pw.Container(
                       width: double.infinity,
                       padding: const pw.EdgeInsets.all(12),
                       margin: const pw.EdgeInsets.only(bottom: 8),
                       decoration: pw.BoxDecoration(
                         color: PdfColors.blue50,
                         border: pw.Border.all(color: PdfColors.blue200),
                         borderRadius: pw.BorderRadius.circular(6),
                       ),
                       child: pw.Row(
                         mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                         children: [
                           pw.Column(
                             crossAxisAlignment: pw.CrossAxisAlignment.start,
                             children: [
                               pw.Text(
                                 'Transaksi #${index + 1} - ${transaksi.namaPelanggan}',
                                 style: pw.TextStyle(
                                   fontSize: 12,
                                   fontWeight: pw.FontWeight.bold,
                                   color: PdfColors.blue800,
                                 ),
                               ),
                               pw.SizedBox(height: 2),
                               pw.Text(
                                 'ID: ${transaksi.id}',
                                 style: pw.TextStyle(
                                   fontSize: 9,
                                   color: PdfColors.grey600,
                                 ),
                               ),
                               pw.Text(
                                 'Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(transaksi.tanggalBeli)}',
                                 style: pw.TextStyle(
                                   fontSize: 9,
                                   color: PdfColors.grey600,
                                 ),
                               ),
                               // Tambahkan nama usaha jika ada
                               if (_pelangganMap[transaksi.idPelanggan]?.namaTempatUsaha != null)
                                 pw.Text(
                                   'Usaha: ${_pelangganMap[transaksi.idPelanggan]!.namaTempatUsaha}',
                                   style: pw.TextStyle(
                                     fontSize: 9,
                                     color: PdfColors.grey600,
                                     fontStyle: pw.FontStyle.italic,
                                   ),
                                 ),
                               // Tambahkan jenis pelanggan
                               pw.Text(
                                 'Jenis: ${_pelangganMap[transaksi.idPelanggan]?.jenisPelanggan ?? 'Tidak diketahui'}',
                                 style: pw.TextStyle(
                                   fontSize: 9,
                                   color: PdfColors.grey600,
                                 ),
                               ),
                             ],
                           ),
                           pw.Text(
                             'Total: Rp ${NumberFormat('#,###').format(transaksi.totalHarga)}',
                             style: pw.TextStyle(
                               fontSize: 11,
                               fontWeight: pw.FontWeight.bold,
                               color: PdfColors.green700,
                             ),
                           ),
                         ],
                       ),
                     ),
                     
                     // Items Table
                     pw.Table(
                       border: pw.TableBorder.all(color: PdfColors.grey300),
                       columnWidths: {
                         0: const pw.FlexColumnWidth(3),
                         1: const pw.FlexColumnWidth(1),
                         2: const pw.FlexColumnWidth(1.5),
                         3: const pw.FlexColumnWidth(1.5),
                       },
                       children: [
                         // Items Header
                         pw.TableRow(
                           decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                           children: [
                             pw.Padding(
                               padding: const pw.EdgeInsets.all(6),
                               child: pw.Text('Nama Produk', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                             ),
                             pw.Padding(
                               padding: const pw.EdgeInsets.all(6),
                               child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                             ),
                             pw.Padding(
                               padding: const pw.EdgeInsets.all(6),
                               child: pw.Text('Harga', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                             ),
                             pw.Padding(
                               padding: const pw.EdgeInsets.all(6),
                               child: pw.Text('Subtotal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                             ),
                           ],
                         ),
                         // Items Data
                         ...transaksi.items.map((item) {
                           return pw.TableRow(
                             children: [
                               pw.Padding(
                                  padding: const pw.EdgeInsets.all(6),
                                  child: pw.Text(item.jenisSayur, style: const pw.TextStyle(fontSize: 8)),
                                ),
                               pw.Padding(
                                 padding: const pw.EdgeInsets.all(6),
                                 child: pw.Text('${item.jumlah}', style: const pw.TextStyle(fontSize: 8)),
                               ),
                               pw.Padding(
                                 padding: const pw.EdgeInsets.all(6),
                                 child: pw.Text('Rp ${NumberFormat('#,###').format(item.harga)}', style: const pw.TextStyle(fontSize: 8)),
                               ),
                               pw.Padding(
                                 padding: const pw.EdgeInsets.all(6),
                                 child: pw.Text('Rp ${NumberFormat('#,###').format(item.totalHarga)}', style: const pw.TextStyle(fontSize: 8)),
                               ),
                             ],
                           );
                         }).toList(),
                       ],
                     ),
                     
                     pw.SizedBox(height: 16),
                   ],
                 );
               }).toList(),
            ];
          },
        ),
      );
      
      // Save PDF to file
      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/laporan_transaksi_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      // Open the PDF file
      await OpenFile.open(file.path);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF berhasil dibuat dan disimpan'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error membuat PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTransaksiDetail(TransaksiModel transaksi) {
    final pelanggan = _pelangganMap[transaksi.idPelanggan];
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modern Header with gradient
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detail Transaksi',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${transaksi.id}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey[50]!, Colors.grey[100]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    size: 20,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        transaksi.namaPelanggan,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (pelanggan?.jenisPelanggan != null)
                                        Text(
                                          pelanggan!.jenisPelanggan,
                                          style: TextStyle(
                                            color: Colors.blue[600],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(transaksi.tanggalBeli),
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('HH:mm').format(transaksi.tanggalBeli),
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (pelanggan?.namaTempatUsaha != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.business, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      pelanggan!.namaTempatUsaha!,
                                      style: TextStyle(
                                        color: Colors.grey[700],
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
                      const SizedBox(height: 20),
                      
                      // Items Section
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.shopping_cart,
                              size: 20,
                              color: Colors.green[700],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Item Pembelian',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${transaksi.items.length} item',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Items List with modern design
                      ...transaksi.items.asMap().entries.map((entry) {
                        int index = entry.key;
                        var item = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.1),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.jenisSayur,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange[100],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${item.jumlah} ${item.satuan}',
                                            style: TextStyle(
                                              color: Colors.orange[700],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '@ Rp ${NumberFormat('#,###').format(item.harga)}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Rp ${NumberFormat('#,###').format(item.totalHarga)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      
                      const SizedBox(height: 20),
                      
                      // Additional Info
                      if (transaksi.informasiLain != null && transaksi.informasiLain!.isNotEmpty) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.info_outline,
                                size: 20,
                                color: Colors.amber[700],
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Informasi Tambahan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber[200]!),
                          ),
                          child: Text(
                            transaksi.informasiLain!,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      
                      // Total Section with modern design
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green[50]!, Colors.green[100]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Item',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      '${transaksi.items.fold(0.0, (sum, item) => sum + item.jumlah).toStringAsFixed(transaksi.items.fold(0.0, (sum, item) => sum + item.jumlah) == transaksi.items.fold(0.0, (sum, item) => sum + item.jumlah).truncateToDouble() ? 0 : 1)} item',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Total Pembayaran',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'Rp ${NumberFormat('#,###').format(transaksi.totalHarga)}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Action Buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        label: const Text('Tutup'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _generateSingleTransactionPDF(transaksi);
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Export PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    double totalRevenue = _filteredTransaksi.fold(0, (sum, transaksi) => sum + transaksi.totalHarga);
    int totalTransactions = _filteredTransaksi.length;
    double totalItems = _filteredTransaksi.fold(0.0, (sum, transaksi) => 
        sum + transaksi.items.fold(0.0, (itemSum, item) => itemSum + item.jumlah));

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Ringkasan Transaksi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Transaksi',
                  totalTransactions.toString(),
                  Icons.receipt_long,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Total Item',
                  totalItems.toStringAsFixed(totalItems == totalItems.truncateToDouble() ? 0 : 1),
                  Icons.shopping_cart,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Total Pendapatan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rp ${NumberFormat('#,###').format(totalRevenue)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
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

  Widget _buildSummaryItem(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laporan Transaksi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onSelected: (String value) {
              if (value == 'all') {
                _generatePDFReport();
              } else if (value == 'customer') {
                _generatePDFReportByCustomer();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.list_alt, size: 20),
                    SizedBox(width: 8),
                    Text('Semua Transaksi'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'customer',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20),
                    SizedBox(width: 8),
                    Text('Per Pelanggan'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
          // Summary Card
          _buildSummaryCard(),
          
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari berdasarkan nama pelanggan atau ID transaksi...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _filterTransaksi();
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) => _filterTransaksi(),
                ),
                const SizedBox(height: 8),
                
                // Filter Jenis Pelanggan
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedJenisPelanggan,
                      hint: const Text('Pilih Jenis Pelanggan'),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Semua Jenis Pelanggan'),
                        ),
                        const DropdownMenuItem<String>(
                          value: 'restoran',
                          child: Text('Restoran'),
                        ),
                        const DropdownMenuItem<String>(
                          value: 'hotel',
                          child: Text('Hotel'),
                        ),
                        const DropdownMenuItem<String>(
                          value: 'individu',
                          child: Text('Individu'),
                        ),
                      ],
                      onChanged: (String? value) {
                        setState(() {
                          _selectedJenisPelanggan = value;
                        });
                        _filterTransaksi();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Filter Pelanggan Spesifik
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPelangganId,
                      hint: const Text('Pilih Pelanggan Spesifik'),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Semua Pelanggan'),
                        ),
                        ..._pelangganMap.values.map((pelanggan) {
                          return DropdownMenuItem<String>(
                            value: pelanggan.id,
                            child: Text(
                              '${pelanggan.namaPelanggan} (${pelanggan.jenisPelanggan})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (String? value) {
                        setState(() {
                          _selectedPelangganId = value;
                        });
                        _filterTransaksi();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Filter Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectDateRange,
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          _startDate != null && _endDate != null
                              ? '${DateFormat('dd/MM/yy').format(_startDate!)} - ${DateFormat('dd/MM/yy').format(_endDate!)}'
                              : 'Pilih Rentang Tanggal',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _clearFilters,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                
                // Export PDF Button for Selected Customer
                if (_selectedPelangganId != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _generatePDFReportByCustomer,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: Text(
                        'Export PDF untuk ${_pelangganMap[_selectedPelangganId!]?.namaPelanggan ?? "Pelanggan"}',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Filter Status Info
          if (_selectedPelangganId != null || _selectedJenisPelanggan != null || _startDate != null || _endDate != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.filter_list, color: Colors.blue[600], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Filter Aktif:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (_selectedPelangganId != null)
                        Chip(
                          label: Text(
                            'Pelanggan: ${_pelangganMap[_selectedPelangganId!]?.namaPelanggan ?? "Unknown"}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: Colors.blue[100],
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      if (_selectedJenisPelanggan != null)
                        Chip(
                          label: Text(
                            'Jenis: ${_selectedJenisPelanggan!.toUpperCase()}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: Colors.green[100],
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      if (_startDate != null && _endDate != null)
                        Chip(
                          label: Text(
                            'Tanggal: ${DateFormat('dd/MM/yy').format(_startDate!)} - ${DateFormat('dd/MM/yy').format(_endDate!)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: Colors.orange[100],
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Menampilkan ${_filteredTransaksi.length} dari ${_allTransaksi.length} transaksi',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          
          // Transaction List
          _isLoading
              ? Container(
                  height: 200,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : _filteredTransaksi.isEmpty
                  ? Container(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tidak ada transaksi ditemukan',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Coba ubah filter pencarian Anda',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _filteredTransaksi.length,
                      itemBuilder: (context, index) {
                          final transaksi = _filteredTransaksi[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: InkWell(
                              onTap: () => _showTransaksiDetail(transaksi),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[100],
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(
                                            Icons.receipt,
                                            color: Colors.blue,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                transaksi.namaPelanggan,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                'ID: ${transaksi.id}',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Rp ${NumberFormat('#,###').format(transaksi.totalHarga)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.green,
                                              ),
                                            ),
                                            Text(
                                              DateFormat('dd/MM/yyyy').format(transaksi.tanggalBeli),
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.shopping_cart,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${transaksi.items.length} item',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('HH:mm').format(transaksi.tanggalBeli),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 12,
                                          color: Colors.grey[400],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}