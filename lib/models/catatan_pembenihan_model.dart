import 'package:cloud_firestore/cloud_firestore.dart';

class CatatanPembenihanModel {
  final String idPembenihan;
  final DateTime tanggalSemai;
  final String idBenih; // Reference to jenis_benih
  final int jumlah;
  final String? satuan;
  final String? kodeBatch;
  final DateTime? tanggalPanenTarget;
  final String? catatan;
  final String dicatatOleh; // Reference to pengguna
  final DateTime dicatatPada;

  CatatanPembenihanModel({
    required this.idPembenihan,
    required this.tanggalSemai,
    required this.idBenih,
    required this.jumlah,
    this.satuan,
    this.kodeBatch,
    this.tanggalPanenTarget,
    this.catatan,
    required this.dicatatOleh,
    required this.dicatatPada,
  });

  // Factory constructor untuk membuat CatatanPembenihanModel dari Map (Firestore)
  factory CatatanPembenihanModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CatatanPembenihanModel(
      idPembenihan: documentId,
      tanggalSemai: map['tanggal_semai']?.toDate() ?? DateTime.now(),
      idBenih: map['id_benih'] ?? '',
      jumlah: map['jumlah']?.toInt() ?? 0,
      satuan: map['satuan'],
      kodeBatch: map['kode_batch'],
      tanggalPanenTarget: map['tanggal_panen_target']?.toDate(),
      catatan: map['catatan'],
      dicatatOleh: map['dicatat_oleh'] ?? '',
      dicatatPada: map['dicatat_pada']?.toDate() ?? DateTime.now(),
    );
  }

  // Method untuk mengkonversi CatatanPembenihanModel ke Map (untuk Firestore)
  Map<String, dynamic> toMap() {
    return {
      'tanggal_semai': Timestamp.fromDate(tanggalSemai),
      'id_benih': idBenih,
      'jumlah': jumlah,
      'satuan': satuan,
      'kode_batch': kodeBatch,
      'tanggal_panen_target': tanggalPanenTarget != null ? Timestamp.fromDate(tanggalPanenTarget!) : null,
      'catatan': catatan,
      'dicatat_oleh': dicatatOleh,
      'dicatat_pada': Timestamp.fromDate(dicatatPada),
    };
  }

  // Method untuk membuat copy dengan perubahan
  CatatanPembenihanModel copyWith({
    String? idPembenihan,
    DateTime? tanggalSemai,
    String? idBenih,
    int? jumlah,
    String? satuan,
    String? kodeBatch,
    DateTime? tanggalPanenTarget,
    String? catatan,
    String? dicatatOleh,
    DateTime? dicatatPada,
  }) {
    return CatatanPembenihanModel(
      idPembenihan: idPembenihan ?? this.idPembenihan,
      tanggalSemai: tanggalSemai ?? this.tanggalSemai,
      idBenih: idBenih ?? this.idBenih,
      jumlah: jumlah ?? this.jumlah,
      satuan: satuan ?? this.satuan,
      kodeBatch: kodeBatch ?? this.kodeBatch,
      tanggalPanenTarget: tanggalPanenTarget ?? this.tanggalPanenTarget,
      catatan: catatan ?? this.catatan,
      dicatatOleh: dicatatOleh ?? this.dicatatOleh,
      dicatatPada: dicatatPada ?? this.dicatatPada,
    );
  }

  @override
  String toString() {
    return 'CatatanPembenihanModel(idPembenihan: $idPembenihan, tanggalSemai: $tanggalSemai, idBenih: $idBenih, jumlah: $jumlah, kodeBatch: $kodeBatch)';
  }
}