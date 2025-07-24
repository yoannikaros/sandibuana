import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get user => _user;
  UserModel? get currentUser => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  // Stream untuk mendengarkan perubahan auth state
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  AuthProvider() {
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    // Listen to auth state changes with error handling
    _authService.authStateChanges.listen(
      (User? user) async {
        try {
          if (user != null) {
            _user = await _authService.getUserData(user.uid);
          } else {
            _user = null;
          }
          notifyListeners();
        } catch (e) {
          print('Error in auth state listener: $e');
          _setError('Terjadi kesalahan saat memuat data pengguna');
        }
      },
      onError: (error) {
        print('Auth state stream error: $error');
        _setError('Terjadi kesalahan koneksi');
      },
    );
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Register
  Future<bool> register({
    required String email,
    required String password,
    required String namaPengguna,
    required String namaLengkap,
    String peran = 'operator',
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      _user = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        namaPengguna: namaPengguna,
        namaLengkap: namaLengkap,
        peran: peran,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  // Login dengan email
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      // Validasi login dihapus

      _user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  // Login dengan username
  Future<bool> loginWithUsername({
    required String username,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      // Validasi login username dihapus

      _user = await _authService.signInWithUsernameAndPassword(
        username: username,
        password: password,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _setError(null);

      // Validasi reset password dihapus

      await _authService.resetPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      _setLoading(true);
      await _authService.signOut();
      _user = null;
      _setLoading(false);
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      _setLoading(false);
    }
  }

  // Update user data
  Future<bool> updateUserData(Map<String, dynamic> data) async {
    try {
      if (_user == null) return false;
      
      _setLoading(true);
      _setError(null);

      await _authService.updateUserData(_user!.idPengguna, data);
      
      // Refresh user data
      _user = await _authService.getUserData(_user!.idPengguna);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  // Check if user is admin
  bool get isAdmin => _user?.peran == 'admin';

  // Check if user is operator
  bool get isOperator => _user?.peran == 'operator';
}