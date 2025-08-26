import 'package:cloud_firestore/cloud_firestore.dart';

class KondisiMejaModel {
  final String id;
  final String namaMeja;
  final String kondisi; // 'kosong', 'tanam', 'panen'
  final DateTime? tanggalTanam;
  final String? jenisSayur;
  final int? targetHariPanen; // berapa hari dari tanam sampai panen
  final String? catatan;
  final bool aktif;
  final DateTime dibuatPada;
  final DateTime diubahPada;

  KondisiMejaModel({
    required this.id,
    required this.namaMeja,
    required this.kondisi,
    this.tanggalTanam,
    this.jenisSayur,
    this.targetHariPanen,
    this.catatan,
    this.aktif = true,
    required this.dibuatPada,
    required this.diubahPada,
  });

  // Hitung usia tanaman dalam hari
  int? get usiaTanamanHari {
    if (tanggalTanam == null) return null;
    final now = DateTime.now();
    return now.difference(tanggalTanam!).inDays;
  }

  // Hitung sisa hari sampai panen
  int? get sisaHariPanen {
    if (tanggalTanam == null || targetHariPanen == null) return null;
    final usia = usiaTanamanHari;
    if (usia == null) return null;
    return targetHariPanen! - usia;
  }

  // Status apakah sudah siap panen
  bool get siapPanen {
    final sisa = sisaHariPanen;
    return sisa != null && sisa <= 0;
  }

  // Factory constructor from Firestore
  factory KondisiMejaModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data();
      
      if (data == null) {
        throw Exception('Document data is null for document ${doc.id}');
      }
      
      final Map<String, dynamic> dataMap = data as Map<String, dynamic>;
      
      // Validate required fields
      if (!dataMap.containsKey('nama_meja') || dataMap['nama_meja'] == null) {
        throw Exception('Missing required field: nama_meja');
      }
      
      if (!dataMap.containsKey('kondisi') || dataMap['kondisi'] == null) {
        throw Exception('Missing required field: kondisi');
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
        dibuatPada = DateTime.now();
      }
      
      DateTime diubahPada;
      try {
        final timestamp = dataMap['diubah_pada'];
        if (timestamp is Timestamp) {
          diubahPada = timestamp.toDate();
        } else if (timestamp is String) {
          diubahPada = DateTime.parse(timestamp);
        } else {
          diubahPada = DateTime.now();
        }
      } catch (e) {
        diubahPada = DateTime.now();
      }
      
      DateTime? tanggalTanam;
      try {
        final timestamp = dataMap['tanggal_tanam'];
        if (timestamp is Timestamp) {
          tanggalTanam = timestamp.toDate();
        } else if (timestamp is String) {
          tanggalTanam = DateTime.parse(timestamp);
        }
      } catch (e) {
        tanggalTanam = null;
      }
      
      return KondisiMejaModel(
        id: doc.id,
        namaMeja: dataMap['nama_meja'] ?? '',
        kondisi: dataMap['kondisi'] ?? 'kosong',
        tanggalTanam: tanggalTanam,
        jenisSayur: dataMap['jenis_sayur'],
        targetHariPanen: dataMap['target_hari_panen'],
        catatan: dataMap['catatan'],
        aktif: dataMap['aktif'] ?? true,
        dibuatPada: dibuatPada,
        diubahPada: diubahPada,
      );
    } catch (e) {
      throw Exception('Error parsing KondisiMejaModel from Firestore: $e');
    }
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'nama_meja': namaMeja,
      'kondisi': kondisi,
      'tanggal_tanam': tanggalTanam != null ? Timestamp.fromDate(tanggalTanam!) : null,
      'jenis_sayur': jenisSayur,
      'target_hari_panen': targetHariPanen,
      'catatan': catatan,
      'aktif': aktif,
      'dibuat_pada': Timestamp.fromDate(dibuatPada),
      'diubah_pada': Timestamp.fromDate(diubahPada),
    };
  }

  // Copy with method
  KondisiMejaModel copyWith({
    String? id,
    String? namaMeja,
    String? kondisi,
    DateTime? tanggalTanam,
    String? jenisSayur,
    int? targetHariPanen,
    String? catatan,
    bool? aktif,
    DateTime? dibuatPada,
    DateTime? diubahPada,
  }) {
    return KondisiMejaModel(
      id: id ?? this.id,
      namaMeja: namaMeja ?? this.namaMeja,
      kondisi: kondisi ?? this.kondisi,
      tanggalTanam: tanggalTanam ?? this.tanggalTanam,
      jenisSayur: jenisSayur ?? this.jenisSayur,
      targetHariPanen: targetHariPanen ?? this.targetHariPanen,
      catatan: catatan ?? this.catatan,
      aktif: aktif ?? this.aktif,
      dibuatPada: dibuatPada ?? this.dibuatPada,
      diubahPada: diubahPada ?? this.diubahPada,
    );
  }

  @override
  String toString() {
    return 'KondisiMejaModel(id: $id, namaMeja: $namaMeja, kondisi: $kondisi, tanggalTanam: $tanggalTanam, jenisSayur: $jenisSayur, targetHariPanen: $targetHariPanen, usiaTanamanHari: $usiaTanamanHari, sisaHariPanen: $sisaHariPanen, siapPanen: $siapPanen)';
  }
}