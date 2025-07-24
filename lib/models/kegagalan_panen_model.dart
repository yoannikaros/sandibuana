import 'package:cloud_firestore/cloud_firestore.dart';

class KegagalanPanenModel {
  final String idKegagalan;
  final DateTime tanggalGagal;
  final String idPenanaman;
  final int jumlahGagal;
  final String jenisKegagalan; // busuk, layu, hama, penyakit, cuaca, lainnya
  final String? penyebabGagal;
  final String? lokasi;
  final String? tindakanDiambil;
  final String dicatatOleh;
  final DateTime dicatatPada;

  KegagalanPanenModel({
    required this.idKegagalan,
    required this.tanggalGagal,
    required this.idPenanaman,
    required this.jumlahGagal,
    required this.jenisKegagalan,
    this.penyebabGagal,
    this.lokasi,
    this.tindakanDiambil,
    required this.dicatatOleh,
    required this.dicatatPada,
  });

  // Factory constructor untuk membuat instance dari Firestore
  factory KegagalanPanenModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return KegagalanPanenModel(
      idKegagalan: doc.id,
      tanggalGagal: (data['tanggal_gagal'] as Timestamp).toDate(),
      idPenanaman: data['id_penanaman'] ?? '',
      jumlahGagal: data['jumlah_gagal'] ?? 0,
      jenisKegagalan: data['jenis_kegagalan'] ?? 'lainnya',
      penyebabGagal: data['penyebab_gagal'],
      lokasi: data['lokasi'],
      tindakanDiambil: data['tindakan_diambil'],
      dicatatOleh: data['dicatat_oleh'] ?? '',
      dicatatPada: (data['dicatat_pada'] as Timestamp).toDate(),
    );
  }

  // Method untuk mengkonversi ke Map untuk Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'tanggal_gagal': Timestamp.fromDate(tanggalGagal),
      'id_penanaman': idPenanaman,
      'jumlah_gagal': jumlahGagal,
      'jenis_kegagalan': jenisKegagalan,
      'penyebab_gagal': penyebabGagal,
      'lokasi': lokasi,
      'tindakan_diambil': tindakanDiambil,
      'dicatat_oleh': dicatatOleh,
      'dicatat_pada': Timestamp.fromDate(dicatatPada),
    };
  }

  // Method untuk membuat copy dengan perubahan
  KegagalanPanenModel copyWith({
    String? idKegagalan,
    DateTime? tanggalGagal,
    String? idPenanaman,
    int? jumlahGagal,
    String? jenisKegagalan,
    String? penyebabGagal,
    String? lokasi,
    String? tindakanDiambil,
    String? dicatatOleh,
    DateTime? dicatatPada,
  }) {
    return KegagalanPanenModel(
      idKegagalan: idKegagalan ?? this.idKegagalan,
      tanggalGagal: tanggalGagal ?? this.tanggalGagal,
      idPenanaman: idPenanaman ?? this.idPenanaman,
      jumlahGagal: jumlahGagal ?? this.jumlahGagal,
      jenisKegagalan: jenisKegagalan ?? this.jenisKegagalan,
      penyebabGagal: penyebabGagal ?? this.penyebabGagal,
      lokasi: lokasi ?? this.lokasi,
      tindakanDiambil: tindakanDiambil ?? this.tindakanDiambil,
      dicatatOleh: dicatatOleh ?? this.dicatatOleh,
      dicatatPada: dicatatPada ?? this.dicatatPada,
    );
  }

  @override
  String toString() {
    return 'KegagalanPanenModel(idKegagalan: $idKegagalan, tanggalGagal: $tanggalGagal, idPenanaman: $idPenanaman, jumlahGagal: $jumlahGagal, jenisKegagalan: $jenisKegagalan)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is KegagalanPanenModel &&
      other.idKegagalan == idKegagalan &&
      other.tanggalGagal == tanggalGagal &&
      other.idPenanaman == idPenanaman &&
      other.jumlahGagal == jumlahGagal &&
      other.jenisKegagalan == jenisKegagalan &&
      other.penyebabGagal == penyebabGagal &&
      other.lokasi == lokasi &&
      other.tindakanDiambil == tindakanDiambil &&
      other.dicatatOleh == dicatatOleh &&
      other.dicatatPada == dicatatPada;
  }

  @override
  int get hashCode {
    return idKegagalan.hashCode ^
      tanggalGagal.hashCode ^
      idPenanaman.hashCode ^
      jumlahGagal.hashCode ^
      jenisKegagalan.hashCode ^
      penyebabGagal.hashCode ^
      lokasi.hashCode ^
      tindakanDiambil.hashCode ^
      dicatatOleh.hashCode ^
      dicatatPada.hashCode;
  }

  // Static method untuk mendapatkan daftar jenis kegagalan
  static List<String> getJenisKegagalanOptions() {
    return [
      'busuk',
      'layu',
      'hama',
      'penyakit',
      'cuaca',
      'lainnya',
    ];
  }

  // Static method untuk mendapatkan display name jenis kegagalan
  static String getJenisKegagalanDisplayName(String jenis) {
    switch (jenis) {
      case 'busuk':
        return 'Busuk';
      case 'layu':
        return 'Layu';
      case 'hama':
        return 'Hama';
      case 'penyakit':
        return 'Penyakit';
      case 'cuaca':
        return 'Cuaca';
      case 'lainnya':
        return 'Lainnya';
      default:
        return jenis;
    }
  }

  // Method untuk mendapatkan warna berdasarkan jenis kegagalan
  static String getJenisKegagalanColor(String jenis) {
    switch (jenis) {
      case 'busuk':
        return '#8B4513'; // Brown
      case 'layu':
        return '#FF8C00'; // Dark Orange
      case 'hama':
        return '#DC143C'; // Crimson
      case 'penyakit':
        return '#9932CC'; // Dark Orchid
      case 'cuaca':
        return '#4682B4'; // Steel Blue
      case 'lainnya':
        return '#696969'; // Dim Gray
      default:
        return '#808080'; // Gray
    }
  }
}