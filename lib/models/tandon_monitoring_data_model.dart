import 'package:cloud_firestore/cloud_firestore.dart';

class TandonMonitoringDataModel {
  final String idTandon;
  final String namaTandon;
  final double? nilaiPpm;
  final double? airDitambah; // liter
  final double? nutrisiDitambah; // ml atau gram
  final double? tingkatPh;
  final double? suhuAir;
  final String? catatan;

  TandonMonitoringDataModel({
    required this.idTandon,
    required this.namaTandon,
    this.nilaiPpm,
    this.airDitambah,
    this.nutrisiDitambah,
    this.tingkatPh,
    this.suhuAir,
    this.catatan,
  });

  // Convert from Map
  factory TandonMonitoringDataModel.fromMap(Map<String, dynamic> data) {
    return TandonMonitoringDataModel(
      idTandon: data['id_tandon'] ?? '',
      namaTandon: data['nama_tandon'] ?? '',
      nilaiPpm: data['nilai_ppm']?.toDouble(),
      airDitambah: data['air_ditambah']?.toDouble(),
      nutrisiDitambah: data['nutrisi_ditambah']?.toDouble(),
      tingkatPh: data['tingkat_ph']?.toDouble(),
      suhuAir: data['suhu_air']?.toDouble(),
      catatan: data['catatan'],
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id_tandon': idTandon,
      'nama_tandon': namaTandon,
      'nilai_ppm': nilaiPpm,
      'air_ditambah': airDitambah,
      'nutrisi_ditambah': nutrisiDitambah,
      'tingkat_ph': tingkatPh,
      'suhu_air': suhuAir,
      'catatan': catatan,
    };
  }

  // Create a copy with updated fields
  TandonMonitoringDataModel copyWith({
    String? idTandon,
    String? namaTandon,
    double? nilaiPpm,
    double? airDitambah,
    double? nutrisiDitambah,
    double? tingkatPh,
    double? suhuAir,
    String? catatan,
  }) {
    return TandonMonitoringDataModel(
      idTandon: idTandon ?? this.idTandon,
      namaTandon: namaTandon ?? this.namaTandon,
      nilaiPpm: nilaiPpm ?? this.nilaiPpm,
      airDitambah: airDitambah ?? this.airDitambah,
      nutrisiDitambah: nutrisiDitambah ?? this.nutrisiDitambah,
      tingkatPh: tingkatPh ?? this.tingkatPh,
      suhuAir: suhuAir ?? this.suhuAir,
      catatan: catatan ?? this.catatan,
    );
  }

  @override
  String toString() {
    return 'TandonMonitoringDataModel(idTandon: $idTandon, namaTandon: $namaTandon, nilaiPpm: $nilaiPpm, airDitambah: $airDitambah, nutrisiDitambah: $nutrisiDitambah, tingkatPh: $tingkatPh, suhuAir: $suhuAir, catatan: $catatan)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TandonMonitoringDataModel &&
        other.idTandon == idTandon &&
        other.namaTandon == namaTandon &&
        other.nilaiPpm == nilaiPpm &&
        other.airDitambah == airDitambah &&
        other.nutrisiDitambah == nutrisiDitambah &&
        other.tingkatPh == tingkatPh &&
        other.suhuAir == suhuAir &&
        other.catatan == catatan;
  }

  @override
  int get hashCode {
    return idTandon.hashCode ^
        namaTandon.hashCode ^
        nilaiPpm.hashCode ^
        airDitambah.hashCode ^
        nutrisiDitambah.hashCode ^
        tingkatPh.hashCode ^
        suhuAir.hashCode ^
        catatan.hashCode;
  }
}