import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RekapBenihMingguanModel {
  final String? idRekap;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final String jenisBenih;
  final int jumlahNampan;
  final String? catatan;
  final String dicatatOleh;
  final DateTime dicatatPada;

  RekapBenihMingguanModel({
    this.idRekap,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.jenisBenih,
    required this.jumlahNampan,
    this.catatan,
    required this.dicatatOleh,
    required this.dicatatPada,
  });

  factory RekapBenihMingguanModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,
      ) {
    final data = snapshot.data();
    return RekapBenihMingguanModel(
      idRekap: snapshot.id,
      tanggalMulai: (data?['tanggal_mulai'] as Timestamp).toDate(),
      tanggalSelesai: (data?['tanggal_selesai'] as Timestamp).toDate(),
      jenisBenih: data?['jenis_benih'],
      jumlahNampan: data?['jumlah_nampan'] as int,
      catatan: data?['catatan'],
      dicatatOleh: data?['dicatat_oleh'],
      dicatatPada: (data?['dicatat_pada'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "tanggal_mulai": Timestamp.fromDate(tanggalMulai),
      "tanggal_selesai": Timestamp.fromDate(tanggalSelesai),
      "jenis_benih": jenisBenih,
      "jumlah_nampan": jumlahNampan,
      if (catatan != null) "catatan": catatan,
      "dicatat_oleh": dicatatOleh,
      "dicatat_pada": Timestamp.fromDate(dicatatPada),
    };
  }

  // Alias for toFirestore to match service usage
  Map<String, dynamic> toMap() => toFirestore();

  // Factory method for fromMap to match service usage
  factory RekapBenihMingguanModel.fromMap(Map<String, dynamic> data, String id) {
    return RekapBenihMingguanModel(
      idRekap: id,
      tanggalMulai: (data['tanggal_mulai'] as Timestamp).toDate(),
      tanggalSelesai: (data['tanggal_selesai'] as Timestamp).toDate(),
      jenisBenih: data['jenis_benih'],
      jumlahNampan: data['jumlah_nampan'] as int,
      catatan: data['catatan'],
      dicatatOleh: data['dicatat_oleh'],
      dicatatPada: (data['dicatat_pada'] as Timestamp).toDate(),
    );
  }

  // Method untuk membuat copy dengan perubahan
  RekapBenihMingguanModel copyWith({
    String? idRekap,
    DateTime? tanggalMulai,
    DateTime? tanggalSelesai,
    String? jenisBenih,
    int? jumlahNampan,
    String? catatan,
    String? dicatatOleh,
    DateTime? dicatatPada,
  }) {
    return RekapBenihMingguanModel(
      idRekap: idRekap ?? this.idRekap,
      tanggalMulai: tanggalMulai ?? this.tanggalMulai,
      tanggalSelesai: tanggalSelesai ?? this.tanggalSelesai,
      jenisBenih: jenisBenih ?? this.jenisBenih,
      jumlahNampan: jumlahNampan ?? this.jumlahNampan,
      catatan: catatan ?? this.catatan,
      dicatatOleh: dicatatOleh ?? this.dicatatOleh,
      dicatatPada: dicatatPada ?? this.dicatatPada,
    );
  }

  // Validation method
  String? validate() {
    if (tanggalMulai.isAfter(DateTime.now())) {
      return 'Tanggal mulai tidak boleh di masa depan';
    }
    if (tanggalSelesai.isBefore(tanggalMulai)) {
      return 'Tanggal selesai tidak boleh sebelum tanggal mulai';
    }
    if (jenisBenih.trim().isEmpty) {
      return 'Jenis benih harus diisi';
    }
    if (jumlahNampan <= 0) {
      return 'Jumlah nampan harus lebih dari 0';
    }
    return null;
  }

  // Static methods for template data
  static List<String> getJenisBenihOptions() {
    return [
      'Selada',
      'Romaine',
      'Kangkung',
      'Bayam',
      'Pakcoy',
      'Sawi',
      'Kemangi',
      'Lettuce',
    ];
  }

  // Helper methods for UI
  String get formattedPeriode {
    return '${tanggalMulai.day}/${tanggalMulai.month}/${tanggalMulai.year} - ${tanggalSelesai.day}/${tanggalSelesai.month}/${tanggalSelesai.year}';
  }

  String get formattedJumlahNampan {
    return '$jumlahNampan nampan';
  }

  Color getJenisBenihColor() {
    switch (jenisBenih.toLowerCase()) {
      case 'selada':
        return Colors.green;
      case 'romaine':
        return Colors.lightGreen;
      case 'kangkung':
        return Colors.teal;
      case 'bayam':
        return Colors.green.shade700;
      case 'pakcoy':
        return Colors.lime;
      case 'sawi':
        return Colors.yellow.shade700;
      case 'kemangi':
        return Colors.purple;
      case 'lettuce':
        return Colors.green.shade300;
      default:
        return Colors.grey;
    }
  }

  @override
  String toString() {
    return 'RekapBenihMingguanModel(idRekap: $idRekap, jenisBenih: $jenisBenih, jumlahNampan: $jumlahNampan, periode: $formattedPeriode)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RekapBenihMingguanModel &&
        other.idRekap == idRekap &&
        other.jenisBenih == jenisBenih &&
        other.jumlahNampan == jumlahNampan;
  }

  @override
  int get hashCode {
    return idRekap.hashCode ^
        jenisBenih.hashCode ^
        jumlahNampan.hashCode;
  }
}