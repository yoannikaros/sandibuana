class CartItem {
  final String id;
  final String jenisSayur;
  final double harga;
  final double jumlah;
  final String satuan;
  final double total;
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.jenisSayur,
    required this.harga,
    required this.jumlah,
    required this.satuan,
    required this.total,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jenis_sayur': jenisSayur,
      'harga': harga,
      'jumlah': jumlah,
      'satuan': satuan,
      'total': total,
      'added_at': addedAt.millisecondsSinceEpoch,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '',
      jenisSayur: map['jenis_sayur'] ?? '',
      harga: (map['harga'] ?? 0.0).toDouble(),
      jumlah: (map['jumlah'] ?? 0.0).toDouble(),
      satuan: map['satuan'] ?? '',
      total: (map['total'] ?? 0.0).toDouble(),
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['added_at'] ?? 0),
    );
  }

  CartItem copyWith({
    String? id,
    String? jenisSayur,
    double? harga,
    double? jumlah,
    String? satuan,
    double? total,
    DateTime? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      jenisSayur: jenisSayur ?? this.jenisSayur,
      harga: harga ?? this.harga,
      jumlah: jumlah ?? this.jumlah,
      satuan: satuan ?? this.satuan,
      total: total ?? this.total,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}