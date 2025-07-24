import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PembelianBenihModel {
  final String? idPembelian;
  final DateTime tanggalBeli;
  final String idBenih; // Reference to jenis_benih
  final String pemasok;
  final double jumlah;
  final String? satuan;
  final double hargaSatuan;
  final double totalHarga;
  final String? nomorFaktur;
  final DateTime? tanggalKadaluarsa;
  final String? lokasiPenyimpanan;
  final String? catatan;
  final String dicatatOleh; // Reference to pengguna
  final DateTime dicatatPada;

  PembelianBenihModel({
    this.idPembelian,
    required this.tanggalBeli,
    required this.idBenih,
    required this.pemasok,
    required this.jumlah,
    this.satuan,
    required this.hargaSatuan,
    required this.totalHarga,
    this.nomorFaktur,
    this.tanggalKadaluarsa,
    this.lokasiPenyimpanan,
    this.catatan,
    required this.dicatatOleh,
    required this.dicatatPada,
  });

  factory PembelianBenihModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,
      ) {
    final data = snapshot.data();
    return PembelianBenihModel(
      idPembelian: snapshot.id,
      tanggalBeli: (data?['tanggal_beli'] as Timestamp).toDate(),
      idBenih: data?['id_benih'],
      pemasok: data?['pemasok'],
      jumlah: (data?['jumlah'] as num).toDouble(),
      satuan: data?['satuan'],
      hargaSatuan: (data?['harga_satuan'] as num).toDouble(),
      totalHarga: (data?['total_harga'] as num).toDouble(),
      nomorFaktur: data?['nomor_faktur'],
      tanggalKadaluarsa: data?['tanggal_kadaluarsa'] != null
          ? (data?['tanggal_kadaluarsa'] as Timestamp).toDate()
          : null,
      lokasiPenyimpanan: data?['lokasi_penyimpanan'],
      catatan: data?['catatan'],
      dicatatOleh: data?['dicatat_oleh'],
      dicatatPada: (data?['dicatat_pada'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "tanggal_beli": Timestamp.fromDate(tanggalBeli),
      "id_benih": idBenih,
      "pemasok": pemasok,
      "jumlah": jumlah,
      if (satuan != null) "satuan": satuan,
      "harga_satuan": hargaSatuan,
      "total_harga": totalHarga,
      if (nomorFaktur != null) "nomor_faktur": nomorFaktur,
      if (tanggalKadaluarsa != null) "tanggal_kadaluarsa": Timestamp.fromDate(tanggalKadaluarsa!),
      if (lokasiPenyimpanan != null) "lokasi_penyimpanan": lokasiPenyimpanan,
      if (catatan != null) "catatan": catatan,
      "dicatat_oleh": dicatatOleh,
      "dicatat_pada": Timestamp.fromDate(dicatatPada),
    };
  }

  // Alias for toFirestore to match service usage
  Map<String, dynamic> toMap() => toFirestore();

  // Factory method for fromMap to match service usage
  factory PembelianBenihModel.fromMap(Map<String, dynamic> data, String id) {
    return PembelianBenihModel(
      idPembelian: id,
      tanggalBeli: (data['tanggal_beli'] as Timestamp).toDate(),
      idBenih: data['id_benih'],
      pemasok: data['pemasok'],
      jumlah: (data['jumlah'] as num).toDouble(),
      satuan: data['satuan'],
      hargaSatuan: (data['harga_satuan'] as num).toDouble(),
      totalHarga: (data['total_harga'] as num).toDouble(),
      nomorFaktur: data['nomor_faktur'],
      tanggalKadaluarsa: data['tanggal_kadaluarsa'] != null
          ? (data['tanggal_kadaluarsa'] as Timestamp).toDate()
          : null,
      lokasiPenyimpanan: data['lokasi_penyimpanan'],
      catatan: data['catatan'],
      dicatatOleh: data['dicatat_oleh'],
      dicatatPada: (data['dicatat_pada'] as Timestamp).toDate(),
    );
  }

  // Method untuk membuat copy dengan perubahan
  PembelianBenihModel copyWith({
    String? idPembelian,
    DateTime? tanggalBeli,
    String? idBenih,
    String? pemasok,
    double? jumlah,
    String? satuan,
    double? hargaSatuan,
    double? totalHarga,
    String? nomorFaktur,
    DateTime? tanggalKadaluarsa,
    String? lokasiPenyimpanan,
    String? catatan,
    String? dicatatOleh,
    DateTime? dicatatPada,
  }) {
    return PembelianBenihModel(
      idPembelian: idPembelian ?? this.idPembelian,
      tanggalBeli: tanggalBeli ?? this.tanggalBeli,
      idBenih: idBenih ?? this.idBenih,
      pemasok: pemasok ?? this.pemasok,
      jumlah: jumlah ?? this.jumlah,
      satuan: satuan ?? this.satuan,
      hargaSatuan: hargaSatuan ?? this.hargaSatuan,
      totalHarga: totalHarga ?? this.totalHarga,
      nomorFaktur: nomorFaktur ?? this.nomorFaktur,
      tanggalKadaluarsa: tanggalKadaluarsa ?? this.tanggalKadaluarsa,
      lokasiPenyimpanan: lokasiPenyimpanan ?? this.lokasiPenyimpanan,
      catatan: catatan ?? this.catatan,
      dicatatOleh: dicatatOleh ?? this.dicatatOleh,
      dicatatPada: dicatatPada ?? this.dicatatPada,
    );
  }

  // Validation method
  String? validate() {
    if (tanggalBeli.isAfter(DateTime.now())) {
      return 'Tanggal beli tidak boleh di masa depan';
    }
    if (idBenih.isEmpty) {
      return 'Jenis benih harus dipilih';
    }
    if (pemasok.trim().isEmpty) {
      return 'Pemasok harus diisi';
    }
    if (jumlah <= 0) {
      return 'Jumlah harus lebih dari 0';
    }
    if (hargaSatuan <= 0) {
      return 'Harga satuan harus lebih dari 0';
    }
    if (totalHarga <= 0) {
      return 'Total harga harus lebih dari 0';
    }
    if (tanggalKadaluarsa != null && tanggalKadaluarsa!.isBefore(tanggalBeli)) {
      return 'Tanggal kadaluarsa tidak boleh sebelum tanggal beli';
    }
    return null;
  }

  // Static methods for template data
  static List<String> getSatuanOptions() {
    return [
      'gram',
      'kilogram',
      'biji',
      'pack',
      'tray',
      'hampan',
      'liter',
      'ml',
    ];
  }

  static List<String> getLokasiPenyimpananOptions() {
    return [
      'Gudang Utama',
      'Ruang Benih',
      'Lemari Es',
      'Rak A1',
      'Rak A2',
      'Rak B1',
      'Rak B2',
      'Area Semai',
    ];
  }

  // Helper methods for UI
  Color getStatusColor() {
    if (tanggalKadaluarsa == null) return Colors.grey;
    
    final now = DateTime.now();
    final daysUntilExpiry = tanggalKadaluarsa!.difference(now).inDays;
    
    if (daysUntilExpiry < 0) return Colors.red; // Expired
    if (daysUntilExpiry <= 30) return Colors.orange; // Expiring soon
    if (daysUntilExpiry <= 90) return Colors.yellow; // Warning
    return Colors.green; // Good
  }

  String getStatusText() {
    if (tanggalKadaluarsa == null) return 'Tidak ada tanggal kadaluarsa';
    
    final now = DateTime.now();
    final daysUntilExpiry = tanggalKadaluarsa!.difference(now).inDays;
    
    if (daysUntilExpiry < 0) return 'Kadaluarsa ${-daysUntilExpiry} hari yang lalu';
    if (daysUntilExpiry == 0) return 'Kadaluarsa hari ini';
    if (daysUntilExpiry <= 30) return 'Kadaluarsa dalam $daysUntilExpiry hari';
    if (daysUntilExpiry <= 90) return 'Kadaluarsa dalam $daysUntilExpiry hari';
    return 'Masih baik ($daysUntilExpiry hari)';
  }

  IconData getStatusIcon() {
    if (tanggalKadaluarsa == null) return Icons.help_outline;
    
    final now = DateTime.now();
    final daysUntilExpiry = tanggalKadaluarsa!.difference(now).inDays;
    
    if (daysUntilExpiry < 0) return Icons.dangerous;
    if (daysUntilExpiry <= 30) return Icons.warning;
    if (daysUntilExpiry <= 90) return Icons.schedule;
    return Icons.check_circle;
  }

  // Display formatting
  String get displayTitle => 'Pembelian ${satuan ?? ''} - $pemasok';
  
  String get displaySubtitle => 
      '${jumlah.toStringAsFixed(jumlah.truncateToDouble() == jumlah ? 0 : 2)} ${satuan ?? ''} - Rp ${totalHarga.toStringAsFixed(0)}';
  
  String get formattedTanggalBeli => 
      '${tanggalBeli.day.toString().padLeft(2, '0')}/${tanggalBeli.month.toString().padLeft(2, '0')}/${tanggalBeli.year}';
  
  String get formattedTanggalKadaluarsa => tanggalKadaluarsa != null
      ? '${tanggalKadaluarsa!.day.toString().padLeft(2, '0')}/${tanggalKadaluarsa!.month.toString().padLeft(2, '0')}/${tanggalKadaluarsa!.year}'
      : '-';
  
  String get formattedHargaSatuan => 'Rp ${hargaSatuan.toStringAsFixed(0)}';
  
  String get formattedTotalHarga => 'Rp ${totalHarga.toStringAsFixed(0)}';
  
  String get formattedJumlah => 
      '${jumlah.toStringAsFixed(jumlah.truncateToDouble() == jumlah ? 0 : 2)} ${satuan ?? ''}';

  // Business logic helpers
  bool get isExpired => tanggalKadaluarsa != null && tanggalKadaluarsa!.isBefore(DateTime.now());
  
  bool get isExpiringSoon => tanggalKadaluarsa != null && 
      tanggalKadaluarsa!.difference(DateTime.now()).inDays <= 30 && 
      !isExpired;
  
  bool get needsAttention => isExpired || isExpiringSoon;
  
  double get nilaiPerGram {
    if (satuan?.toLowerCase() == 'gram') return hargaSatuan;
    if (satuan?.toLowerCase() == 'kilogram') return hargaSatuan / 1000;
    return hargaSatuan; // For other units, return as is
  }

  @override
  String toString() {
    return 'PembelianBenihModel(idPembelian: $idPembelian, tanggalBeli: $tanggalBeli, idBenih: $idBenih, pemasok: $pemasok, jumlah: $jumlah, totalHarga: $totalHarga)';
  }
}