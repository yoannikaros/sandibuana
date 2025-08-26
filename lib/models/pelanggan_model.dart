import 'package:cloud_firestore/cloud_firestore.dart';

class PelangganModel {
  final String id;
  final String namaPelanggan;
  final String jenisPelanggan; // restoran, hotel, individu
  final String? namaTempatUsaha;
  final String? kontakPerson;
  final String? telepon;
  final String? alamat;
  final bool aktif;
  final DateTime dibuatPada;

  PelangganModel({
    required this.id,
    required this.namaPelanggan,
    required this.jenisPelanggan,
    this.namaTempatUsaha,
    this.kontakPerson,
    this.telepon,
    this.alamat,
    this.aktif = true,
    required this.dibuatPada,
  });

  // Factory constructor from Firestore
  factory PelangganModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data();
      
      if (data == null) {
        throw Exception('Document data is null for document ${doc.id}');
      }
      
      final Map<String, dynamic> dataMap = data as Map<String, dynamic>;
      
      // Validate required fields
      if (!dataMap.containsKey('nama_pelanggan') || dataMap['nama_pelanggan'] == null) {
        throw Exception('Missing required field: nama_pelanggan');
      }
      
      DateTime dibuatPada;
      try {
        final timestamp = dataMap['dibuat_pada'];
        if (timestamp is Timestamp) {
          dibuatPada = timestamp.toDate();
        } else if (timestamp is String) {
          dibuatPada = DateTime.parse(timestamp);
        } else {
          dibuatPada = DateTime.now();
        }
      } catch (e) {
        print('Error parsing dibuat_pada for document ${doc.id}: $e');
        dibuatPada = DateTime.now();
      }
      
      return PelangganModel(
        id: doc.id,
        namaPelanggan: (dataMap['nama_pelanggan'] ?? '').toString().trim(),
        jenisPelanggan: (dataMap['jenis_pelanggan'] ?? 'restoran').toString().trim(),
        namaTempatUsaha: dataMap['nama_tempat_usaha']?.toString()?.trim(),
        kontakPerson: dataMap['kontak_person']?.toString()?.trim(),
        telepon: dataMap['telepon']?.toString()?.trim(),
        alamat: dataMap['alamat']?.toString()?.trim(),
        aktif: dataMap['aktif'] ?? true,
        dibuatPada: dibuatPada,
      );
    } catch (e) {
      print('Error creating PelangganModel from Firestore document ${doc.id}: $e');
      rethrow;
    }
  }

  // Factory constructor from Map
  factory PelangganModel.fromMap(Map<String, dynamic> data, String id) {
    return PelangganModel(
      id: id,
      namaPelanggan: data['nama_pelanggan'] ?? '',
      jenisPelanggan: data['jenis_pelanggan'] ?? 'restoran',
      namaTempatUsaha: data['nama_tempat_usaha'],
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
      'nama_tempat_usaha': namaTempatUsaha,
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
    String? namaTempatUsaha,
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
      namaTempatUsaha: namaTempatUsaha ?? this.namaTempatUsaha,
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

  // Static method to get jenis pelanggan options (fallback)
  static List<String> get jenisPelangganOptions => ['restoran', 'hotel', 'individu'];
  
  static List<String> get jenisPelangganDisplayOptions => ['Restoran', 'Hotel', 'Individu'];
  
  // Note: For dynamic options from SQLite, use JenisPelangganProvider
}