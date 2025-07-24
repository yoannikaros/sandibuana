import 'package:cloud_firestore/cloud_firestore.dart';

class RekapPupukMingguanModel {
  final String id;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final String idTandon;
  final String idPupuk;
  final double jumlahDigunakan;
  final String satuan;
  final double? jumlahSeharusnya; // Jumlah yang seharusnya digunakan berdasarkan kapasitas tandon
  final double? selisih; // Selisih antara yang digunakan dengan yang seharusnya
  final bool? indikasiBocor; // True jika ada indikasi kebocoran
  final String? catatan;
  final String dicatatOleh;
  final DateTime dicatatPada;

  RekapPupukMingguanModel({
    required this.id,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.idTandon,
    required this.idPupuk,
    required this.jumlahDigunakan,
    required this.satuan,
    this.jumlahSeharusnya,
    this.selisih,
    this.indikasiBocor,
    this.catatan,
    required this.dicatatOleh,
    required this.dicatatPada,
  });

  // Convert from Firestore document
  factory RekapPupukMingguanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RekapPupukMingguanModel(
      id: doc.id,
      tanggalMulai: (data['tanggal_mulai'] as Timestamp).toDate(),
      tanggalSelesai: (data['tanggal_selesai'] as Timestamp).toDate(),
      idTandon: data['id_tandon'] ?? '',
      idPupuk: data['id_pupuk'] ?? '',
      jumlahDigunakan: (data['jumlah_digunakan'] ?? 0.0).toDouble(),
      satuan: data['satuan'] ?? '',
      jumlahSeharusnya: data['jumlah_seharusnya']?.toDouble(),
      selisih: data['selisih']?.toDouble(),
      indikasiBocor: data['indikasi_bocor'],
      catatan: data['catatan'],
      dicatatOleh: data['dicatat_oleh'] ?? '',
      dicatatPada: (data['dicatat_pada'] as Timestamp).toDate(),
    );
  }

  // Convert from Map
  factory RekapPupukMingguanModel.fromMap(Map<String, dynamic> data, String id) {
    return RekapPupukMingguanModel(
      id: id,
      tanggalMulai: data['tanggal_mulai'] is Timestamp 
          ? (data['tanggal_mulai'] as Timestamp).toDate()
          : DateTime.parse(data['tanggal_mulai']),
      tanggalSelesai: data['tanggal_selesai'] is Timestamp 
          ? (data['tanggal_selesai'] as Timestamp).toDate()
          : DateTime.parse(data['tanggal_selesai']),
      idTandon: data['id_tandon'] ?? '',
      idPupuk: data['id_pupuk'] ?? '',
      jumlahDigunakan: (data['jumlah_digunakan'] ?? 0.0).toDouble(),
      satuan: data['satuan'] ?? '',
      jumlahSeharusnya: data['jumlah_seharusnya']?.toDouble(),
      selisih: data['selisih']?.toDouble(),
      indikasiBocor: data['indikasi_bocor'],
      catatan: data['catatan'],
      dicatatOleh: data['dicatat_oleh'] ?? '',
      dicatatPada: data['dicatat_pada'] is Timestamp 
          ? (data['dicatat_pada'] as Timestamp).toDate()
          : DateTime.parse(data['dicatat_pada']),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'tanggal_mulai': Timestamp.fromDate(tanggalMulai),
      'tanggal_selesai': Timestamp.fromDate(tanggalSelesai),
      'id_tandon': idTandon,
      'id_pupuk': idPupuk,
      'jumlah_digunakan': jumlahDigunakan,
      'satuan': satuan,
      'jumlah_seharusnya': jumlahSeharusnya,
      'selisih': selisih,
      'indikasi_bocor': indikasiBocor,
      'catatan': catatan,
      'dicatat_oleh': dicatatOleh,
      'dicatat_pada': Timestamp.fromDate(dicatatPada),
    };
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tanggal_mulai': tanggalMulai.toIso8601String(),
      'tanggal_selesai': tanggalSelesai.toIso8601String(),
      'id_tandon': idTandon,
      'id_pupuk': idPupuk,
      'jumlah_digunakan': jumlahDigunakan,
      'satuan': satuan,
      'jumlah_seharusnya': jumlahSeharusnya,
      'selisih': selisih,
      'indikasi_bocor': indikasiBocor,
      'catatan': catatan,
      'dicatat_oleh': dicatatOleh,
      'dicatat_pada': dicatatPada.toIso8601String(),
    };
  }

  // Copy with method for updates
  RekapPupukMingguanModel copyWith({
    String? id,
    DateTime? tanggalMulai,
    DateTime? tanggalSelesai,
    String? idTandon,
    String? idPupuk,
    double? jumlahDigunakan,
    String? satuan,
    double? jumlahSeharusnya,
    double? selisih,
    bool? indikasiBocor,
    String? catatan,
    String? dicatatOleh,
    DateTime? dicatatPada,
  }) {
    return RekapPupukMingguanModel(
      id: id ?? this.id,
      tanggalMulai: tanggalMulai ?? this.tanggalMulai,
      tanggalSelesai: tanggalSelesai ?? this.tanggalSelesai,
      idTandon: idTandon ?? this.idTandon,
      idPupuk: idPupuk ?? this.idPupuk,
      jumlahDigunakan: jumlahDigunakan ?? this.jumlahDigunakan,
      satuan: satuan ?? this.satuan,
      jumlahSeharusnya: jumlahSeharusnya ?? this.jumlahSeharusnya,
      selisih: selisih ?? this.selisih,
      indikasiBocor: indikasiBocor ?? this.indikasiBocor,
      catatan: catatan ?? this.catatan,
      dicatatOleh: dicatatOleh ?? this.dicatatOleh,
      dicatatPada: dicatatPada ?? this.dicatatPada,
    );
  }

  // Validation method
  bool isValid() {
    return idTandon.isNotEmpty &&
           idPupuk.isNotEmpty &&
           jumlahDigunakan >= 0 &&
           satuan.isNotEmpty &&
           dicatatOleh.isNotEmpty;
  }

  // Calculate leak indication based on difference percentage
  bool calculateLeakIndication() {
    if (jumlahSeharusnya == null || jumlahSeharusnya == 0) return false;
    
    final percentage = (selisih?.abs() ?? 0) / jumlahSeharusnya! * 100;
    return percentage > 15; // Indikasi bocor jika selisih > 15%
  }

  // Get status color based on leak indication
  String getStatusColor() {
    if (indikasiBocor == true) return 'red';
    if ((selisih?.abs() ?? 0) > 0) return 'orange';
    return 'green';
  }

  // Get status text
  String getStatusText() {
    if (indikasiBocor == true) return 'Indikasi Bocor';
    if ((selisih?.abs() ?? 0) > 0) return 'Perlu Perhatian';
    return 'Normal';
  }

  // Static method for satuan options
  static List<String> getSatuanOptions() {
    return ['ml', 'liter', 'gram', 'kg'];
  }

  // Get week range text
  String getWeekRangeText() {
    return '${tanggalMulai.day}/${tanggalMulai.month}/${tanggalMulai.year} - ${tanggalSelesai.day}/${tanggalSelesai.month}/${tanggalSelesai.year}';
  }

  @override
  String toString() {
    return 'RekapPupukMingguanModel(id: $id, tanggalMulai: $tanggalMulai, tanggalSelesai: $tanggalSelesai, idTandon: $idTandon, idPupuk: $idPupuk, jumlahDigunakan: $jumlahDigunakan, indikasiBocor: $indikasiBocor)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RekapPupukMingguanModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}