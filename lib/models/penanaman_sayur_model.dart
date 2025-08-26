import 'package:cloud_firestore/cloud_firestore.dart';

class PenanamanSayurModel {
  final String idPenanaman;
  final String? idPembenihan; // Reference to catatan_pembenihan
  final DateTime tanggalTanam;
  final String jenisSayur;
  final int jumlahDitanam;
  final String tahapPertumbuhan; // semai, vegetatif, siap_panen, panen, gagal
  final DateTime? tanggalPanen;
  final int jumlahDipanen;
  final int jumlahGagal;
  final String? alasanGagal;
  final double tingkatKeberhasilan;
  final double? harga; // Harga per unit sayur
  final String dicatatOleh; // Reference to pengguna
  final DateTime dicatatPada;
  final DateTime diubahPada;

  PenanamanSayurModel({
    required this.idPenanaman,
    this.idPembenihan,
    required this.tanggalTanam,
    required this.jenisSayur,
    required this.jumlahDitanam,
    this.tahapPertumbuhan = 'semai',
    this.tanggalPanen,
    this.jumlahDipanen = 0,
    this.jumlahGagal = 0,
    this.alasanGagal,
    this.tingkatKeberhasilan = 0.0,
    this.harga,
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
      tahapPertumbuhan: data['tahap_pertumbuhan'] ?? 'semai',
      tanggalPanen: data['tanggal_panen'] != null 
          ? (data['tanggal_panen'] as Timestamp).toDate() 
          : null,
      jumlahDipanen: data['jumlah_dipanen'] ?? 0,
      jumlahGagal: data['jumlah_gagal'] ?? 0,
      alasanGagal: data['alasan_gagal'],
      tingkatKeberhasilan: (data['tingkat_keberhasilan'] ?? 0.0).toDouble(),
      harga: data['harga'] != null ? (data['harga'] as num).toDouble() : null,
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
      'tahap_pertumbuhan': tahapPertumbuhan,
      'tanggal_panen': tanggalPanen != null ? Timestamp.fromDate(tanggalPanen!) : null,
      'jumlah_dipanen': jumlahDipanen,
      'jumlah_gagal': jumlahGagal,
      'alasan_gagal': alasanGagal,
      'tingkat_keberhasilan': tingkatKeberhasilan,
      'harga': harga,
      'dicatat_oleh': dicatatOleh,
      'dicatat_pada': Timestamp.fromDate(dicatatPada),
      'diubah_pada': Timestamp.fromDate(diubahPada),
    };
  }

  // Formatted display methods
  String get formattedTanggalTanam {
    return '${tanggalTanam.day.toString().padLeft(2, '0')}/${tanggalTanam.month.toString().padLeft(2, '0')}/${tanggalTanam.year}';
  }

  String get formattedTanggalPanen {
    if (tanggalPanen == null) return '-';
    return '${tanggalPanen!.day.toString().padLeft(2, '0')}/${tanggalPanen!.month.toString().padLeft(2, '0')}/${tanggalPanen!.year}';
  }

  String get displayTahapPertumbuhan {
    switch (tahapPertumbuhan) {
      case 'semai':
        return 'Semai';
      case 'vegetatif':
        return 'Vegetatif';
      case 'siap_panen':
        return 'Siap Panen';
      case 'panen':
        return 'Panen';
      case 'gagal':
        return 'Gagal';
      default:
        return tahapPertumbuhan;
    }
  }



  String get displayAlasanGagal {
    return alasanGagal?.isNotEmpty == true ? alasanGagal! : 'Tidak ada alasan';
  }

  // Copy with method for updates
  PenanamanSayurModel copyWith({
    String? idPenanaman,
    String? idPembenihan,
    DateTime? tanggalTanam,
    String? jenisSayur,
    int? jumlahDitanam,
    String? tahapPertumbuhan,
    DateTime? tanggalPanen,
    int? jumlahDipanen,
    int? jumlahGagal,
    String? alasanGagal,
    double? tingkatKeberhasilan,
    double? harga,
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
      tahapPertumbuhan: tahapPertumbuhan ?? this.tahapPertumbuhan,
      tanggalPanen: tanggalPanen ?? this.tanggalPanen,
      jumlahDipanen: jumlahDipanen ?? this.jumlahDipanen,
      jumlahGagal: jumlahGagal ?? this.jumlahGagal,
      alasanGagal: alasanGagal ?? this.alasanGagal,
      tingkatKeberhasilan: tingkatKeberhasilan ?? this.tingkatKeberhasilan,
      harga: harga ?? this.harga,
      dicatatOleh: dicatatOleh ?? this.dicatatOleh,
      dicatatPada: dicatatPada ?? this.dicatatPada,
      diubahPada: diubahPada ?? this.diubahPada,
    );
  }
}