import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CatatanPerlakuanModel {
  final String idPerlakuan;
  final DateTime tanggalPerlakuan;
  final String? idJadwal; // relasi ke jadwal jika ada
  final String jenisPerlakuan;
  final String? areaTanaman;
  final String? bahanDigunakan;
  final double? jumlahDigunakan;
  final String? satuan;
  final String? metode;
  final String? kondisiCuaca;
  final int? ratingEfektivitas; // 1-5 rating efektivitas
  final String? catatan;
  final String dicatatOleh;
  final DateTime dicatatPada;

  CatatanPerlakuanModel({
    required this.idPerlakuan,
    required this.tanggalPerlakuan,
    this.idJadwal,
    required this.jenisPerlakuan,
    this.areaTanaman,
    this.bahanDigunakan,
    this.jumlahDigunakan,
    this.satuan,
    this.metode,
    this.kondisiCuaca,
    this.ratingEfektivitas,
    this.catatan,
    required this.dicatatOleh,
    required this.dicatatPada,
  });

  // Factory constructor untuk membuat instance dari Firestore
  factory CatatanPerlakuanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CatatanPerlakuanModel(
      idPerlakuan: doc.id,
      tanggalPerlakuan: (data['tanggal_perlakuan'] as Timestamp).toDate(),
      idJadwal: data['id_jadwal'],
      jenisPerlakuan: data['jenis_perlakuan'] ?? '',
      areaTanaman: data['area_tanaman'],
      bahanDigunakan: data['bahan_digunakan'],
      jumlahDigunakan: data['jumlah_digunakan']?.toDouble(),
      satuan: data['satuan'],
      metode: data['metode'],
      kondisiCuaca: data['kondisi_cuaca'],
      ratingEfektivitas: data['rating_efektivitas'],
      catatan: data['catatan'],
      dicatatOleh: data['dicatat_oleh'] ?? '',
      dicatatPada: (data['dicatat_pada'] as Timestamp).toDate(),
    );
  }

  // Method untuk mengkonversi ke Map untuk Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'tanggal_perlakuan': Timestamp.fromDate(tanggalPerlakuan),
      'id_jadwal': idJadwal,
      'jenis_perlakuan': jenisPerlakuan,
      'area_tanaman': areaTanaman,
      'bahan_digunakan': bahanDigunakan,
      'jumlah_digunakan': jumlahDigunakan,
      'satuan': satuan,
      'metode': metode,
      'kondisi_cuaca': kondisiCuaca,
      'rating_efektivitas': ratingEfektivitas,
      'catatan': catatan,
      'dicatat_oleh': dicatatOleh,
      'dicatat_pada': Timestamp.fromDate(dicatatPada),
    };
  }

  // Method untuk membuat copy dengan perubahan
  CatatanPerlakuanModel copyWith({
    String? idPerlakuan,
    DateTime? tanggalPerlakuan,
    String? idJadwal,
    String? jenisPerlakuan,
    String? areaTanaman,
    String? bahanDigunakan,
    double? jumlahDigunakan,
    String? satuan,
    String? metode,
    String? kondisiCuaca,
    int? ratingEfektivitas,
    String? catatan,
    String? dicatatOleh,
    DateTime? dicatatPada,
  }) {
    return CatatanPerlakuanModel(
      idPerlakuan: idPerlakuan ?? this.idPerlakuan,
      tanggalPerlakuan: tanggalPerlakuan ?? this.tanggalPerlakuan,
      idJadwal: idJadwal ?? this.idJadwal,
      jenisPerlakuan: jenisPerlakuan ?? this.jenisPerlakuan,
      areaTanaman: areaTanaman ?? this.areaTanaman,
      bahanDigunakan: bahanDigunakan ?? this.bahanDigunakan,
      jumlahDigunakan: jumlahDigunakan ?? this.jumlahDigunakan,
      satuan: satuan ?? this.satuan,
      metode: metode ?? this.metode,
      kondisiCuaca: kondisiCuaca ?? this.kondisiCuaca,
      ratingEfektivitas: ratingEfektivitas ?? this.ratingEfektivitas,
      catatan: catatan ?? this.catatan,
      dicatatOleh: dicatatOleh ?? this.dicatatOleh,
      dicatatPada: dicatatPada ?? this.dicatatPada,
    );
  }

  // Method untuk validasi data
  String? validate() {
    if (jenisPerlakuan.isEmpty) {
      return 'Jenis perlakuan harus diisi';
    }
    if (dicatatOleh.isEmpty) {
      return 'Pencatat harus diisi';
    }
    if (ratingEfektivitas != null && (ratingEfektivitas! < 1 || ratingEfektivitas! > 5)) {
      return 'Rating efektivitas harus antara 1-5';
    }
    if (jumlahDigunakan != null && jumlahDigunakan! < 0) {
      return 'Jumlah yang digunakan tidak boleh negatif';
    }
    return null;
  }

  // Format display methods
  String get formattedTanggalPerlakuan {
    return '${tanggalPerlakuan.day.toString().padLeft(2, '0')}/${tanggalPerlakuan.month.toString().padLeft(2, '0')}/${tanggalPerlakuan.year}';
  }

  String get formattedDicatatPada {
    return '${dicatatPada.day.toString().padLeft(2, '0')}/${dicatatPada.month.toString().padLeft(2, '0')}/${dicatatPada.year} ${dicatatPada.hour.toString().padLeft(2, '0')}:${dicatatPada.minute.toString().padLeft(2, '0')}';
  }

  String get formattedJumlahDigunakan {
    if (jumlahDigunakan == null) return '-';
    return '${jumlahDigunakan!.toStringAsFixed(jumlahDigunakan! % 1 == 0 ? 0 : 2)} ${satuan ?? ''}'.trim();
  }

  String get displayAreaTanaman {
    return areaTanaman?.isNotEmpty == true ? areaTanaman! : 'Tidak Ditentukan';
  }

  String get displayBahanDigunakan {
    return bahanDigunakan?.isNotEmpty == true ? bahanDigunakan! : 'Tidak Ditentukan';
  }

  String get displayMetode {
    return metode?.isNotEmpty == true ? metode! : 'Tidak Ditentukan';
  }

  String get displayKondisiCuaca {
    return kondisiCuaca?.isNotEmpty == true ? kondisiCuaca! : 'Tidak Ditentukan';
  }

  String get displayCatatan {
    return catatan?.isNotEmpty == true ? catatan! : 'Tidak ada catatan';
  }

  // Static methods untuk template data
  static List<String> getJenisPerlakuanOptions() {
    return [
      'Pemupukan',
      'Penyiraman',
      'Penyemprotan Pestisida',
      'Penyiangan',
      'Pemangkasan',
      'Penggemburan Tanah',
      'Mulching',
      'Transplanting',
      'Harvesting',
      'Lainnya',
    ];
  }

  static List<String> getAreaTanamanOptions() {
    return [
      'Greenhouse A',
      'Greenhouse B',
      'Greenhouse C',
      'Lahan Terbuka 1',
      'Lahan Terbuka 2',
      'Lahan Terbuka 3',
      'Nursery',
      'Kebun Sayur',
      'Kebun Buah',
      'Area Kompos',
    ];
  }

  static List<String> getMetodeOptions() {
    return [
      'Manual',
      'Sprayer',
      'Drip Irrigation',
      'Sprinkler',
      'Foliar Application',
      'Soil Application',
      'Broadcasting',
      'Side Dressing',
      'Fertigation',
      'Organic Method',
    ];
  }

  static List<String> getKondisiCuacaOptions() {
    return [
      'Cerah',
      'Berawan',
      'Mendung',
      'Hujan Ringan',
      'Hujan Sedang',
      'Hujan Lebat',
      'Berangin',
      'Panas',
      'Lembab',
      'Kering',
    ];
  }

  static List<String> getSatuanOptions() {
    return [
      'kg',
      'gram',
      'liter',
      'ml',
      'ton',
      'karung',
      'botol',
      'kaleng',
      'ember',
      'gelas',
    ];
  }

  // Helper methods untuk UI
  static Color getRatingColor(int? rating) {
    if (rating == null) return Colors.grey;
    switch (rating) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  static String getRatingText(int? rating) {
    if (rating == null) return 'Belum Dinilai';
    switch (rating) {
      case 1:
        return 'Sangat Buruk';
      case 2:
        return 'Buruk';
      case 3:
        return 'Cukup';
      case 4:
        return 'Baik';
      case 5:
        return 'Sangat Baik';
      default:
        return 'Tidak Valid';
    }
  }

  static IconData getRatingIcon(int? rating) {
    if (rating == null) return Icons.help_outline;
    switch (rating) {
      case 1:
        return Icons.sentiment_very_dissatisfied;
      case 2:
        return Icons.sentiment_dissatisfied;
      case 3:
        return Icons.sentiment_neutral;
      case 4:
        return Icons.sentiment_satisfied;
      case 5:
        return Icons.sentiment_very_satisfied;
      default:
        return Icons.help_outline;
    }
  }

  // Method untuk format display
  String getDisplayTitle() {
    return '$jenisPerlakuan - $formattedTanggalPerlakuan';
  }

  String getDisplaySubtitle() {
    final parts = <String>[];
    if (areaTanaman?.isNotEmpty == true) parts.add('Area: $areaTanaman');
    if (bahanDigunakan?.isNotEmpty == true) parts.add('Bahan: $bahanDigunakan');
    if (ratingEfektivitas != null) parts.add('Rating: ${getRatingText(ratingEfektivitas)}');
    return parts.join(' • ');
  }

  // Method untuk mendapatkan prioritas berdasarkan rating
  int getPriority() {
    if (ratingEfektivitas == null) return 3; // Medium priority untuk yang belum dinilai
    if (ratingEfektivitas! <= 2) return 1; // High priority untuk rating rendah
    if (ratingEfektivitas! >= 4) return 5; // Low priority untuk rating tinggi
    return 3; // Medium priority untuk rating sedang
  }

  // Method untuk cek apakah perlakuan efektif
  bool get isEfektif {
    return ratingEfektivitas != null && ratingEfektivitas! >= 4;
  }

  // Method untuk cek apakah perlakuan perlu perhatian
  bool get perluPerhatian {
    return ratingEfektivitas != null && ratingEfektivitas! <= 2;
  }

  // Method untuk mendapatkan warna status
  Color getStatusColor() {
    return getRatingColor(ratingEfektivitas);
  }

  // Method untuk mendapatkan icon status
  IconData getStatusIcon() {
    return getRatingIcon(ratingEfektivitas);
  }

  @override
  String toString() {
    return 'CatatanPerlakuanModel(idPerlakuan: $idPerlakuan, tanggalPerlakuan: $tanggalPerlakuan, jenisPerlakuan: $jenisPerlakuan)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CatatanPerlakuanModel && other.idPerlakuan == idPerlakuan;
  }

  @override
  int get hashCode => idPerlakuan.hashCode;
}