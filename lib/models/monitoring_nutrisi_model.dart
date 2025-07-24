import 'package:cloud_firestore/cloud_firestore.dart';

class MonitoringNutrisiModel {
  final String id;
  final DateTime tanggalMonitoring;
  final String? idPembenihan; // Reference to catatan_pembenihan (optional)
  final String? idPenanaman; // Reference to penanaman_sayur (optional)
  final String? idTandon; // Reference to tandon_air (optional)
  final double? nilaiPpm;
  final double? airDitambah; // liter
  final double? nutrisiDitambah; // ml atau gram
  final double? tingkatPh;
  final double? suhuAir;
  final String? catatan;
  final String dicatatOleh; // Required - auto filled from logged in user
  final DateTime dicatatPada;

  MonitoringNutrisiModel({
    required this.id,
    required this.tanggalMonitoring,
    this.idPembenihan,
    this.idPenanaman,
    this.idTandon,
    this.nilaiPpm,
    this.airDitambah,
    this.nutrisiDitambah,
    this.tingkatPh,
    this.suhuAir,
    this.catatan,
    required this.dicatatOleh,
    required this.dicatatPada,
  });

  // Convert from Firestore document
  factory MonitoringNutrisiModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MonitoringNutrisiModel(
      id: doc.id,
      tanggalMonitoring: (data['tanggal_monitoring'] as Timestamp).toDate(),
      idPembenihan: data['id_pembenihan'],
      idPenanaman: data['id_penanaman'],
      idTandon: data['id_tandon'],
      nilaiPpm: data['nilai_ppm']?.toDouble(),
      airDitambah: data['air_ditambah']?.toDouble(),
      nutrisiDitambah: data['nutrisi_ditambah']?.toDouble(),
      tingkatPh: data['tingkat_ph']?.toDouble(),
      suhuAir: data['suhu_air']?.toDouble(),
      catatan: data['catatan'],
      dicatatOleh: data['dicatat_oleh'] ?? '',
      dicatatPada: (data['dicatat_pada'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'tanggal_monitoring': Timestamp.fromDate(tanggalMonitoring),
      'id_pembenihan': idPembenihan,
      'id_penanaman': idPenanaman,
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
    String? idPembenihan,
    String? idPenanaman,
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
      idPembenihan: idPembenihan ?? this.idPembenihan,
      idPenanaman: idPenanaman ?? this.idPenanaman,
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
    return 'MonitoringNutrisiModel(id: $id, tanggalMonitoring: $tanggalMonitoring, idPembenihan: $idPembenihan, idPenanaman: $idPenanaman, idTandon: $idTandon, nilaiPpm: $nilaiPpm, airDitambah: $airDitambah, nutrisiDitambah: $nutrisiDitambah, tingkatPh: $tingkatPh, suhuAir: $suhuAir, catatan: $catatan, dicatatOleh: $dicatatOleh, dicatatPada: $dicatatPada)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MonitoringNutrisiModel &&
        other.id == id &&
        other.tanggalMonitoring == tanggalMonitoring &&
        other.idPembenihan == idPembenihan &&
        other.idPenanaman == idPenanaman &&
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
        idPembenihan.hashCode ^
        idPenanaman.hashCode ^
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