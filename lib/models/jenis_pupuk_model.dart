class JenisPupukModel {
  final String id;
  final String namaPupuk;
  final String? kodePupuk;
  final String tipe; // makro, mikro, organik, kimia
  final String? keterangan;
  final bool aktif;

  JenisPupukModel({
    required this.id,
    required this.namaPupuk,
    this.kodePupuk,
    required this.tipe,
    this.keterangan,
    this.aktif = true,
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
  }) {
    return JenisPupukModel(
      id: id ?? this.id,
      namaPupuk: namaPupuk ?? this.namaPupuk,
      kodePupuk: kodePupuk ?? this.kodePupuk,
      tipe: tipe ?? this.tipe,
      keterangan: keterangan ?? this.keterangan,
      aktif: aktif ?? this.aktif,
    );
  }

  @override
  String toString() {
    return 'JenisPupukModel(id: $id, namaPupuk: $namaPupuk, kodePupuk: $kodePupuk, tipe: $tipe, aktif: $aktif)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JenisPupukModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}