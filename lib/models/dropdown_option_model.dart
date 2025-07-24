class DropdownOptionModel {
  final int? id;
  final String category; // 'area_tanaman', 'jenis_perlakuan', 'metode'
  final String value;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  DropdownOptionModel({
    this.id,
    required this.category,
    required this.value,
    this.description,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory DropdownOptionModel.fromMap(Map<String, dynamic> map) {
    return DropdownOptionModel(
      id: map['id'],
      category: map['category'],
      value: map['value'],
      description: map['description'],
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'value': value,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  DropdownOptionModel copyWith({
    int? id,
    String? category,
    String? value,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DropdownOptionModel(
      id: id ?? this.id,
      category: category ?? this.category,
      value: value ?? this.value,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'DropdownOptionModel(id: $id, category: $category, value: $value, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DropdownOptionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Constants untuk kategori dropdown
class DropdownCategories {
  // Removed areaTanaman - no longer needed
  static const String jenisPerlakuan = 'jenis_perlakuan';
  static const String metode = 'metode';
  
  static List<String> get allCategories => [
    jenisPerlakuan,
    metode,
  ];
  
  static String getCategoryDisplayName(String category) {
    switch (category) {
      case jenisPerlakuan:
        return 'Jenis Perlakuan';
      case metode:
        return 'Metode';
      default:
        return category;
    }
  }
}