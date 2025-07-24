import 'package:cloud_firestore/cloud_firestore.dart';

class PenggunaanPupukModel {
  final String id;
  final DateTime tanggalPakai;
  final String idPupuk;
  final double jumlahDigunakan;
  final String? satuan; // kg, liter, gram
  final String? catatan;
  final String dicatatOleh;
  final DateTime dicatatPada;

  PenggunaanPupukModel({
    required this.id,
    required this.tanggalPakai,
    required this.idPupuk,
    required this.jumlahDigunakan,
    this.satuan,
    this.catatan,
    required this.dicatatOleh,
    required this.dicatatPada,
  });

  // Convert from Firestore document
  factory PenggunaanPupukModel.fromFirestore(Map<String, dynamic> data, String id) {
    return PenggunaanPupukModel(
      id: id,
      tanggalPakai: (data['tanggal_pakai'] as Timestamp).toDate(),
      idPupuk: data['id_pupuk'] ?? '',
      jumlahDigunakan: (data['jumlah_digunakan'] ?? 0.0).toDouble(),
      satuan: data['satuan'],
      catatan: data['catatan'],
      dicatatOleh: data['dicatat_oleh'] ?? '',
      dicatatPada: (data['dicatat_pada'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'tanggal_pakai': Timestamp.fromDate(tanggalPakai),
      'id_pupuk': idPupuk,
      'jumlah_digunakan': jumlahDigunakan,
      'satuan': satuan,
      'catatan': catatan,
      'dicatat_oleh': dicatatOleh,
      'dicatat_pada': Timestamp.fromDate(dicatatPada),
    };
  }

  // Copy with method for updates
  PenggunaanPupukModel copyWith({
    String? id,
    DateTime? tanggalPakai,
    String? idPupuk,
    double? jumlahDigunakan,
    String? satuan,
    String? catatan,
    String? dicatatOleh,
    DateTime? dicatatPada,
  }) {
    return PenggunaanPupukModel(
      id: id ?? this.id,
      tanggalPakai: tanggalPakai ?? this.tanggalPakai,
      idPupuk: idPupuk ?? this.idPupuk,
      jumlahDigunakan: jumlahDigunakan ?? this.jumlahDigunakan,
      satuan: satuan ?? this.satuan,
      catatan: catatan ?? this.catatan,
      dicatatOleh: dicatatOleh ?? this.dicatatOleh,
      dicatatPada: dicatatPada ?? this.dicatatPada,
    );
  }

  @override
  String toString() {
    return 'PenggunaanPupukModel(id: $id, tanggalPakai: $tanggalPakai, idPupuk: $idPupuk, jumlahDigunakan: $jumlahDigunakan)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PenggunaanPupukModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}