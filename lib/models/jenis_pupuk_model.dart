class JenisPupukModel {
  final String id;
  final String namaPupuk;
  final String? kodePupuk;
  final String tipe; // makro, mikro, organik, kimia
  final String? keterangan;
  final bool aktif;
  final double stok; // stok pupuk dalam kg atau liter

  JenisPupukModel({
    required this.id,
    required this.namaPupuk,
    this.kodePupuk,
    required this.tipe,
    this.keterangan,
    this.aktif = true,
    this.stok = 0.0,
  });

  // Convert from Firestore document
  factory JenisPupukModel.fromFirestore(Map<String, dynamic> data, String id) {
    return JenisPupukModel(
      id: id,
      namaPupuk: data['nama_pupuk'] ?? '',
      kodePupuk: data['kode_pupuk'],
      tipe: data['tipe'] ?? 'makro',
      keterangan: data['keterangan'],
      aktif: data['aktif'] ?? true,
      stok: (data['stok'] ?? 0.0).toDouble(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'nama_pupuk': namaPupuk,
      'kode_pupuk': kodePupuk,
      'tipe': tipe,
      'keterangan': keterangan,
      'aktif': aktif,
      'stok': stok,
    };
  }

  // Copy with method for updates
  JenisPupukModel copyWith({
    String? id,
    String? namaPupuk,
    String? kodePupuk,
    String? tipe,
    String? keterangan,
    bool? aktif,
    double? stok,
  }) {
    return JenisPupukModel(
      id: id ?? this.id,
      namaPupuk: namaPupuk ?? this.namaPupuk,
      kodePupuk: kodePupuk ?? this.kodePupuk,
      tipe: tipe ?? this.tipe,
      keterangan: keterangan ?? this.keterangan,
      aktif: aktif ?? this.aktif,
      stok: stok ?? this.stok,
    );
  }

  @override
  String toString() {
    return 'JenisPupukModel(id: $id, namaPupuk: $namaPupuk, kodePupuk: $kodePupuk, tipe: $tipe, aktif: $aktif, stok: $stok)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JenisPupukModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}