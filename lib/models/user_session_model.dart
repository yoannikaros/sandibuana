class UserSessionModel {
  final int? id;
  final String userId;
  final String email;
  final String username;
  final String namaLengkap;
  final String peran;
  final bool rememberMe;
  final DateTime loginTime;
  final DateTime lastActivity;
  final bool isActive;

  // Getter untuk session ID
  int get sessionId => id ?? 0;

  // Getter untuk mengecek apakah session expired
  bool get isExpired {
    final now = DateTime.now();
    
    if (rememberMe) {
      // Jika remember me aktif, session berlaku 30 hari
      final maxAge = Duration(days: 30);
      return now.difference(loginTime) >= maxAge;
    } else {
      // Jika tidak remember me, session berlaku 24 jam dari last activity
      final maxInactivity = Duration(hours: 24);
      return now.difference(lastActivity) >= maxInactivity;
    }
  }

  UserSessionModel({
    this.id,
    required this.userId,
    required this.email,
    required this.username,
    required this.namaLengkap,
    required this.peran,
    required this.rememberMe,
    required this.loginTime,
    required this.lastActivity,
    required this.isActive,
  });

  factory UserSessionModel.fromMap(Map<String, dynamic> map) {
    return UserSessionModel(
      id: map['id'],
      userId: map['user_id'],
      email: map['email'],
      username: map['username'],
      namaLengkap: map['nama_lengkap'],
      peran: map['peran'],
      rememberMe: map['remember_me'] == 1,
      loginTime: DateTime.parse(map['login_time']),
      lastActivity: DateTime.parse(map['last_activity']),
      isActive: map['is_active'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'email': email,
      'username': username,
      'nama_lengkap': namaLengkap,
      'peran': peran,
      'remember_me': rememberMe ? 1 : 0,
      'login_time': loginTime.toIso8601String(),
      'last_activity': lastActivity.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  UserSessionModel copyWith({
    int? id,
    String? userId,
    String? email,
    String? username,
    String? namaLengkap,
    String? peran,
    bool? rememberMe,
    DateTime? loginTime,
    DateTime? lastActivity,
    bool? isActive,
  }) {
    return UserSessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      username: username ?? this.username,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      peran: peran ?? this.peran,
      rememberMe: rememberMe ?? this.rememberMe,
      loginTime: loginTime ?? this.loginTime,
      lastActivity: lastActivity ?? this.lastActivity,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'UserSessionModel(id: $id, userId: $userId, email: $email, username: $username, namaLengkap: $namaLengkap, peran: $peran, rememberMe: $rememberMe, loginTime: $loginTime, lastActivity: $lastActivity, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserSessionModel &&
        other.id == id &&
        other.userId == userId &&
        other.email == email &&
        other.username == username &&
        other.namaLengkap == namaLengkap &&
        other.peran == peran &&
        other.rememberMe == rememberMe &&
        other.loginTime == loginTime &&
        other.lastActivity == lastActivity &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        email.hashCode ^
        username.hashCode ^
        namaLengkap.hashCode ^
        peran.hashCode ^
        rememberMe.hashCode ^
        loginTime.hashCode ^
        lastActivity.hashCode ^
        isActive.hashCode;
  }
}