import 'package:cloud_firestore/cloud_firestore.dart';

class TransaksiModel {
  final String id;
  final String idPelanggan;
  final String namaPelanggan;
  final DateTime tanggalBeli;
  final List<TransaksiItemModel> items;
  final double totalHarga;
  final String? informasiLain;
  final DateTime dicatatPada;
  final String dicatatOleh;

  TransaksiModel({
    required this.id,
    required this.idPelanggan,
    required this.namaPelanggan,
    required this.tanggalBeli,
    required this.items,
    required this.totalHarga,
    this.informasiLain,
    required this.dicatatPada,
    required this.dicatatOleh,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_pelanggan': idPelanggan,
      'nama_pelanggan': namaPelanggan,
      'tanggal_beli': tanggalBeli,
      'items': items.map((item) => item.toMap()).toList(),
      'total_harga': totalHarga,
      'informasi_lain': informasiLain,
      'dicatat_pada': dicatatPada,
      'dicatat_oleh': dicatatOleh,
    };
  }

  // Create from Map (Firestore)
  factory TransaksiModel.fromMap(Map<String, dynamic> map) {
    return TransaksiModel(
      id: map['id'] ?? '',
      idPelanggan: map['id_pelanggan'] ?? '',
      namaPelanggan: map['nama_pelanggan'] ?? '',
      tanggalBeli: (map['tanggal_beli'] as Timestamp).toDate(),
      items: (map['items'] as List<dynamic>)
          .map((item) => TransaksiItemModel.fromMap(item))
          .toList(),
      totalHarga: (map['total_harga'] ?? 0.0).toDouble(),
      informasiLain: map['informasi_lain'],
      dicatatPada: (map['dicatat_pada'] as Timestamp).toDate(),
      dicatatOleh: map['dicatat_oleh'] ?? '',
    );
  }
}

class TransaksiItemModel {
  final String idPenanaman;
  final String jenisSayur;
  final double harga;
  final double jumlah;
  final String satuan;
  final double totalHarga;

  TransaksiItemModel({
    required this.idPenanaman,
    required this.jenisSayur,
    required this.harga,
    required this.jumlah,
    required this.satuan,
    required this.totalHarga,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id_penanaman': idPenanaman,
      'jenis_sayur': jenisSayur,
      'harga': harga,
      'jumlah': jumlah,
      'satuan': satuan,
      'total_harga': totalHarga,
    };
  }

  // Create from Map (Firestore)
  factory TransaksiItemModel.fromMap(Map<String, dynamic> map) {
    return TransaksiItemModel(
      idPenanaman: map['id_penanaman'] ?? '',
      jenisSayur: map['jenis_sayur'] ?? '',
      harga: (map['harga'] ?? 0.0).toDouble(),
      jumlah: (map['jumlah'] ?? 0.0).toDouble(),
      satuan: map['satuan'] ?? '',
      totalHarga: (map['total_harga'] ?? 0.0).toDouble(),
    );
  }
}