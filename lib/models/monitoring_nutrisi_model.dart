import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'tandon_monitoring_data_model.dart';

class MonitoringNutrisiModel {
  final String id;
  final String nama; // Nama paket monitoring
  final DateTime tanggalMonitoring;
  final String? idPembenihan; // Reference to catatan_pembenihan (optional)
  final String? idPenanaman; // Reference to penanaman_sayur (optional)
  final List<TandonMonitoringDataModel>? tandonData; // Data monitoring per tandon
  final String dicatatOleh; // Required - auto filled from logged in user
  final DateTime dicatatPada;

  MonitoringNutrisiModel({
    required this.id,
    required this.nama,
    required this.tanggalMonitoring,
    this.idPembenihan,
    this.idPenanaman,
    this.tandonData,
    required this.dicatatOleh,
    required this.dicatatPada,
  });

  // Convert from Firestore document
  factory MonitoringNutrisiModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    List<TandonMonitoringDataModel>? tandonDataList;
    if (data['tandon_data'] != null) {
      tandonDataList = (data['tandon_data'] as List)
          .map((item) => TandonMonitoringDataModel.fromMap(item as Map<String, dynamic>))
          .toList();
    }
    
    return MonitoringNutrisiModel(
      id: doc.id,
      nama: data['nama'] ?? '',
      tanggalMonitoring: (data['tanggal_monitoring'] as Timestamp).toDate(),
      idPembenihan: data['id_pembenihan'],
      idPenanaman: data['id_penanaman'],
      tandonData: tandonDataList,
      dicatatOleh: data['dicatat_oleh'] ?? '',
      dicatatPada: (data['dicatat_pada'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'nama': nama,
      'tanggal_monitoring': Timestamp.fromDate(tanggalMonitoring),
      'id_pembenihan': idPembenihan,
      'id_penanaman': idPenanaman,
      'tandon_data': tandonData?.map((data) => data.toMap()).toList(),
      'dicatat_oleh': dicatatOleh,
      'dicatat_pada': Timestamp.fromDate(dicatatPada),
    };
  }

  // Create a copy with updated fields
  MonitoringNutrisiModel copyWith({
    String? id,
    String? nama,
    DateTime? tanggalMonitoring,
    String? idPembenihan,
    String? idPenanaman,
    List<TandonMonitoringDataModel>? tandonData,
    String? dicatatOleh,
    DateTime? dicatatPada,
  }) {
    return MonitoringNutrisiModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      tanggalMonitoring: tanggalMonitoring ?? this.tanggalMonitoring,
      idPembenihan: idPembenihan ?? this.idPembenihan,
      idPenanaman: idPenanaman ?? this.idPenanaman,
      tandonData: tandonData ?? this.tandonData,
      dicatatOleh: dicatatOleh ?? this.dicatatOleh,
      dicatatPada: dicatatPada ?? this.dicatatPada,
    );
  }

  @override
  String toString() {
    return 'MonitoringNutrisiModel(id: $id, nama: $nama, tanggalMonitoring: $tanggalMonitoring, idPembenihan: $idPembenihan, idPenanaman: $idPenanaman, tandonData: $tandonData, dicatatOleh: $dicatatOleh, dicatatPada: $dicatatPada)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MonitoringNutrisiModel &&
        other.id == id &&
        other.nama == nama &&
        other.tanggalMonitoring == tanggalMonitoring &&
        other.idPembenihan == idPembenihan &&
        other.idPenanaman == idPenanaman &&
        listEquals(other.tandonData, tandonData) &&
        other.dicatatOleh == dicatatOleh &&
        other.dicatatPada == dicatatPada;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        nama.hashCode ^
        tanggalMonitoring.hashCode ^
        idPembenihan.hashCode ^
        idPenanaman.hashCode ^
        (tandonData != null ? tandonData!.fold(0, (prev, element) => prev ^ element.hashCode) : 0) ^
        dicatatOleh.hashCode ^
        dicatatPada.hashCode;
  }
}