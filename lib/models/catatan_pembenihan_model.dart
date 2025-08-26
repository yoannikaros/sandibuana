import 'package:cloud_firestore/cloud_firestore.dart';

class CatatanPembenihanModel {
  final String idPembenihan;
  final DateTime tanggalPembenihan; // Tanggal pembenihan
  final DateTime tanggalSemai;
  final String idBenih; // Reference to jenis_benih
  final String? idTandon; // Reference to tandon_air
  final String? idPupuk; // Reference to jenis_pupuk
  final String? mediaTanam; // Media tanam yang digunakan
  final int jumlah;
  final String? satuan;
  final String kodeBatch; // Wajib diisi
  final String status; // "berjalan", "panen", "gagal"

  final String? catatan;
  final String dicatatOleh; // Reference to pengguna
  final DateTime dicatatPada;

  CatatanPembenihanModel({
    required this.idPembenihan,
    required this.tanggalPembenihan,
    required this.tanggalSemai,
    required this.idBenih,
    this.idTandon,
    this.idPupuk,
    this.mediaTanam,
    required this.jumlah,
    this.satuan,
    required this.kodeBatch,
    required this.status,

    this.catatan,
    required this.dicatatOleh,
    required this.dicatatPada,
  });

  // Factory constructor untuk membuat CatatanPembenihanModel dari Map (Firestore)
  factory CatatanPembenihanModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CatatanPembenihanModel(
      idPembenihan: documentId,
      tanggalPembenihan: map['tanggal_pembenihan']?.toDate() ?? DateTime.now(),
      tanggalSemai: map['tanggal_semai']?.toDate() ?? DateTime.now(),
      idBenih: map['id_benih'] ?? '',
      idTandon: map['id_tandon'],
      idPupuk: map['id_pupuk'],
      mediaTanam: map['media_tanam'],
      jumlah: map['jumlah']?.toInt() ?? 0,
      satuan: map['satuan'],
      kodeBatch: map['kode_batch'] ?? '',
      status: map['status'] ?? 'berjalan',

      catatan: map['catatan'],
      dicatatOleh: map['dicatat_oleh'] ?? '',
      dicatatPada: map['dicatat_pada']?.toDate() ?? DateTime.now(),
    );
  }

  // Method untuk mengkonversi CatatanPembenihanModel ke Map (untuk Firestore)
  Map<String, dynamic> toMap() {
    return {
      'tanggal_pembenihan': Timestamp.fromDate(tanggalPembenihan),
      'tanggal_semai': Timestamp.fromDate(tanggalSemai),
      'id_benih': idBenih,
      'id_tandon': idTandon,
      'id_pupuk': idPupuk,
      'media_tanam': mediaTanam,
      'jumlah': jumlah,
      'satuan': satuan,
      'kode_batch': kodeBatch,
      'status': status,

      'catatan': catatan,
      'dicatat_oleh': dicatatOleh,
      'dicatat_pada': Timestamp.fromDate(dicatatPada),
    };
  }

  // Method untuk membuat copy dengan perubahan
  CatatanPembenihanModel copyWith({
    String? idPembenihan,
    DateTime? tanggalPembenihan,
    DateTime? tanggalSemai,
    String? idBenih,
    String? idTandon,
    String? idPupuk,
    String? mediaTanam,
    int? jumlah,
    String? satuan,
    String? kodeBatch,
    String? status,

    String? catatan,
    String? dicatatOleh,
    DateTime? dicatatPada,
  }) {
    return CatatanPembenihanModel(
      idPembenihan: idPembenihan ?? this.idPembenihan,
      tanggalPembenihan: tanggalPembenihan ?? this.tanggalPembenihan,
      tanggalSemai: tanggalSemai ?? this.tanggalSemai,
      idBenih: idBenih ?? this.idBenih,
      idTandon: idTandon ?? this.idTandon,
      idPupuk: idPupuk ?? this.idPupuk,
      mediaTanam: mediaTanam ?? this.mediaTanam,
      jumlah: jumlah ?? this.jumlah,
      satuan: satuan ?? this.satuan,
      kodeBatch: kodeBatch ?? this.kodeBatch,
      status: status ?? this.status,

      catatan: catatan ?? this.catatan,
      dicatatOleh: dicatatOleh ?? this.dicatatOleh,
      dicatatPada: dicatatPada ?? this.dicatatPada,
    );
  }

  @override
  String toString() {
    return 'CatatanPembenihanModel(idPembenihan: $idPembenihan, tanggalPembenihan: $tanggalPembenihan, tanggalSemai: $tanggalSemai, idBenih: $idBenih, jumlah: $jumlah, kodeBatch: $kodeBatch, status: $status)';
  }
}