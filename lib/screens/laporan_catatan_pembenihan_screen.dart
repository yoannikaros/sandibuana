import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../models/catatan_pembenihan_model.dart';
import '../models/jenis_benih_model.dart';
import '../models/tandon_air_model.dart';
import '../models/jenis_pupuk_model.dart';
import '../providers/benih_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/tandon_provider.dart';
import '../providers/pupuk_provider.dart';

class LaporanCatatanPembenihanScreen extends StatefulWidget {
  const LaporanCatatanPembenihanScreen({super.key});

  @override
  State<LaporanCatatanPembenihanScreen> createState() => _LaporanCatatanPembenihanScreenState();
}

class _LaporanCatatanPembenihanScreenState extends State<LaporanCatatanPembenihanScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _searchQuery = '';
  String _statusFilter = 'semua';
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    // Defer loading until after the build is complete to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final benihProvider = Provider.of<BenihProvider>(context, listen: false);
    final tandonProvider = Provider.of<TandonProvider>(context, listen: false);
    final pupukProvider = Provider.of<PupukProvider>(context, listen: false);
    
    await Future.wait([
      benihProvider.loadCatatanPembenihanByTanggal(_startDate, _endDate),
      benihProvider.loadJenisBenihAktif(),
      tandonProvider.loadTandonAir(),
      pupukProvider.loadJenisPupukAktif(),
    ]);
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      await _loadData();
    }
  }

  List<CatatanPembenihanModel> _getFilteredData(List<CatatanPembenihanModel> data, BenihProvider benihProvider) {
    return data.where((catatan) {
      // Filter berdasarkan status
      if (_statusFilter != 'semua' && catatan.status != _statusFilter) {
        return false;
      }
      
      // Filter berdasarkan pencarian
      if (_searchQuery.isNotEmpty) {
        final benih = benihProvider.jenisBenihList.firstWhere(
          (b) => b.idBenih == catatan.idBenih,
          orElse: () => JenisBenihModel(
            idBenih: '',
            namaBenih: 'Unknown',
            pemasok: '',
            hargaPerSatuan: 0,
            jenisSatuan: '',
            ukuranSatuan: '',
            aktif: true,
            dibuatPada: DateTime.now(),
          ),
        );
        
        return benih.namaBenih.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               catatan.kodeBatch.toLowerCase().contains(_searchQuery.toLowerCase());
      }
      
      return true;
    }).toList();
  }

  Map<String, dynamic> _generateStatistics(List<CatatanPembenihanModel> data, BenihProvider benihProvider) {
    if (data.isEmpty) {
      return {
        'total': 0,
        'berjalan': 0,
        'panen': 0,
        'gagal': 0,
        'totalJumlah': 0,
        'benihTerpopuler': 'Tidak ada data',
        'rataRataJumlah': 0.0,
      };
    }

    final statusCount = <String, int>{};
    var totalJumlah = 0;
    final benihCount = <String, int>{};

    for (final catatan in data) {
      // Hitung status
      statusCount[catatan.status] = (statusCount[catatan.status] ?? 0) + 1;
      
      // Hitung total jumlah
      totalJumlah += catatan.jumlah;
      
      // Hitung benih terpopuler
      final benih = benihProvider.jenisBenihList.firstWhere(
        (b) => b.idBenih == catatan.idBenih,
        orElse: () => JenisBenihModel(
          idBenih: '',
          namaBenih: 'Unknown',
          pemasok: '',
          hargaPerSatuan: 0,
          jenisSatuan: '',
          ukuranSatuan: '',
          aktif: true,
          dibuatPada: DateTime.now(),
        ),
      );
      benihCount[benih.namaBenih] = (benihCount[benih.namaBenih] ?? 0) + 1;
    }

    // Cari benih terpopuler
    String benihTerpopuler = 'Tidak ada data';
    if (benihCount.isNotEmpty) {
      benihTerpopuler = benihCount.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    return {
      'total': data.length,
      'berjalan': statusCount['berjalan'] ?? 0,
      'panen': statusCount['panen'] ?? 0,
      'gagal': statusCount['gagal'] ?? 0,
      'totalJumlah': totalJumlah,
      'benihTerpopuler': benihTerpopuler,
      'rataRataJumlah': totalJumlah / data.length,
    };
  }

  Future<void> _generatePdfReport() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final benihProvider = Provider.of<BenihProvider>(context, listen: false);
      final tandonProvider = Provider.of<TandonProvider>(context, listen: false);
      final pupukProvider = Provider.of<PupukProvider>(context, listen: false);
      
      final filteredData = _getFilteredData(benihProvider.catatanPembenihanList, benihProvider);
      final statistics = _generateStatistics(filteredData, benihProvider);

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Text(
                  'LAPORAN CATATAN PEMBENIHAN',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Info periode
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Periode: ${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text('Tanggal Cetak: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
                    if (_statusFilter != 'semua')
                      pw.Text('Filter Status: ${_statusFilter.toUpperCase()}'),
                    if (_searchQuery.isNotEmpty)
                      pw.Text('Pencarian: $_searchQuery'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Statistik
              pw.Text(
                'RINGKASAN STATISTIK',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Metrik', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Nilai', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Total Catatan'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('${statistics['total']}'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Status Berjalan'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('${statistics['berjalan']}'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Status Panen'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('${statistics['panen']}'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Status Gagal'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('${statistics['gagal']}'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Total Jumlah'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('${statistics['totalJumlah']}'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Rata-rata Jumlah'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('${statistics['rataRataJumlah'].toStringAsFixed(1)}'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Benih Terpopuler'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('${statistics['benihTerpopuler']}'),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              
              // Detail data
              pw.Text(
                'DETAIL CATATAN PEMBENIHAN',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              
              // Tabel data
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FixedColumnWidth(60),
                  1: const pw.FixedColumnWidth(80),
                  2: const pw.FixedColumnWidth(100),
                  3: const pw.FixedColumnWidth(80),
                  4: const pw.FixedColumnWidth(60),
                  5: const pw.FixedColumnWidth(80),
                  6: const pw.FixedColumnWidth(60),
                },
                children: [
                  // Header tabel
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Tanggal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Kode Batch', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Jenis Benih', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Jumlah', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Tandon', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Media', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      ),
                    ],
                  ),
                  
                  // Data rows
                  ...filteredData.map((catatan) {
                    final benih = benihProvider.jenisBenihList.firstWhere(
                      (b) => b.idBenih == catatan.idBenih,
                      orElse: () => JenisBenihModel(
                        idBenih: '',
                        namaBenih: 'Unknown',
                        pemasok: '',
                        hargaPerSatuan: 0,
                        jenisSatuan: '',
                        ukuranSatuan: '',
                        aktif: true,
                        dibuatPada: DateTime.now(),
                      ),
                    );
                    
                    final tandon = catatan.idTandon != null
                        ? tandonProvider.tandonAirList.firstWhere(
                            (t) => t.id == catatan.idTandon,
                            orElse: () => TandonAirModel(id: '', kodeTandon: 'Unknown'),
                          )
                        : null;
                    
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            DateFormat('dd/MM/yy').format(catatan.tanggalPembenihan),
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            catatan.kodeBatch,
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            benih.namaBenih,
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            '${catatan.jumlah} ${catatan.satuan ?? ''}',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            catatan.status.toUpperCase(),
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            tandon?.namaTandon ?? tandon?.kodeTandon ?? '-',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            catatan.mediaTanam ?? '-',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ];
          },
        ),
      );

      // Simpan PDF
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'laporan_catatan_pembenihan_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Buka PDF
      await OpenFile.open(file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF berhasil dibuat: $fileName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isGeneratingPdf = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Catatan Pembenihan'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isGeneratingPdf ? null : _generatePdfReport,
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
          ),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter dan pencarian
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                // Periode tanggal
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectDateRange,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.date_range, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Pencarian dan filter status
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari berdasarkan nama benih atau kode batch...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _statusFilter,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'semua', child: Text('Semua Status')),
                          DropdownMenuItem(value: 'berjalan', child: Text('Berjalan')),
                          DropdownMenuItem(value: 'panen', child: Text('Panen')),
                          DropdownMenuItem(value: 'gagal', child: Text('Gagal')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _statusFilter = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Konten utama
          Expanded(
            child: Consumer4<BenihProvider, TandonProvider, PupukProvider, AuthProvider>(
              builder: (context, benihProvider, tandonProvider, pupukProvider, authProvider, child) {
                if (benihProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (benihProvider.errorMessage != null) {
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
                          'Error: ${benihProvider.errorMessage}',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                final filteredData = _getFilteredData(benihProvider.catatanPembenihanList, benihProvider);
                final statistics = _generateStatistics(filteredData, benihProvider);

                if (filteredData.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.grass,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _statusFilter != 'semua'
                              ? 'Tidak ada catatan pembenihan yang sesuai dengan filter'
                              : 'Belum ada catatan pembenihan pada periode ini',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Statistik ringkasan
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ringkasan Statistik',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Grid statistik - Responsive layout
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    // Tentukan jumlah kolom berdasarkan lebar layar
                                    int crossAxisCount = 2;
                                    if (constraints.maxWidth > 600) {
                                      crossAxisCount = 3;
                                    }
                                    if (constraints.maxWidth > 900) {
                                      crossAxisCount = 4;
                                    }
                                    
                                    return GridView.count(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      crossAxisCount: crossAxisCount,
                                      childAspectRatio: 1.2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      children: [
                                        _buildStatCard('Total Catatan', '${statistics['total']}', Icons.list_alt, Colors.blue),
                                        _buildStatCard('Berjalan', '${statistics['berjalan']}', Icons.play_circle, Colors.orange),
                                        _buildStatCard('Panen', '${statistics['panen']}', Icons.check_circle, Colors.green),
                                        _buildStatCard('Gagal', '${statistics['gagal']}', Icons.cancel, Colors.red),
                                        _buildStatCard('Total Jumlah', '${statistics['totalJumlah']}', Icons.numbers, Colors.purple),
                                        _buildStatCard('Rata-rata', '${statistics['rataRataJumlah'].toStringAsFixed(1)}', Icons.analytics, Colors.teal),
                                      ],
                                    );
                                  },
                                ),
                                
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.star, color: Colors.green.shade600),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Benih Terpopuler: ${statistics['benihTerpopuler']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Detail data
                        Text(
                          'Detail Catatan Pembenihan (${filteredData.length} data)',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // List data
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredData.length,
                          itemBuilder: (context, index) {
                            final catatan = filteredData[index];
                            return _buildCatatanCard(catatan, benihProvider, tandonProvider, pupukProvider);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatatanCard(
    CatatanPembenihanModel catatan,
    BenihProvider benihProvider,
    TandonProvider tandonProvider,
    PupukProvider pupukProvider,
  ) {
    // Get benih name
    final benih = benihProvider.jenisBenihList.firstWhere(
      (b) => b.idBenih == catatan.idBenih,
      orElse: () => JenisBenihModel(
        idBenih: '',
        namaBenih: 'Unknown',
        pemasok: '',
        hargaPerSatuan: 0,
        jenisSatuan: '',
        ukuranSatuan: '',
        aktif: true,
        dibuatPada: DateTime.now(),
      ),
    );
    
    // Get tandon name
    final tandon = catatan.idTandon != null
        ? tandonProvider.tandonAirList.firstWhere(
            (t) => t.id == catatan.idTandon,
            orElse: () => TandonAirModel(id: '', kodeTandon: 'Unknown'),
          )
        : null;
    
    // Get pupuk name
    final pupuk = catatan.idPupuk != null
        ? pupukProvider.jenisPupukAktif.firstWhere(
            (p) => p.id == catatan.idPupuk,
            orElse: () => JenisPupukModel(id: '', namaPupuk: 'Unknown', tipe: ''),
          )
        : null;
    
    // Status color
    Color statusColor;
    switch (catatan.status) {
      case 'berjalan':
        statusColor = Colors.blue;
        break;
      case 'panen':
        statusColor = Colors.green;
        break;
      case 'gagal':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan tanggal dan status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(catatan.tanggalPembenihan),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    catatan.status.toUpperCase(),
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
            
            // Nama benih
            Row(
              children: [
                Icon(Icons.grass, size: 20, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    benih.namaBenih,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Detail informasi
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jumlah: ${catatan.jumlah} ${catatan.satuan ?? ''}',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Batch: ${catatan.kodeBatch}',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tandon != null) ...[
                        Text(
                          'Tandon: ${tandon.namaTandon ?? tandon.kodeTandon}',
                          style: TextStyle(
                            color: Colors.cyan[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (catatan.mediaTanam != null) ...[
                        Text(
                          'Media: ${catatan.mediaTanam}',
                          style: TextStyle(
                            color: Colors.brown[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
            
            if (pupuk != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.eco, size: 16, color: Colors.orange.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Pupuk: ${pupuk.namaPupuk}',
                    style: TextStyle(
                      color: Colors.orange[600],
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
            
            if (catatan.catatan != null && catatan.catatan!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        catatan.catatan!,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Footer dengan info pencatat
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tanggal Semai: ${DateFormat('dd/MM/yyyy').format(catatan.tanggalSemai)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  'Dicatat: ${DateFormat('dd/MM/yyyy HH:mm').format(catatan.dicatatPada)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}