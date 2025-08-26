class CartItemModel {
  final String id;
  final String idPenanaman;
  final String jenisSayur;
  final double harga;
  final double jumlah;
  final String satuan;
  final double totalHarga;

  CartItemModel({
    required this.id,
    required this.idPenanaman,
    required this.jenisSayur,
    required this.harga,
    required this.jumlah,
    required this.satuan,
    required this.totalHarga,
  });

  // Copy with method for updates
  CartItemModel copyWith({
    String? id,
    String? idPenanaman,
    String? jenisSayur,
    double? harga,
    double? jumlah,
    String? satuan,
    double? totalHarga,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      idPenanaman: idPenanaman ?? this.idPenanaman,
      jenisSayur: jenisSayur ?? this.jenisSayur,
      harga: harga ?? this.harga,
      jumlah: jumlah ?? this.jumlah,
      satuan: satuan ?? this.satuan,
      totalHarga: totalHarga ?? this.totalHarga,
    );
  }

  @override
  String toString() {
    return 'CartItemModel(id: $id, jenisSayur: $jenisSayur, jumlah: $jumlah, totalHarga: $totalHarga)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItemModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}