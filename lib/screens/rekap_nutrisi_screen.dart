import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../providers/monitoring_nutrisi_provider.dart';
import '../models/monitoring_nutrisi_model.dart';
import '../models/tandon_monitoring_data_model.dart';

class RekapNutrisiScreen extends StatefulWidget {
  const RekapNutrisiScreen({Key? key}) : super(key: key);

  @override
  State<RekapNutrisiScreen> createState() => _RekapNutrisiScreenState();
}

class _RekapNutrisiScreenState extends State<RekapNutrisiScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedPeriod = 'Minggu Ini';
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _monthFormat = DateFormat('MMM yyyy');

  @override
  void initState() {
    super.initState();
    _setDefaultDateRange();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _setDefaultDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Hari Ini':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'Minggu Ini':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        _startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'Bulan Ini':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 'Custom':
        // Keep existing dates or set to this month
        _startDate ??= DateTime(now.year, now.month, 1);
        _endDate ??= DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
    }
  }

  void _loadData() {
    if (_startDate != null && _endDate != null) {
      final provider = Provider.of<MonitoringNutrisiProvider>(context, listen: false);
      provider.loadMonitoringByDateRange(_startDate!, _endDate!);
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
        _selectedPeriod = 'Custom';
      });
      _loadData();
    }
  }

  Map<String, dynamic> _calculateNutrisiSummary(List<MonitoringNutrisiModel> monitoringList) {
    double totalNutrisiAdded = 0;
    double totalPpmAverage = 0;
    double totalPhAverage = 0;
    double totalTempAverage = 0;
    Map<String, double> nutrisiByTandon = {};
    Map<String, double> ppmByTandon = {};
    Map<String, double> phByTandon = {};
    Map<String, double> tempByTandon = {};
    Map<String, int> countByTandon = {};
    Set<String> uniqueDates = {};
    int totalReadings = 0;

    for (var monitoring in monitoringList) {
      uniqueDates.add(_dateFormat.format(monitoring.tanggalMonitoring));
      
      if (monitoring.tandonData != null) {
        for (var tandon in monitoring.tandonData!) {
          final tandonName = tandon.namaTandon;
          
          // Nutrisi ditambah
          if (tandon.nutrisiDitambah != null && tandon.nutrisiDitambah! > 0) {
            totalNutrisiAdded += tandon.nutrisiDitambah!;
            nutrisiByTandon[tandonName] = 
                (nutrisiByTandon[tandonName] ?? 0) + tandon.nutrisiDitambah!;
          }
          
          // PPM
          if (tandon.nilaiPpm != null && tandon.nilaiPpm! > 0) {
            totalPpmAverage += tandon.nilaiPpm!;
            ppmByTandon[tandonName] = 
                (ppmByTandon[tandonName] ?? 0) + tandon.nilaiPpm!;
            totalReadings++;
          }
          
          // pH
          if (tandon.tingkatPh != null && tandon.tingkatPh! > 0) {
            totalPhAverage += tandon.tingkatPh!;
            phByTandon[tandonName] = 
                (phByTandon[tandonName] ?? 0) + tandon.tingkatPh!;
          }
          
          // Temperature
          if (tandon.suhuAir != null && tandon.suhuAir! > 0) {
            totalTempAverage += tandon.suhuAir!;
            tempByTandon[tandonName] = 
                (tempByTandon[tandonName] ?? 0) + tandon.suhuAir!;
          }
          
          countByTandon[tandonName] = 
              (countByTandon[tandonName] ?? 0) + 1;
        }
      }
    }

    // Calculate averages
    for (String tandon in countByTandon.keys) {
      final count = countByTandon[tandon]!;
      if (ppmByTandon.containsKey(tandon)) {
        ppmByTandon[tandon] = ppmByTandon[tandon]! / count;
      }
      if (phByTandon.containsKey(tandon)) {
        phByTandon[tandon] = phByTandon[tandon]! / count;
      }
      if (tempByTandon.containsKey(tandon)) {
        tempByTandon[tandon] = tempByTandon[tandon]! / count;
      }
    }

    return {
      'totalNutrisi': totalNutrisiAdded,
      'averagePpm': totalReadings > 0 ? totalPpmAverage / totalReadings : 0,
      'averagePh': totalReadings > 0 ? totalPhAverage / totalReadings : 0,
      'averageTemp': totalReadings > 0 ? totalTempAverage / totalReadings : 0,
      'nutrisiByTandon': nutrisiByTandon,
      'ppmByTandon': ppmByTandon,
      'phByTandon': phByTandon,
      'tempByTandon': tempByTandon,
      'countByTandon': countByTandon,
      'totalDays': uniqueDates.length,
      'totalReadings': totalReadings,
    };
  }

  List<Map<String, dynamic>> _getDetailedNutrisiData(List<MonitoringNutrisiModel> monitoringList) {
    List<Map<String, dynamic>> detailData = [];
    
    for (var monitoring in monitoringList) {
      if (monitoring.tandonData != null) {
        for (var tandon in monitoring.tandonData!) {
          detailData.add({
            'tanggal': monitoring.tanggalMonitoring,
            'namaTandon': tandon.namaTandon,
            'nilaiPpm': tandon.nilaiPpm ?? 0,
            'tingkatPh': tandon.tingkatPh ?? 0,
            'suhuAir': tandon.suhuAir ?? 0,
            'nutrisiDitambah': tandon.nutrisiDitambah ?? 0,
            'airDitambah': tandon.airDitambah ?? 0,
            'catatan': tandon.catatan ?? '-',
            'monitoringNama': monitoring.nama,
          });
        }
      }
    }
    
    // Sort by date descending
    detailData.sort((a, b) => (b['tanggal'] as DateTime).compareTo(a['tanggal'] as DateTime));
    return detailData;
  }

  Widget _buildSummaryCard(Map<String, dynamic> summary) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.green.shade600),
              const SizedBox(width: 8),
              Text(
                'Ringkasan Nutrisi',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Nutrisi',
                  '${summary['totalNutrisi'].toStringAsFixed(1)} l',
                  Icons.water_drop,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Rata-rata PPM',
                  '${summary['averagePpm'].toStringAsFixed(1)}',
                  Icons.speed,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Rata-rata pH',
                  '${summary['averagePh'].toStringAsFixed(1)}',
                  Icons.science,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Rata-rata Suhu',
                  '${summary['averageTemp'].toStringAsFixed(1)}°C',
                  Icons.thermostat,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Hari',
                  '${summary['totalDays']} hari',
                  Icons.calendar_today,
                  Colors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Pembacaan',
                  '${summary['totalReadings']}',
                  Icons.assessment,
                  Colors.indigo,
                ),
              ),
            ],
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailList(List<Map<String, dynamic>> detailData) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.list_alt, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(
                  'Detail Monitoring Nutrisi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: detailData.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = detailData[index];
              final tanggal = data['tanggal'] as DateTime;
              final catatan = data['catatan'] as String;
              
              return Padding(
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
                                _dateFormat.format(tanggal),
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              Text(
                                data['namaTandon'],
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            data['monitoringNama'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailItem(
                            'PPM',
                            '${data['nilaiPpm'].toStringAsFixed(1)}',
                            Icons.speed,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDetailItem(
                            'pH',
                            '${data['tingkatPh'].toStringAsFixed(1)}',
                            Icons.science,
                            Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDetailItem(
                            'Suhu',
                            '${data['suhuAir'].toStringAsFixed(1)}°C',
                            Icons.thermostat,
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailItem(
                            'Nutrisi',
                            '${data['nutrisiDitambah'].toStringAsFixed(1)} L',
                            Icons.water_drop,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDetailItem(
                            'Air',
                            '${data['airDitambah'].toStringAsFixed(1)} L',
                            Icons.opacity,
                            Colors.cyan,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                    if (catatan != '-') ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Catatan:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              catatan,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToPDF() async {
    try {
      final provider = Provider.of<MonitoringNutrisiProvider>(context, listen: false);
      
      if (provider.monitoringList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada data untuk diekspor'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Membuat PDF...'),
            ],
          ),
        ),
      );

      final pdf = pw.Document();
      final now = DateTime.now();
      final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
      
      final monitoringList = provider.monitoringList;
      final summary = _calculateNutrisiSummary(monitoringList);
      final detailData = _getDetailedNutrisiData(monitoringList);
      
      // Create PDF content
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'LAPORAN REKAP NUTRISI',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Periode: ${_startDate != null && _endDate != null ? '${_dateFormat.format(_startDate!)} - ${_dateFormat.format(_endDate!)}' : 'Semua Data'}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.Text(
                      'Dicetak pada: ${dateFormat.format(now)}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.SizedBox(height: 16),
                  ],
                ),
              ),
              
              // Summary Section
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'RINGKASAN NUTRISI',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Total Nutrisi:', style: const pw.TextStyle(fontSize: 10)),
                              pw.Text('${summary['totalNutrisi'].toStringAsFixed(1)} L', 
                                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Rata-rata PPM:', style: const pw.TextStyle(fontSize: 10)),
                              pw.Text('${summary['averagePpm'].toStringAsFixed(1)}', 
                                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Rata-rata pH:', style: const pw.TextStyle(fontSize: 10)),
                              pw.Text('${summary['averagePh'].toStringAsFixed(1)}', 
                                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Rata-rata Suhu:', style: const pw.TextStyle(fontSize: 10)),
                              pw.Text('${summary['averageTemp'].toStringAsFixed(1)}°C', 
                                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Total Hari:', style: const pw.TextStyle(fontSize: 10)),
                              pw.Text('${summary['totalDays']} hari', 
                                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Total Pembacaan:', style: const pw.TextStyle(fontSize: 10)),
                              pw.Text('${summary['totalReadings']}', 
                                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Detail Table
              pw.Text(
                'DETAIL MONITORING NUTRISI',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FixedColumnWidth(60),
                  1: const pw.FixedColumnWidth(80),
                  2: const pw.FixedColumnWidth(50),
                  3: const pw.FixedColumnWidth(40),
                  4: const pw.FixedColumnWidth(50),
                  5: const pw.FixedColumnWidth(50),
                  6: const pw.FixedColumnWidth(50),
                  7: const pw.FlexColumnWidth(),
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Tanggal',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Tandon',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'PPM',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'pH',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Suhu (°C)',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Nutrisi (L)',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Air (L)',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Catatan',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  
                  // Data rows
                  ...detailData.map((data) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            _dateFormat.format(data['tanggal']),
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            data['namaTandon'],
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            data['nilaiPpm'].toStringAsFixed(1),
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            data['tingkatPh'].toStringAsFixed(1),
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            data['suhuAir'].toStringAsFixed(1),
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            data['nutrisiDitambah'].toStringAsFixed(1),
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            data['airDitambah'].toStringAsFixed(1),
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            data['catatan'] ?? '-',
                            textAlign: pw.TextAlign.left,
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

      // Save PDF file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'rekap_nutrisi_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success dialog with option to open file
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('PDF Berhasil Dibuat'),
          content: Text('File PDF telah disimpan sebagai:\n$fileName'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await OpenFile.open(file.path);
              },
              child: const Text('Buka PDF'),
            ),
          ],
        ),
      );

    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Nutrisi'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Pilih Rentang Tanggal',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPDF,
            tooltip: 'Export PDF',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Period Selector
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Periode Rekap',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: ['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Custom'].map((period) {
                      return ChoiceChip(
                        label: Text(period),
                        selected: _selectedPeriod == period,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedPeriod = period;
                            });
                            _setDefaultDateRange();
                            _loadData();
                          }
                        },
                        selectedColor: Colors.green.shade100,
                        labelStyle: TextStyle(
                          color: _selectedPeriod == period 
                              ? Colors.green.shade700 
                              : Colors.grey.shade600,
                        ),
                      );
                    }).toList(),
                  ),
                  if (_startDate != null && _endDate != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${_dateFormat.format(_startDate!)} - ${_dateFormat.format(_endDate!)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: Consumer<MonitoringNutrisiProvider>(
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
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            provider.error!,
                            style: Theme.of(context).textTheme.bodyMedium,
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

                  final monitoringList = provider.monitoringList;
                  final summary = _calculateNutrisiSummary(monitoringList);
                  final detailData = _getDetailedNutrisiData(monitoringList);

                  if (detailData.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada data monitoring nutrisi',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Belum ada data monitoring nutrisi pada periode ini',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildSummaryCard(summary),
                        _buildDetailList(detailData),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}