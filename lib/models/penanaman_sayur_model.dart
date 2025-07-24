import 'package:cloud_firestore/cloud_firestore.dart';

class PenanamanSayurModel {
  final String idPenanaman;
  final String? idPembenihan; // Reference to catatan_pembenihan
  final DateTime tanggalTanam;
  final String jenisSayur;
  final int jumlahDitanam;
  final String? lokasi;
  final String tahapPertumbuhan; // semai, vegetatif, siap_panen, panen, gagal
  final DateTime? tanggalPanen;
  final int jumlahDipanen;
  final int jumlahGagal;
  final String? alasanGagal;
  final double tingkatKeberhasilan;
  final double? harga; // Harga per unit sayur
  final String? catatan;
  final String dicatatOleh; // Reference to pengguna
  final DateTime dicatatPada;
  final DateTime diubahPada;

  PenanamanSayurModel({
    required this.idPenanaman,
    this.idPembenihan,
    required this.tanggalTanam,
    required this.jenisSayur,
    required this.jumlahDitanam,
    this.lokasi,
    this.tahapPertumbuhan = 'semai',
    this.tanggalPanen,
    this.jumlahDipanen = 0,
    this.jumlahGagal = 0,
    this.alasanGagal,
    this.tingkatKeberhasilan = 0.0,
    this.harga,
    this.catatan,
    required this.dicatatOleh,
    required this.dicatatPada,
    required this.diubahPada,
  });

  // Convert from Firestore document
  factory PenanamanSayurModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return PenanamanSayurModel(
      idPenanaman: doc.id,
      idPembenihan: data['id_pembenihan'],
      tanggalTanam: (data['tanggal_tanam'] as Timestamp).toDate(),
      jenisSayur: data['jenis_sayur'] ?? '',
      jumlahDitanam: data['jumlah_ditanam'] ?? 0,
      lokasi: data['lokasi'],
      tahapPertumbuhan: data['tahap_pertumbuhan'] ?? 'semai',
      tanggalPanen: data['tanggal_panen'] != null 
          ? (data['tanggal_panen'] as Timestamp).toDate() 
          : null,
      jumlahDipanen: data['jumlah_dipanen'] ?? 0,
      jumlahGagal: data['jumlah_gagal'] ?? 0,
      alasanGagal: data['alasan_gagal'],
      tingkatKeberhasilan: (data['tingkat_keberhasilan'] ?? 0.0).toDouble(),
      harga: data['harga'] != null ? (data['harga'] as num).toDouble() : null,
      catatan: data['catatan'],
      dicatatOleh: data['dicatat_oleh'] ?? '',
      dicatatPada: (data['dicatat_pada'] as Timestamp).toDate(),
      diubahPada: (data['diubah_pada'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id_pembenihan': idPembenihan,
      'tanggal_tanam': Timestamp.fromDate(tanggalTanam),
      'jenis_sayur': jenisSayur,
      'jumlah_ditanam': jumlahDitanam,
      'lokasi': lokasi,
      'tahap_pertumbuhan': tahapPertumbuhan,
      'tanggal_panen': tanggalPanen != null ? Timestamp.fromDate(tanggalPanen!) : null,
      'jumlah_dipanen': jumlahDipanen,
      'jumlah_gagal': jumlahGagal,
      'alasan_gagal': alasanGagal,
      'tingkat_keberhasilan': tingkatKeberhasilan,
      'harga': harga,
      'catatan': catatan,
      'dicatat_oleh': dicatatOleh,
      'dicatat_pada': Timestamp.fromDate(dicatatPada),
      'diubah_pada': Timestamp.fromDate(diubahPada),
    };
  }

  // Copy with method for updates
  PenanamanSayurModel copyWith({
    String? idPenanaman,
    String? idPembenihan,
    DateTime? tanggalTanam,
    String? jenisSayur,
    int? jumlahDitanam,
    String? lokasi,
    String? tahapPertumbuhan,
    DateTime? tanggalPanen,
    int? jumlahDipanen,
    int? jumlahGagal,
    String? alasanGagal,
    double? tingkatKeberhasilan,
    double? harga,
    String? catatan,
    String? dicatatOleh,
    DateTime? dicatatPada,
    DateTime? diubahPada,
  }) {
    return PenanamanSayurModel(
      idPenanaman: idPenanaman ?? this.idPenanaman,
      idPembenihan: idPembenihan ?? this.idPembenihan,
      tanggalTanam: tanggalTanam ?? this.tanggalTanam,
      jenisSayur: jenisSayur ?? this.jenisSayur,
      jumlahDitanam: jumlahDitanam ?? this.jumlahDitanam,
      lokasi: lokasi ?? this.lokasi,
      tahapPertumbuhan: tahapPertumbuhan ?? this.tahapPertumbuhan,
      tanggalPanen: tanggalPanen ?? this.tanggalPanen,
      jumlahDipanen: jumlahDipanen ?? this.jumlahDipanen,
      jumlahGagal: jumlahGagal ?? this.jumlahGagal,
      alasanGagal: alasanGagal ?? this.alasanGagal,
      tingkatKeberhasilan: tingkatKeberhasilan ?? this.tingkatKeberhasilan,
      harga: harga ?? this.harga,
      catatan: catatan ?? this.catatan,
      dicatatOleh: dicatatOleh ?? this.dicatatOleh,
      dicatatPada: dicatatPada ?? this.dicatatPada,
      diubahPada: diubahPada ?? this.diubahPada,
    );
  }
}