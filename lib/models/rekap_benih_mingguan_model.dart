import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RekapBenihMingguanModel {
  final String? idRekap;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final String? idPembenihan; // Reference to catatan_pembenihan
  final int jumlahNampan;
  final String? catatan;
  final String dicatatOleh;
  final DateTime dicatatPada;

  RekapBenihMingguanModel({
    this.idRekap,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    this.idPembenihan,
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
      idPembenihan: data?['id_pembenihan'],
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
      if (idPembenihan != null) "id_pembenihan": idPembenihan,
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
      idPembenihan: data['id_pembenihan'],
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
    String? idPembenihan,
    int? jumlahNampan,
    String? catatan,
    String? dicatatOleh,
    DateTime? dicatatPada,
  }) {
    return RekapBenihMingguanModel(
      idRekap: idRekap ?? this.idRekap,
      tanggalMulai: tanggalMulai ?? this.tanggalMulai,
      tanggalSelesai: tanggalSelesai ?? this.tanggalSelesai,
      idPembenihan: idPembenihan ?? this.idPembenihan,
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
    if (idPembenihan == null || idPembenihan!.trim().isEmpty) {
      return 'Catatan pembenihan harus dipilih';
    }
    if (jumlahNampan <= 0) {
      return 'Jumlah nampan harus lebih dari 0';
    }
    return null;
  }

  // Helper methods for UI
  String get formattedPeriode {
    return '${tanggalMulai.day}/${tanggalMulai.month}/${tanggalMulai.year} - ${tanggalSelesai.day}/${tanggalSelesai.month}/${tanggalSelesai.year}';
  }

  String get formattedJumlahNampan {
    return '$jumlahNampan nampan';
  }

  @override
  String toString() {
    return 'RekapBenihMingguanModel(idRekap: $idRekap, idPembenihan: $idPembenihan, jumlahNampan: $jumlahNampan, periode: $formattedPeriode)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RekapBenihMingguanModel &&
        other.idRekap == idRekap &&
        other.idPembenihan == idPembenihan &&
        other.jumlahNampan == jumlahNampan;
  }

  @override
  int get hashCode {
    return idRekap.hashCode ^
        idPembenihan.hashCode ^
        jumlahNampan.hashCode;
  }
}