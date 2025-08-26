import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService() {
    // Set persistence hanya untuk platform web
    // setPersistence() tidak didukung di platform mobile
    // _auth.setPersistence(Persistence.LOCAL);
  }

  // Stream untuk mendengarkan perubahan status authentication
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Register dengan email dan password
  Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String namaPengguna,
    required String namaLengkap,
    String peran = 'operator',
  }) async {
    try {
      // Cek apakah username sudah digunakan
      final usernameQuery = await _firestore
          .collection('pengguna')
          .where('nama_pengguna', isEqualTo: namaPengguna)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        throw Exception('Username sudah digunakan');
      }

      // Buat akun Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        // Simpan data user ke Firestore
        final userData = {
          'nama_pengguna': namaPengguna,
          'nama_lengkap': namaLengkap,
          'email': email,
          'peran': peran,
          'aktif': true,
          'dibuat_pada': FieldValue.serverTimestamp(),
          'diubah_pada': FieldValue.serverTimestamp(),
        };

        await _firestore.collection('pengguna').doc(user.uid).set(userData);

        // Update display name
        await user.updateDisplayName(namaLengkap);

        // Ambil data user yang baru dibuat
        return await getUserData(user.uid);
      }
      return null;
    } catch (e) {
      print('Register error: $e');
      if (e.toString().contains('permission-denied')) {
        throw Exception('Akses ditolak. Pastikan Firestore rules sudah dikonfigurasi dengan benar.');
      } else if (e.toString().contains('email-already-in-use')) {
        throw Exception('Email sudah digunakan oleh akun lain.');
      } else if (e.toString().contains('weak-password')) {
        throw Exception('Password terlalu lemah. Gunakan minimal 6 karakter.');
      } else if (e.toString().contains('invalid-email')) {
        throw Exception('Format email tidak valid.');
      }
      throw Exception('Gagal mendaftar: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // Login dengan email dan password
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        // Ambil data user dari Firestore
        UserModel? userData = await getUserData(user.uid);
        
        if (userData != null && !userData.aktif) {
          await signOut();
          throw Exception('Akun Anda tidak aktif. Hubungi administrator.');
        }
        
        return userData;
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      if (e.toString().contains('permission-denied')) {
        throw Exception('Akses ditolak. Pastikan Firestore rules sudah dikonfigurasi dengan benar.');
      } else if (e.toString().contains('user-not-found')) {
        throw Exception('Email tidak terdaftar.');
      } else if (e.toString().contains('wrong-password')) {
        throw Exception('Password salah.');
      } else if (e.toString().contains('invalid-email')) {
        throw Exception('Format email tidak valid.');
      } else if (e.toString().contains('user-disabled')) {
        throw Exception('Akun telah dinonaktifkan.');
      }
      throw Exception('Gagal masuk: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // Login dengan username dan password
  Future<UserModel?> signInWithUsernameAndPassword({
    required String username,
    required String password,
  }) async {
    try {
      // Cari email berdasarkan username
      final usernameQuery = await _firestore
          .collection('pengguna')
          .where('nama_pengguna', isEqualTo: username)
          .limit(1)
          .get();

      if (usernameQuery.docs.isEmpty) {
        throw Exception('Username tidak ditemukan');
      }

      final userDoc = usernameQuery.docs.first;
      final email = userDoc.data()['email'] as String?;

      if (email == null) {
        throw Exception('Email tidak ditemukan untuk username ini');
      }

      // Login dengan email
      return await signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Login with username error: $e');
      if (e.toString().contains('permission-denied')) {
        throw Exception('Akses ditolak. Pastikan Firestore rules sudah dikonfigurasi dengan benar.');
      } else if (e.toString().contains('user-not-found')) {
        throw Exception('Username tidak ditemukan.');
      }
      throw Exception('Gagal masuk: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // Ambil data user dari Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      // Pastikan user sudah terautentikasi sebelum mengakses Firestore
      if (_auth.currentUser == null) {
        throw Exception('User tidak terautentikasi');
      }
      
      DocumentSnapshot doc = await _firestore.collection('pengguna').doc(uid).get();
      
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      if (e.toString().contains('permission-denied')) {
        print('Permission denied - pastikan Firestore rules sudah benar dan user terautentikasi');
        throw Exception('Akses ditolak. Pastikan Anda sudah login dan memiliki izin akses.');
      }
      return null;
    }
  }

  // Update data user
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      data['diubah_pada'] = FieldValue.serverTimestamp();
      await _firestore.collection('pengguna').doc(uid).update(data);
    } catch (e) {
      throw Exception('Gagal mengupdate data: ${e.toString()}');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Gagal mengirim email reset password: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Gagal keluar: ${e.toString()}');
    }
  }

  // Validasi email
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validasi password
  bool isValidPassword(String password) {
    // Minimal 6 karakter
    return password.length >= 6;
  }

  // Validasi username
  bool isValidUsername(String username) {
    // Minimal 3 karakter, hanya huruf, angka, dan underscore
    return RegExp(r'^[a-zA-Z0-9_]{3,}$').hasMatch(username);
  }
}