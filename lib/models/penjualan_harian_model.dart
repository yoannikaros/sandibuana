import 'package:cloud_firestore/cloud_firestore.dart';

class PenjualanHarianModel {
  final String id;
  final DateTime tanggalJual;
  final String idPelanggan;
  final String jenisSayur;
  final double jumlah;
  final String? satuan;
  final double? hargaPerSatuan;
  final double totalHarga;
  final String statusKirim; // pending, terkirim, batal
  final String? catatan;
  final String dicatatOleh;
  final DateTime dicatatPada;

  PenjualanHarianModel({
    required this.id,
    required this.tanggalJual,
    required this.idPelanggan,
    required this.jenisSayur,
    required this.jumlah,
    this.satuan,
    this.hargaPerSatuan,
    required this.totalHarga,
    this.statusKirim = 'pending',
    this.catatan,
    required this.dicatatOleh,
    required this.dicatatPada,
  });

  // Convert from Firestore document
  factory PenjualanHarianModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PenjualanHarianModel(
      id: doc.id,
      tanggalJual: (data['tanggal_jual'] as Timestamp).toDate(),
      idPelanggan: data['id_pelanggan'] ?? '',
      jenisSayur: data['jenis_sayur'] ?? '',
      jumlah: (data['jumlah'] ?? 0).toDouble(),
      satuan: data['satuan'],
      hargaPerSatuan: data['harga_per_satuan']?.toDouble(),
      totalHarga: (data['total_harga'] ?? 0).toDouble(),
      statusKirim: data['status_kirim'] ?? 'pending',
      catatan: data['catatan'],
      dicatatOleh: data['dicatat_oleh'] ?? '',
      dicatatPada: (data['dicatat_pada'] as Timestamp).toDate(),
    );
  }

  // Convert from Map
  factory PenjualanHarianModel.fromMap(Map<String, dynamic> map) {
    return PenjualanHarianModel(
      id: map['id'] ?? '',
      tanggalJual: map['tanggal_jual'] is Timestamp
          ? (map['tanggal_jual'] as Timestamp).toDate()
          : DateTime.parse(map['tanggal_jual']),
      idPelanggan: map['id_pelanggan'] ?? '',
      jenisSayur: map['jenis_sayur'] ?? '',
      jumlah: (map['jumlah'] ?? 0).toDouble(),
      satuan: map['satuan'],
      hargaPerSatuan: map['harga_per_satuan']?.toDouble(),
      totalHarga: (map['total_harga'] ?? 0).toDouble(),
      statusKirim: map['status_kirim'] ?? 'pending',
      catatan: map['catatan'],
      dicatatOleh: map['dicatat_oleh'] ?? '',
      dicatatPada: map['dicatat_pada'] is Timestamp
          ? (map['dicatat_pada'] as Timestamp).toDate()
          : DateTime.parse(map['dicatat_pada']),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'tanggal_jual': Timestamp.fromDate(tanggalJual),
      'id_pelanggan': idPelanggan,
      'jenis_sayur': jenisSayur,
      'jumlah': jumlah,
      'satuan': satuan,
      'harga_per_satuan': hargaPerSatuan,
      'total_harga': totalHarga,
      'status_kirim': statusKirim,
      'catatan': catatan,
      'dicatat_oleh': dicatatOleh,
      'dicatat_pada': Timestamp.fromDate(dicatatPada),
    };
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tanggal_jual': tanggalJual.toIso8601String(),
      'id_pelanggan': idPelanggan,
      'jenis_sayur': jenisSayur,
      'jumlah': jumlah,
      'satuan': satuan,
      'harga_per_satuan': hargaPerSatuan,
      'total_harga': totalHarga,
      'status_kirim': statusKirim,
      'catatan': catatan,
      'dicatat_oleh': dicatatOleh,
      'dicatat_pada': dicatatPada.toIso8601String(),
    };
  }

  // Validation
  String? validate() {
    if (jenisSayur.trim().isEmpty) {
      return 'Jenis sayur harus diisi';
    }
    if (jumlah <= 0) {
      return 'Jumlah harus lebih dari 0';
    }
    if (totalHarga <= 0) {
      return 'Total harga harus lebih dari 0';
    }
    if (idPelanggan.trim().isEmpty) {
      return 'Pelanggan harus dipilih';
    }
    if (dicatatOleh.trim().isEmpty) {
      return 'Pencatat harus diisi';
    }
    return null;
  }

  // Create a copy with updated fields
  PenjualanHarianModel copyWith({
    String? id,
    DateTime? tanggalJual,
    String? idPelanggan,
    String? jenisSayur,
    double? jumlah,
    String? satuan,
    double? hargaPerSatuan,
    double? totalHarga,
    String? statusKirim,
    String? catatan,
    String? dicatatOleh,
    DateTime? dicatatPada,
  }) {
    return PenjualanHarianModel(
      id: id ?? this.id,
      tanggalJual: tanggalJual ?? this.tanggalJual,
      idPelanggan: idPelanggan ?? this.idPelanggan,
      jenisSayur: jenisSayur ?? this.jenisSayur,
      jumlah: jumlah ?? this.jumlah,
      satuan: satuan ?? this.satuan,
      hargaPerSatuan: hargaPerSatuan ?? this.hargaPerSatuan,
      totalHarga: totalHarga ?? this.totalHarga,
      statusKirim: statusKirim ?? this.statusKirim,
      catatan: catatan ?? this.catatan,
      dicatatOleh: dicatatOleh ?? this.dicatatOleh,
      dicatatPada: dicatatPada ?? this.dicatatPada,
    );
  }

  // Helper getters for display
  String get formattedTanggalJual =>
      '${tanggalJual.day.toString().padLeft(2, '0')}/${tanggalJual.month.toString().padLeft(2, '0')}/${tanggalJual.year}';

  String get formattedJumlah =>
      '${jumlah.toStringAsFixed(jumlah.truncateToDouble() == jumlah ? 0 : 2)} ${satuan ?? ''}';

  String get formattedHargaPerSatuan => hargaPerSatuan != null
      ? 'Rp ${hargaPerSatuan!.toStringAsFixed(0)}'
      : '-';

  String get formattedTotalHarga => 'Rp ${totalHarga.toStringAsFixed(0)}';

  String get statusKirimDisplay {
    switch (statusKirim) {
      case 'pending':
        return 'Menunggu';
      case 'terkirim':
        return 'Terkirim';
      case 'batal':
        return 'Dibatal';
      default:
        return statusKirim;
    }
  }

  // Business logic helpers
  bool get isPending => statusKirim == 'pending';
  bool get isTerkirim => statusKirim == 'terkirim';
  bool get isBatal => statusKirim == 'batal';

  @override
  String toString() {
    return 'PenjualanHarianModel(id: $id, tanggalJual: $tanggalJual, idPelanggan: $idPelanggan, jenisSayur: $jenisSayur, jumlah: $jumlah, totalHarga: $totalHarga, statusKirim: $statusKirim)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PenjualanHarianModel &&
        other.id == id &&
        other.tanggalJual == tanggalJual &&
        other.idPelanggan == idPelanggan &&
        other.jenisSayur == jenisSayur &&
        other.jumlah == jumlah &&
        other.satuan == satuan &&
        other.hargaPerSatuan == hargaPerSatuan &&
        other.totalHarga == totalHarga &&
        other.statusKirim == statusKirim &&
        other.catatan == catatan &&
        other.dicatatOleh == dicatatOleh &&
        other.dicatatPada == dicatatPada;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        tanggalJual.hashCode ^
        idPelanggan.hashCode ^
        jenisSayur.hashCode ^
        jumlah.hashCode ^
        satuan.hashCode ^
        hargaPerSatuan.hashCode ^
        totalHarga.hashCode ^
        statusKirim.hashCode ^
        catatan.hashCode ^
        dicatatOleh.hashCode ^
        dicatatPada.hashCode;
  }
}