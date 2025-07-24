import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class KategoriPengeluaranModel {
  final String id;
  final String namaKategori;
  final String? keterangan;
  final bool aktif;

  KategoriPengeluaranModel({
    required this.id,
    required this.namaKategori,
    this.keterangan,
    this.aktif = true,
  });

  // Convert from Firestore document
  factory KategoriPengeluaranModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return KategoriPengeluaranModel(
      id: doc.id,
      namaKategori: data['nama_kategori'] ?? '',
      keterangan: data['keterangan'],
      aktif: data['aktif'] ?? true,
    );
  }

  // Convert from Map
  factory KategoriPengeluaranModel.fromMap(Map<String, dynamic> map) {
    return KategoriPengeluaranModel(
      id: map['id'] ?? '',
      namaKategori: map['nama_kategori'] ?? '',
      keterangan: map['keterangan'],
      aktif: map['aktif'] ?? true,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'nama_kategori': namaKategori,
      'keterangan': keterangan,
      'aktif': aktif,
    };
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_kategori': namaKategori,
      'keterangan': keterangan,
      'aktif': aktif,
    };
  }

  // Create a copy with updated fields
  KategoriPengeluaranModel copyWith({
    String? id,
    String? namaKategori,
    String? keterangan,
    bool? aktif,
  }) {
    return KategoriPengeluaranModel(
      id: id ?? this.id,
      namaKategori: namaKategori ?? this.namaKategori,
      keterangan: keterangan ?? this.keterangan,
      aktif: aktif ?? this.aktif,
    );
  }

  // Static list of default categories
  static List<KategoriPengeluaranModel> get defaultKategori => [
    KategoriPengeluaranModel(
      id: 'listrik',
      namaKategori: 'Listrik',
      keterangan: 'Biaya listrik untuk operasional',
    ),
    KategoriPengeluaranModel(
      id: 'bensin',
      namaKategori: 'Bensin',
      keterangan: 'Bahan bakar kendaraan dan genset',
    ),
    KategoriPengeluaranModel(
      id: 'benih',
      namaKategori: 'Benih',
      keterangan: 'Pembelian benih sayuran',
    ),
    KategoriPengeluaranModel(
      id: 'rockwool',
      namaKategori: 'Rockwool',
      keterangan: 'Media tanam rockwool',
    ),
    KategoriPengeluaranModel(
      id: 'pupuk',
      namaKategori: 'Pupuk',
      keterangan: 'Pembelian pupuk dan nutrisi',
    ),
    KategoriPengeluaranModel(
      id: 'lain-lain',
      namaKategori: 'Lain-lain',
      keterangan: 'Pengeluaran operasional lainnya',
    ),
  ];

  @override
  String toString() {
    return 'KategoriPengeluaranModel(id: $id, namaKategori: $namaKategori, keterangan: $keterangan, aktif: $aktif)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KategoriPengeluaranModel &&
        other.id == id &&
        other.namaKategori == namaKategori &&
        other.keterangan == keterangan &&
        other.aktif == aktif;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        namaKategori.hashCode ^
        keterangan.hashCode ^
        aktif.hashCode;
  }

  // Validation method
  String? validate() {
    if (namaKategori.trim().isEmpty) {
      return 'Nama kategori harus diisi';
    }
    if (namaKategori.trim().length < 3) {
      return 'Nama kategori minimal 3 karakter';
    }
    if (namaKategori.trim().length > 50) {
      return 'Nama kategori maksimal 50 karakter';
    }
    return null;
  }

  // Helper methods for UI display
  String get displayTitle => namaKategori;
  
  String get displaySubtitle => keterangan ?? 'Tidak ada keterangan';
  
  Color get statusColor => aktif ? Colors.green : Colors.red;
  
  IconData get statusIcon => aktif ? Icons.check_circle : Icons.cancel;
  
  String get statusText => aktif ? 'Aktif' : 'Tidak Aktif';

  // Get icon for category
  IconData get categoryIcon {
    switch (namaKategori.toLowerCase()) {
      case 'listrik':
        return Icons.electrical_services;
      case 'bensin':
        return Icons.local_gas_station;
      case 'benih':
        return Icons.grass;
      case 'rockwool':
        return Icons.layers;
      case 'pupuk':
        return Icons.eco;
      default:
        return Icons.category;
    }
  }

  // Get color for category
  Color get categoryColor {
    switch (namaKategori.toLowerCase()) {
      case 'listrik':
        return Colors.amber;
      case 'bensin':
        return Colors.red;
      case 'benih':
        return Colors.green;
      case 'rockwool':
        return Colors.brown;
      case 'pupuk':
        return Colors.lightGreen;
      default:
        return Colors.grey;
    }
  }
}