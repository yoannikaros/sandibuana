import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      throw Exception('Gagal mendaftar: ${e.toString()}');
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

        // Simpan status login
        await _saveLoginStatus(true);
        
        return userData;
      }
      return null;
    } catch (e) {
      throw Exception('Gagal masuk: ${e.toString()}');
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
      throw Exception('Gagal masuk: ${e.toString()}');
    }
  }

  // Ambil data user dari Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('pengguna').doc(uid).get();
      
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
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
      await _saveLoginStatus(false);
    } catch (e) {
      throw Exception('Gagal keluar: ${e.toString()}');
    }
  }

  // Simpan status login ke SharedPreferences
  Future<void> _saveLoginStatus(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn);
  }

  // Cek status login dari SharedPreferences
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
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