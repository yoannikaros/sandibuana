class UserModel {
  final String idPengguna;
  final String namaPengguna;
  final String namaLengkap;
  final String? email;
  final String peran;
  final bool aktif;
  final DateTime dibuatPada;
  final DateTime diubahPada;

  UserModel({
    required this.idPengguna,
    required this.namaPengguna,
    required this.namaLengkap,
    this.email,
    required this.peran,
    required this.aktif,
    required this.dibuatPada,
    required this.diubahPada,
  });

  // Factory constructor untuk membuat UserModel dari Map (Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      idPengguna: documentId,
      namaPengguna: map['nama_pengguna'] ?? '',
      namaLengkap: map['nama_lengkap'] ?? '',
      email: map['email'],
      peran: map['peran'] ?? 'operator',
      aktif: map['aktif'] ?? true,
      dibuatPada: map['dibuat_pada']?.toDate() ?? DateTime.now(),
      diubahPada: map['diubah_pada']?.toDate() ?? DateTime.now(),
    );
  }

  // Method untuk mengkonversi UserModel ke Map (untuk Firestore)
  Map<String, dynamic> toMap() {
    return {
      'nama_pengguna': namaPengguna,
      'nama_lengkap': namaLengkap,
      'email': email,
      'peran': peran,
      'aktif': aktif,
      'dibuat_pada': dibuatPada,
      'diubah_pada': diubahPada,
    };
  }

  // Method untuk membuat copy dengan perubahan
  UserModel copyWith({
    String? idPengguna,
    String? namaPengguna,
    String? namaLengkap,
    String? email,
    String? peran,
    bool? aktif,
    DateTime? dibuatPada,
    DateTime? diubahPada,
  }) {
    return UserModel(
      idPengguna: idPengguna ?? this.idPengguna,
      namaPengguna: namaPengguna ?? this.namaPengguna,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      email: email ?? this.email,
      peran: peran ?? this.peran,
      aktif: aktif ?? this.aktif,
      dibuatPada: dibuatPada ?? this.dibuatPada,
      diubahPada: diubahPada ?? this.diubahPada,
    );
  }

  @override
  String toString() {
    return 'UserModel(idPengguna: $idPengguna, namaPengguna: $namaPengguna, namaLengkap: $namaLengkap, email: $email, peran: $peran, aktif: $aktif)';
  }
}