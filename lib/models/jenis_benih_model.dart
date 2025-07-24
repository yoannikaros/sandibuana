import 'package:cloud_firestore/cloud_firestore.dart';

class JenisBenihModel {
  final String idBenih;
  final String namaBenih;
  final String? pemasok;
  final double? hargaPerSatuan;
  final String? jenisSatuan;
  final String? ukuranSatuan;
  final bool aktif;
  final DateTime dibuatPada;

  JenisBenihModel({
    required this.idBenih,
    required this.namaBenih,
    this.pemasok,
    this.hargaPerSatuan,
    this.jenisSatuan,
    this.ukuranSatuan,
    required this.aktif,
    required this.dibuatPada,
  });

  // Factory constructor untuk membuat JenisBenihModel dari Map (Firestore)
  factory JenisBenihModel.fromMap(Map<String, dynamic> map, String documentId) {
    return JenisBenihModel(
      idBenih: documentId,
      namaBenih: map['nama_benih'] ?? '',
      pemasok: map['pemasok'],
      hargaPerSatuan: map['harga_per_satuan']?.toDouble(),
      jenisSatuan: map['jenis_satuan'],
      ukuranSatuan: map['ukuran_satuan'],
      aktif: map['aktif'] ?? true,
      dibuatPada: map['dibuat_pada']?.toDate() ?? DateTime.now(),
    );
  }

  // Method untuk mengkonversi JenisBenihModel ke Map (untuk Firestore)
  Map<String, dynamic> toMap() {
    return {
      'nama_benih': namaBenih,
      'pemasok': pemasok,
      'harga_per_satuan': hargaPerSatuan,
      'jenis_satuan': jenisSatuan,
      'ukuran_satuan': ukuranSatuan,
      'aktif': aktif,
      'dibuat_pada': Timestamp.fromDate(dibuatPada),
    };
  }

  // Method untuk membuat copy dengan perubahan
  JenisBenihModel copyWith({
    String? idBenih,
    String? namaBenih,
    String? pemasok,
    double? hargaPerSatuan,
    String? jenisSatuan,
    String? ukuranSatuan,
    bool? aktif,
    DateTime? dibuatPada,
  }) {
    return JenisBenihModel(
      idBenih: idBenih ?? this.idBenih,
      namaBenih: namaBenih ?? this.namaBenih,
      pemasok: pemasok ?? this.pemasok,
      hargaPerSatuan: hargaPerSatuan ?? this.hargaPerSatuan,
      jenisSatuan: jenisSatuan ?? this.jenisSatuan,
      ukuranSatuan: ukuranSatuan ?? this.ukuranSatuan,
      aktif: aktif ?? this.aktif,
      dibuatPada: dibuatPada ?? this.dibuatPada,
    );
  }

  @override
  String toString() {
    return 'JenisBenihModel(idBenih: $idBenih, namaBenih: $namaBenih, pemasok: $pemasok, hargaPerSatuan: $hargaPerSatuan, jenisSatuan: $jenisSatuan, ukuranSatuan: $ukuranSatuan, aktif: $aktif)';
  }
}