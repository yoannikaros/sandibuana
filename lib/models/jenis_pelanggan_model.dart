class JenisPelangganModel {
  final int? id;
  final String nama;
  final String kode;
  final String? deskripsi;
  final bool aktif;
  final DateTime dibuatPada;
  final DateTime? diubahPada;

  JenisPelangganModel({
    this.id,
    required this.nama,
    required this.kode,
    this.deskripsi,
    this.aktif = true,
    required this.dibuatPada,
    this.diubahPada,
  });

  // Factory constructor from Map (SQLite)
  factory JenisPelangganModel.fromMap(Map<String, dynamic> map) {
    return JenisPelangganModel(
      id: map['id'],
      nama: map['nama'],
      kode: map['kode'],
      deskripsi: map['deskripsi'],
      aktif: map['aktif'] == 1,
      dibuatPada: DateTime.fromMillisecondsSinceEpoch(map['dibuat_pada']),
      diubahPada: map['diubah_pada'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['diubah_pada'])
          : null,
    );
  }

  // Convert to Map (SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'kode': kode,
      'deskripsi': deskripsi,
      'aktif': aktif ? 1 : 0,
      'dibuat_pada': dibuatPada.millisecondsSinceEpoch,
      'diubah_pada': diubahPada?.millisecondsSinceEpoch,
    };
  }

  // Copy with method for updates
  JenisPelangganModel copyWith({
    int? id,
    String? nama,
    String? kode,
    String? deskripsi,
    bool? aktif,
    DateTime? dibuatPada,
    DateTime? diubahPada,
  }) {
    return JenisPelangganModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      kode: kode ?? this.kode,
      deskripsi: deskripsi ?? this.deskripsi,
      aktif: aktif ?? this.aktif,
      dibuatPada: dibuatPada ?? this.dibuatPada,
      diubahPada: diubahPada ?? this.diubahPada,
    );
  }

  @override
  String toString() {
    return 'JenisPelangganModel(id: $id, nama: $nama, kode: $kode, aktif: $aktif)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JenisPelangganModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}