import 'package:cloud_firestore/cloud_firestore.dart';

class MonitoringNutrisiModel {
  final String id;
  final DateTime tanggalMonitoring;
  final String idTandon;
  final double? nilaiPpm;
  final double? airDitambah; // liter
  final double? nutrisiDitambah; // ml atau gram
  final double? tingkatPh;
  final double? suhuAir;
  final String? catatan;
  final String? dicatatOleh;
  final DateTime dicatatPada;

  MonitoringNutrisiModel({
    required this.id,
    required this.tanggalMonitoring,
    required this.idTandon,
    this.nilaiPpm,
    this.airDitambah,
    this.nutrisiDitambah,
    this.tingkatPh,
    this.suhuAir,
    this.catatan,
    this.dicatatOleh,
    required this.dicatatPada,
  });

  // Convert from Firestore document
  factory MonitoringNutrisiModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MonitoringNutrisiModel(
      id: doc.id,
      tanggalMonitoring: (data['tanggal_monitoring'] as Timestamp).toDate(),
      idTandon: data['id_tandon'] ?? '',
      nilaiPpm: data['nilai_ppm']?.toDouble(),
      airDitambah: data['air_ditambah']?.toDouble(),
      nutrisiDitambah: data['nutrisi_ditambah']?.toDouble(),
      tingkatPh: data['tingkat_ph']?.toDouble(),
      suhuAir: data['suhu_air']?.toDouble(),
      catatan: data['catatan'],
      dicatatOleh: data['dicatat_oleh'],
      dicatatPada: (data['dicatat_pada'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'tanggal_monitoring': Timestamp.fromDate(tanggalMonitoring),
      'id_tandon': idTandon,
      'nilai_ppm': nilaiPpm,
      'air_ditambah': airDitambah,
      'nutrisi_ditambah': nutrisiDitambah,
      'tingkat_ph': tingkatPh,
      'suhu_air': suhuAir,
      'catatan': catatan,
      'dicatat_oleh': dicatatOleh,
      'dicatat_pada': Timestamp.fromDate(dicatatPada),
    };
  }

  // Create a copy with updated fields
  MonitoringNutrisiModel copyWith({
    String? id,
    DateTime? tanggalMonitoring,
    String? idTandon,
    double? nilaiPpm,
    double? airDitambah,
    double? nutrisiDitambah,
    double? tingkatPh,
    double? suhuAir,
    String? catatan,
    String? dicatatOleh,
    DateTime? dicatatPada,
  }) {
    return MonitoringNutrisiModel(
      id: id ?? this.id,
      tanggalMonitoring: tanggalMonitoring ?? this.tanggalMonitoring,
      idTandon: idTandon ?? this.idTandon,
      nilaiPpm: nilaiPpm ?? this.nilaiPpm,
      airDitambah: airDitambah ?? this.airDitambah,
      nutrisiDitambah: nutrisiDitambah ?? this.nutrisiDitambah,
      tingkatPh: tingkatPh ?? this.tingkatPh,
      suhuAir: suhuAir ?? this.suhuAir,
      catatan: catatan ?? this.catatan,
      dicatatOleh: dicatatOleh ?? this.dicatatOleh,
      dicatatPada: dicatatPada ?? this.dicatatPada,
    );
  }

  @override
  String toString() {
    return 'MonitoringNutrisiModel(id: $id, tanggalMonitoring: $tanggalMonitoring, idTandon: $idTandon, nilaiPpm: $nilaiPpm, airDitambah: $airDitambah, nutrisiDitambah: $nutrisiDitambah, tingkatPh: $tingkatPh, suhuAir: $suhuAir, catatan: $catatan, dicatatOleh: $dicatatOleh, dicatatPada: $dicatatPada)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MonitoringNutrisiModel &&
        other.id == id &&
        other.tanggalMonitoring == tanggalMonitoring &&
        other.idTandon == idTandon &&
        other.nilaiPpm == nilaiPpm &&
        other.airDitambah == airDitambah &&
        other.nutrisiDitambah == nutrisiDitambah &&
        other.tingkatPh == tingkatPh &&
        other.suhuAir == suhuAir &&
        other.catatan == catatan &&
        other.dicatatOleh == dicatatOleh &&
        other.dicatatPada == dicatatPada;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        tanggalMonitoring.hashCode ^
        idTandon.hashCode ^
        nilaiPpm.hashCode ^
        airDitambah.hashCode ^
        nutrisiDitambah.hashCode ^
        tingkatPh.hashCode ^
        suhuAir.hashCode ^
        catatan.hashCode ^
        dicatatOleh.hashCode ^
        dicatatPada.hashCode;
  }
}