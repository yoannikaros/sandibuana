import 'package:cloud_firestore/cloud_firestore.dart';

class TandonAirModel {
  final String id;
  final String kodeTandon;
  final String? namaTandon;
  final double? kapasitas; // liter
  final String? lokasi;
  final bool aktif;

  TandonAirModel({
    required this.id,
    required this.kodeTandon,
    this.namaTandon,
    this.kapasitas,
    this.lokasi,
    this.aktif = true,
  });

  // Convert from Firestore document
  factory TandonAirModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TandonAirModel(
      id: doc.id,
      kodeTandon: data['kode_tandon'] ?? '',
      namaTandon: data['nama_tandon'],
      kapasitas: data['kapasitas']?.toDouble(),
      lokasi: data['lokasi'],
      aktif: data['aktif'] ?? true,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'kode_tandon': kodeTandon,
      'nama_tandon': namaTandon,
      'kapasitas': kapasitas,
      'lokasi': lokasi,
      'aktif': aktif,
    };
  }

  // Create a copy with updated fields
  TandonAirModel copyWith({
    String? id,
    String? kodeTandon,
    String? namaTandon,
    double? kapasitas,
    String? lokasi,
    bool? aktif,
  }) {
    return TandonAirModel(
      id: id ?? this.id,
      kodeTandon: kodeTandon ?? this.kodeTandon,
      namaTandon: namaTandon ?? this.namaTandon,
      kapasitas: kapasitas ?? this.kapasitas,
      lokasi: lokasi ?? this.lokasi,
      aktif: aktif ?? this.aktif,
    );
  }

  @override
  String toString() {
    return 'TandonAirModel(id: $id, kodeTandon: $kodeTandon, namaTandon: $namaTandon, kapasitas: $kapasitas, lokasi: $lokasi, aktif: $aktif)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TandonAirModel &&
        other.id == id &&
        other.kodeTandon == kodeTandon &&
        other.namaTandon == namaTandon &&
        other.kapasitas == kapasitas &&
        other.lokasi == lokasi &&
        other.aktif == aktif;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        kodeTandon.hashCode ^
        namaTandon.hashCode ^
        kapasitas.hashCode ^
        lokasi.hashCode ^
        aktif.hashCode;
  }
}