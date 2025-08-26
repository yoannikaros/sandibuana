import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/user_session_model.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';

class AuthProvider with ChangeNotifier, WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  final SessionService _sessionService = SessionService();
  
  UserModel? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _rememberMe = false;
  bool _isFirstInitialization = true;
  
  // Stream subscription untuk auth state changes
  StreamSubscription<User?>? _authStateSubscription;

  // Getters
  UserModel? get user => _user;
  UserModel? get currentUser => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  // Stream untuk mendengarkan perubahan auth state
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  AuthProvider() {
    WidgetsBinding.instance.addObserver(this);
    initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authStateSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _user != null) {
      // Update last activity when app resumes
      _updateSessionActivity();
    }
  }

  // Update session activity when app resumes
  Future<void> _updateSessionActivity() async {
    try {
      if (_user?.idPengguna != null && _user!.idPengguna.isNotEmpty) {
        await _sessionService.updateLastActivity(_user!.idPengguna);
      }
    } catch (e) {
      print('Error updating session activity: $e');
      // Jangan throw error untuk menghindari crash aplikasi
    }
  }

  // Initialize provider
  Future<void> initialize() async {
    try {
      _setLoading(true);
      _setError(null);
      
      // Only cleanup expired sessions on first initialization
      // to prevent logout when app resumes from background
      if (_isFirstInitialization) {
        try {
          await _sessionService.cleanupExpiredSessions();
        } catch (e) {
          print('Warning: Failed to cleanup expired sessions: $e');
          // Continue initialization even if cleanup fails
        }
        _isFirstInitialization = false;
      }
      
      // Check for existing session
      try {
        final existingSession = await _sessionService.getActiveSession();
        if (existingSession != null) {
          // Try to restore session
          await _restoreSession(existingSession);
        }
      } catch (e) {
        print('Warning: Failed to restore session: $e');
        // Continue initialization even if session restore fails
      }
      
      // Listen to auth state changes
      _authStateSubscription = _authService.authStateChanges.listen((User? user) async {
        if (user != null) {
          // User is signed in, get user data
          try {
            _user = await _authService.getUserData(user.uid);
            if (_user != null && !_user!.aktif) {
              // User is inactive, sign out
              await _authService.signOut();
              await _sessionService.clearUserSessions(user.uid);
              _user = null;
              _setError('Akun Anda tidak aktif. Hubungi administrator.');
            }
          } catch (e) {
            print('Error getting user data: $e');
            _user = null;
            if (e.toString().contains('permission-denied')) {
              await handlePermissionDenied();
            }
          }
        } else {
          // User is signed out
          _user = null;
        }
        
        notifyListeners();
      });
      
      _isInitialized = true;
      _setLoading(false);
    } catch (e) {
      print('Critical error during initialization: $e');
      _setError('Gagal menginisialisasi aplikasi. Silakan restart aplikasi.');
      _setLoading(false);
      _isInitialized = false;
    }
  }

  // Restore session from SQLite
  Future<void> _restoreSession(UserSessionModel session) async {
    try {
      // Check if session is still valid
      if (session.isExpired) {
        await _sessionService.clearSession(session.sessionId);
        return;
      }

      // Try to get current Firebase user
      final currentUser = _authService.currentUser;
      if (currentUser != null && currentUser.uid == session.userId) {
        // Session is valid, restore user data
        _user = await _authService.getUserData(session.userId);
        _rememberMe = session.rememberMe;
        
        // Update session last activity
        await _sessionService.updateSessionActivity(session.sessionId);
      } else {
        // Session is invalid, clear it
        await _sessionService.clearSession(session.sessionId);
      }
    } catch (e) {
      print('Error restoring session: $e');
      await _sessionService.clearSession(session.sessionId);
    }
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
    bool rememberMe = false,
  }) async {
    // Validasi input
    if (email.trim().isEmpty) {
      _setError('Email tidak boleh kosong');
      return false;
    }
    
    if (password.trim().isEmpty) {
      _setError('Password tidak boleh kosong');
      return false;
    }
    
    if (!_authService.isValidEmail(email.trim())) {
      _setError('Format email tidak valid');
      return false;
    }
    
    try {
      _setLoading(true);
      _setError(null);

      _user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (_user != null) {
        // Save session to SQLite
        _rememberMe = rememberMe;
        await _sessionService.saveSession(
          user: _user!,
          rememberMe: rememberMe,
        );
      }

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
    bool rememberMe = false,
  }) async {
    // Validasi input
    if (username.trim().isEmpty) {
      _setError('Username tidak boleh kosong');
      return false;
    }
    
    if (password.trim().isEmpty) {
      _setError('Password tidak boleh kosong');
      return false;
    }
    
    if (!_authService.isValidUsername(username.trim())) {
      _setError('Format username tidak valid. Gunakan minimal 3 karakter (huruf, angka, underscore)');
      return false;
    }
    
    try {
      _setLoading(true);
      _setError(null);

      _user = await _authService.signInWithUsernameAndPassword(
        username: username,
        password: password,
      );

      if (_user != null) {
        // Save session to SQLite
        _rememberMe = rememberMe;
        await _sessionService.saveSession(
          user: _user!,
          rememberMe: rememberMe,
        );
      }

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
      
      // Clear sessions from SQLite
      if (_user != null) {
        await _sessionService.clearUserSessions(_user!.idPengguna);
      }
      
      await _authService.signOut();
      _rememberMe = false;
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

  // Auto logout when permission denied
  Future<void> handlePermissionDenied() async {
    try {
      _setError('Sesi login telah berakhir. Silakan login kembali.');
      
      // Clear sessions from SQLite
      if (_user != null) {
        await _sessionService.clearUserSessions(_user!.idPengguna);
      }
      
      await _authService.signOut();
      _rememberMe = false;
    } catch (e) {
      print('Error during auto logout: $e');
    }
  }

  // Check if auto-login is enabled
  bool get hasRememberMe => _rememberMe;

  // Get current session info
  Future<UserSessionModel?> getCurrentSession() async {
    return await _sessionService.getActiveSession();
  }

  // Clear expired sessions manually
  Future<void> clearExpiredSessions() async {
    await _sessionService.cleanupExpiredSessions();
  }
}