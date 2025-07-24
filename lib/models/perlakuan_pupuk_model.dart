class PerlakuanPupukModel {
  final String idPerlakuan;
  final String kodePerlakuan;
  final String namaPerlakuan;
  final String? deskripsi;
  final bool isAktif;
  final DateTime dibuatPada;
  final DateTime? diupdatePada;
  final String dibuatOleh;
  final String? diupdateOleh;

  PerlakuanPupukModel({
    required this.idPerlakuan,
    required this.kodePerlakuan,
    required this.namaPerlakuan,
    this.deskripsi,
    this.isAktif = true,
    required this.dibuatPada,
    this.diupdatePada,
    required this.dibuatOleh,
    this.diupdateOleh,
  });

  // Factory constructor untuk membuat instance dari Map (SQLite)
  factory PerlakuanPupukModel.fromMap(Map<String, dynamic> map) {
    return PerlakuanPupukModel(
      idPerlakuan: map['id_perlakuan'] ?? '',
      kodePerlakuan: map['kode_perlakuan'] ?? '',
      namaPerlakuan: map['nama_perlakuan'] ?? '',
      deskripsi: map['deskripsi'],
      isAktif: (map['is_aktif'] ?? 1) == 1,
      dibuatPada: DateTime.parse(map['dibuat_pada'] ?? DateTime.now().toIso8601String()),
      diupdatePada: map['diupdate_pada'] != null 
          ? DateTime.parse(map['diupdate_pada']) 
          : null,
      dibuatOleh: map['dibuat_oleh'] ?? '',
      diupdateOleh: map['diupdate_oleh'],
    );
  }

  // Method untuk mengkonversi ke Map untuk SQLite
  Map<String, dynamic> toMap() {
    return {
      'id_perlakuan': idPerlakuan,
      'kode_perlakuan': kodePerlakuan,
      'nama_perlakuan': namaPerlakuan,
      'deskripsi': deskripsi,
      'is_aktif': isAktif ? 1 : 0,
      'dibuat_pada': dibuatPada.toIso8601String(),
      'diupdate_pada': diupdatePada?.toIso8601String(),
      'dibuat_oleh': dibuatOleh,
      'diupdate_oleh': diupdateOleh,
    };
  }

  // Method untuk membuat copy dengan perubahan
  PerlakuanPupukModel copyWith({
    String? idPerlakuan,
    String? kodePerlakuan,
    String? namaPerlakuan,
    String? deskripsi,
    bool? isAktif,
    DateTime? dibuatPada,
    DateTime? diupdatePada,
    String? dibuatOleh,
    String? diupdateOleh,
  }) {
    return PerlakuanPupukModel(
      idPerlakuan: idPerlakuan ?? this.idPerlakuan,
      kodePerlakuan: kodePerlakuan ?? this.kodePerlakuan,
      namaPerlakuan: namaPerlakuan ?? this.namaPerlakuan,
      deskripsi: deskripsi ?? this.deskripsi,
      isAktif: isAktif ?? this.isAktif,
      dibuatPada: dibuatPada ?? this.dibuatPada,
      diupdatePada: diupdatePada ?? this.diupdatePada,
      dibuatOleh: dibuatOleh ?? this.dibuatOleh,
      diupdateOleh: diupdateOleh ?? this.diupdateOleh,
    );
  }

  // Method untuk validasi
  bool isValid() {
    return kodePerlakuan.isNotEmpty && 
           namaPerlakuan.isNotEmpty &&
           dibuatOleh.isNotEmpty;
  }

  // Method untuk mendapatkan display name
  String get displayName => '$kodePerlakuan - $namaPerlakuan';

  // Method untuk mendapatkan status text
  String get statusText => isAktif ? 'Aktif' : 'Nonaktif';

  @override
  String toString() {
    return 'PerlakuanPupukModel(idPerlakuan: $idPerlakuan, kodePerlakuan: $kodePerlakuan, namaPerlakuan: $namaPerlakuan, isAktif: $isAktif)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PerlakuanPupukModel && 
           other.idPerlakuan == idPerlakuan;
  }

  @override
  int get hashCode => idPerlakuan.hashCode;

  // Static method untuk membuat data default
  static List<Map<String, dynamic>> getDefaultData() {
    final now = DateTime.now();
    return [
      {
        'id_perlakuan': 'perlakuan_001',
        'kode_perlakuan': 'CEF_PTH',
        'nama_perlakuan': 'Pupuk CEF + PTh',
        'deskripsi': 'Kombinasi pupuk CEF dengan Pythium Treatment',
        'is_aktif': 1,
        'dibuat_pada': now.toIso8601String(),
        'dibuat_oleh': 'system',
      },
      {
        'id_perlakuan': 'perlakuan_002',
        'kode_perlakuan': 'COKLAT',
        'nama_perlakuan': 'Pupuk Coklat',
        'deskripsi': 'Pupuk organik berbasis coklat',
        'is_aktif': 1,
        'dibuat_pada': now.toIso8601String(),
        'dibuat_oleh': 'system',
      },
      {
        'id_perlakuan': 'perlakuan_003',
        'kode_perlakuan': 'PUTIH',
        'nama_perlakuan': 'Pupuk Putih',
        'deskripsi': 'Pupuk mineral putih',
        'is_aktif': 1,
        'dibuat_pada': now.toIso8601String(),
        'dibuat_oleh': 'system',
      },
      {
        'id_perlakuan': 'perlakuan_004',
        'kode_perlakuan': 'CEF',
        'nama_perlakuan': 'Pupuk CEF',
        'deskripsi': 'Pupuk CEF standar',
        'is_aktif': 1,
        'dibuat_pada': now.toIso8601String(),
        'dibuat_oleh': 'system',
      },
      {
        'id_perlakuan': 'perlakuan_005',
        'kode_perlakuan': 'COKLAT_HIR',
        'nama_perlakuan': 'Pupuk Coklat + HIRACOL',
        'deskripsi': 'Kombinasi pupuk coklat dengan HIRACOL',
        'is_aktif': 1,
        'dibuat_pada': now.toIso8601String(),
        'dibuat_oleh': 'system',
      },
      {
        'id_perlakuan': 'perlakuan_006',
        'kode_perlakuan': 'PUTIH_ANT',
        'nama_perlakuan': 'Pupuk Putih + ANTRACOL',
        'deskripsi': 'Kombinasi pupuk putih dengan ANTRACOL',
        'is_aktif': 1,
        'dibuat_pada': now.toIso8601String(),
        'dibuat_oleh': 'system',
      },
      {
        'id_perlakuan': 'perlakuan_007',
        'kode_perlakuan': 'BAWPUT_CEF',
        'nama_perlakuan': 'Bawang Putih + Pupuk CEF',
        'deskripsi': 'Kombinasi ekstrak bawang putih dengan pupuk CEF',
        'is_aktif': 1,
        'dibuat_pada': now.toIso8601String(),
        'dibuat_oleh': 'system',
      },
      {
        'id_perlakuan': 'perlakuan_008',
        'kode_perlakuan': 'TREAT_KHUSUS',
        'nama_perlakuan': 'Treatment Khusus',
        'deskripsi': 'Perlakuan khusus sesuai kondisi tanaman',
        'is_aktif': 1,
        'dibuat_pada': now.toIso8601String(),
        'dibuat_oleh': 'system',
      },
    ];
  }
}