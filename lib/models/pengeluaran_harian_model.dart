import 'package:cloud_firestore/cloud_firestore.dart';

class PengeluaranHarianModel {
  final String id;
  final DateTime tanggalPengeluaran;
  final String idKategori;
  final String keterangan;
  final double jumlah;
  final String? nomorNota;
  final String? pemasok;
  final String? catatan;
  final String? dicatatOleh;
  final DateTime dicatatPada;

  PengeluaranHarianModel({
    required this.id,
    required this.tanggalPengeluaran,
    required this.idKategori,
    required this.keterangan,
    required this.jumlah,
    this.nomorNota,
    this.pemasok,
    this.catatan,
    this.dicatatOleh,
    required this.dicatatPada,
  });

  // Convert from Firestore document
  factory PengeluaranHarianModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PengeluaranHarianModel(
      id: doc.id,
      tanggalPengeluaran: (data['tanggal_pengeluaran'] as Timestamp).toDate(),
      idKategori: data['id_kategori'] ?? '',
      keterangan: data['keterangan'] ?? '',
      jumlah: (data['jumlah'] ?? 0).toDouble(),
      nomorNota: data['nomor_nota'],
      pemasok: data['pemasok'],
      catatan: data['catatan'],
      dicatatOleh: data['dicatat_oleh'],
      dicatatPada: (data['dicatat_pada'] as Timestamp).toDate(),
    );
  }

  // Convert from Map
  factory PengeluaranHarianModel.fromMap(Map<String, dynamic> map) {
    return PengeluaranHarianModel(
      id: map['id'] ?? '',
      tanggalPengeluaran: map['tanggal_pengeluaran'] is Timestamp
          ? (map['tanggal_pengeluaran'] as Timestamp).toDate()
          : DateTime.parse(map['tanggal_pengeluaran']),
      idKategori: map['id_kategori'] ?? '',
      keterangan: map['keterangan'] ?? '',
      jumlah: (map['jumlah'] ?? 0).toDouble(),
      nomorNota: map['nomor_nota'],
      pemasok: map['pemasok'],
      catatan: map['catatan'],
      dicatatOleh: map['dicatat_oleh'],
      dicatatPada: map['dicatat_pada'] is Timestamp
          ? (map['dicatat_pada'] as Timestamp).toDate()
          : DateTime.parse(map['dicatat_pada']),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'tanggal_pengeluaran': Timestamp.fromDate(tanggalPengeluaran),
      'id_kategori': idKategori,
      'keterangan': keterangan,
      'jumlah': jumlah,
      'nomor_nota': nomorNota,
      'pemasok': pemasok,
      'catatan': catatan,
      'dicatat_oleh': dicatatOleh,
      'dicatat_pada': Timestamp.fromDate(dicatatPada),
    };
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tanggal_pengeluaran': tanggalPengeluaran.toIso8601String(),
      'id_kategori': idKategori,
      'keterangan': keterangan,
      'jumlah': jumlah,
      'nomor_nota': nomorNota,
      'pemasok': pemasok,
      'catatan': catatan,
      'dicatat_oleh': dicatatOleh,
      'dicatat_pada': dicatatPada.toIso8601String(),
    };
  }

  // Create a copy with updated fields
  PengeluaranHarianModel copyWith({
    String? id,
    DateTime? tanggalPengeluaran,
    String? idKategori,
    String? keterangan,
    double? jumlah,
    String? nomorNota,
    String? pemasok,
    String? catatan,
    String? dicatatOleh,
    DateTime? dicatatPada,
  }) {
    return PengeluaranHarianModel(
      id: id ?? this.id,
      tanggalPengeluaran: tanggalPengeluaran ?? this.tanggalPengeluaran,
      idKategori: idKategori ?? this.idKategori,
      keterangan: keterangan ?? this.keterangan,
      jumlah: jumlah ?? this.jumlah,
      nomorNota: nomorNota ?? this.nomorNota,
      pemasok: pemasok ?? this.pemasok,
      catatan: catatan ?? this.catatan,
      dicatatOleh: dicatatOleh ?? this.dicatatOleh,
      dicatatPada: dicatatPada ?? this.dicatatPada,
    );
  }

  @override
  String toString() {
    return 'PengeluaranHarianModel(id: $id, tanggalPengeluaran: $tanggalPengeluaran, idKategori: $idKategori, keterangan: $keterangan, jumlah: $jumlah, nomorNota: $nomorNota, pemasok: $pemasok, catatan: $catatan, dicatatOleh: $dicatatOleh, dicatatPada: $dicatatPada)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PengeluaranHarianModel &&
        other.id == id &&
        other.tanggalPengeluaran == tanggalPengeluaran &&
        other.idKategori == idKategori &&
        other.keterangan == keterangan &&
        other.jumlah == jumlah &&
        other.nomorNota == nomorNota &&
        other.pemasok == pemasok &&
        other.catatan == catatan &&
        other.dicatatOleh == dicatatOleh &&
        other.dicatatPada == dicatatPada;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        tanggalPengeluaran.hashCode ^
        idKategori.hashCode ^
        keterangan.hashCode ^
        jumlah.hashCode ^
        nomorNota.hashCode ^
        pemasok.hashCode ^
        catatan.hashCode ^
        dicatatOleh.hashCode ^
        dicatatPada.hashCode;
  }
}