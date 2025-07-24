import 'package:cloud_firestore/cloud_firestore.dart';

class PelangganModel {
  final String id;
  final String namaPelanggan;
  final String jenisPelanggan; // restoran, hotel, individu
  final String? kontakPerson;
  final String? telepon;
  final String? alamat;
  final bool aktif;
  final DateTime dibuatPada;

  PelangganModel({
    required this.id,
    required this.namaPelanggan,
    required this.jenisPelanggan,
    this.kontakPerson,
    this.telepon,
    this.alamat,
    this.aktif = true,
    required this.dibuatPada,
  });

  // Factory constructor from Firestore
  factory PelangganModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PelangganModel(
      id: doc.id,
      namaPelanggan: data['nama_pelanggan'] ?? '',
      jenisPelanggan: data['jenis_pelanggan'] ?? 'restoran',
      kontakPerson: data['kontak_person'],
      telepon: data['telepon'],
      alamat: data['alamat'],
      aktif: data['aktif'] ?? true,
      dibuatPada: (data['dibuat_pada'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Factory constructor from Map
  factory PelangganModel.fromMap(Map<String, dynamic> data, String id) {
    return PelangganModel(
      id: id,
      namaPelanggan: data['nama_pelanggan'] ?? '',
      jenisPelanggan: data['jenis_pelanggan'] ?? 'restoran',
      kontakPerson: data['kontak_person'],
      telepon: data['telepon'],
      alamat: data['alamat'],
      aktif: data['aktif'] ?? true,
      dibuatPada: (data['dibuat_pada'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'nama_pelanggan': namaPelanggan,
      'jenis_pelanggan': jenisPelanggan,
      'kontak_person': kontakPerson,
      'telepon': telepon,
      'alamat': alamat,
      'aktif': aktif,
      'dibuat_pada': Timestamp.fromDate(dibuatPada),
    };
  }

  // Copy with method for updates
  PelangganModel copyWith({
    String? id,
    String? namaPelanggan,
    String? jenisPelanggan,
    String? kontakPerson,
    String? telepon,
    String? alamat,
    bool? aktif,
    DateTime? dibuatPada,
  }) {
    return PelangganModel(
      id: id ?? this.id,
      namaPelanggan: namaPelanggan ?? this.namaPelanggan,
      jenisPelanggan: jenisPelanggan ?? this.jenisPelanggan,
      kontakPerson: kontakPerson ?? this.kontakPerson,
      telepon: telepon ?? this.telepon,
      alamat: alamat ?? this.alamat,
      aktif: aktif ?? this.aktif,
      dibuatPada: dibuatPada ?? this.dibuatPada,
    );
  }

  @override
  String toString() {
    return 'PelangganModel(id: $id, namaPelanggan: $namaPelanggan, jenisPelanggan: $jenisPelanggan, aktif: $aktif)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PelangganModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Helper method to get jenis pelanggan display name
  String get jenisPelangganDisplay {
    switch (jenisPelanggan) {
      case 'restoran':
        return 'Restoran';
      case 'hotel':
        return 'Hotel';
      case 'individu':
        return 'Individu';
      default:
        return jenisPelanggan;
    }
  }

  // Static method to get jenis pelanggan options
  static List<String> get jenisPelangganOptions => ['restoran', 'hotel', 'individu'];
  
  static List<String> get jenisPelangganDisplayOptions => ['Restoran', 'Hotel', 'Individu'];
}