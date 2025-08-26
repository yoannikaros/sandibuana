import 'package:sqflite/sqflite.dart';
import '../models/user_session_model.dart';
import '../models/user_model.dart';
import 'database_helper.dart';

class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Simpan session login
  Future<bool> saveSession({
    required UserModel user,
    required bool rememberMe,
  }) async {
    try {
      final db = await _dbHelper.database;
      
      // Hapus session lama terlebih dahulu
      await clearAllSessions();
      
      final session = UserSessionModel(
        userId: user.idPengguna,
        email: user.email ?? '',
        username: user.namaPengguna,
        namaLengkap: user.namaLengkap,
        peran: user.peran,
        rememberMe: rememberMe,
        loginTime: DateTime.now(),
        lastActivity: DateTime.now(),
        isActive: true,
      );
      
      await db.insert('user_session', session.toMap());
      return true;
    } catch (e) {
      print('Error saving session: $e');
      return false;
    }
  }

  // Ambil session yang aktif
  Future<UserSessionModel?> getActiveSession() async {
    try {
      final db = await _dbHelper.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'user_session',
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'login_time DESC',
        limit: 1,
      );
      
      if (maps.isNotEmpty) {
        final session = UserSessionModel.fromMap(maps.first);
        
        // Periksa apakah session masih valid
        if (await _isSessionValid(session)) {
          // Update last activity
          await _updateLastActivity(session.id!);
          return session;
        } else {
          // Session expired, hapus
          await clearSession(session.id!);
          return null;
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting active session: $e');
      return null;
    }
  }

  // Periksa apakah session masih valid
  Future<bool> _isSessionValid(UserSessionModel session) async {
    final now = DateTime.now();
    final lastActivity = session.lastActivity;
    
    // Jika remember me aktif, session berlaku 30 hari
    if (session.rememberMe) {
      final maxAge = Duration(days: 30);
      return now.difference(session.loginTime) < maxAge;
    } else {
      // Jika tidak remember me, session berlaku 24 jam dari last activity
      final maxInactivity = Duration(hours: 24);
      return now.difference(lastActivity) < maxInactivity;
    }
  }

  // Update last activity
  Future<bool> _updateLastActivity(int sessionId) async {
    try {
      final db = await _dbHelper.database;
      
      await db.update(
        'user_session',
        {'last_activity': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [sessionId],
      );
      
      return true;
    } catch (e) {
      print('Error updating last activity: $e');
      return false;
    }
  }

  // Update last activity berdasarkan user ID
  Future<bool> updateLastActivity(String userId) async {
    try {
      final db = await _dbHelper.database;
      
      await db.update(
        'user_session',
        {'last_activity': DateTime.now().toIso8601String()},
        where: 'user_id = ? AND is_active = ?',
        whereArgs: [userId, 1],
      );
      
      return true;
    } catch (e) {
      print('Error updating last activity: $e');
      return false;
    }
  }

  // Update session activity berdasarkan session ID
  Future<bool> updateSessionActivity(int sessionId) async {
    try {
      final db = await _dbHelper.database;
      
      await db.update(
        'user_session',
        {'last_activity': DateTime.now().toIso8601String()},
        where: 'id = ? AND is_active = ?',
        whereArgs: [sessionId, 1],
      );
      
      return true;
    } catch (e) {
      print('Error updating session activity: $e');
      return false;
    }
  }

  // Hapus session tertentu
  Future<bool> clearSession(int sessionId) async {
    try {
      final db = await _dbHelper.database;
      
      await db.update(
        'user_session',
        {'is_active': 0},
        where: 'id = ?',
        whereArgs: [sessionId],
      );
      
      return true;
    } catch (e) {
      print('Error clearing session: $e');
      return false;
    }
  }

  // Hapus semua session
  Future<bool> clearAllSessions() async {
    try {
      final db = await _dbHelper.database;
      
      await db.update(
        'user_session',
        {'is_active': 0},
        where: 'is_active = ?',
        whereArgs: [1],
      );
      
      return true;
    } catch (e) {
      print('Error clearing all sessions: $e');
      return false;
    }
  }

  // Hapus session berdasarkan user ID
  Future<bool> clearUserSessions(String userId) async {
    try {
      final db = await _dbHelper.database;
      
      await db.update(
        'user_session',
        {'is_active': 0},
        where: 'user_id = ? AND is_active = ?',
        whereArgs: [userId, 1],
      );
      
      return true;
    } catch (e) {
      print('Error clearing user sessions: $e');
      return false;
    }
  }

  // Periksa apakah ada session aktif
  Future<bool> hasActiveSession() async {
    final session = await getActiveSession();
    return session != null;
  }

  // Bersihkan session yang expired
  Future<void> cleanupExpiredSessions() async {
    try {
      final db = await _dbHelper.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'user_session',
        where: 'is_active = ?',
        whereArgs: [1],
      );
      
      for (final map in maps) {
        final session = UserSessionModel.fromMap(map);
        if (!await _isSessionValid(session)) {
          await clearSession(session.id!);
        }
      }
    } catch (e) {
      print('Error cleaning up expired sessions: $e');
    }
  }

  // Ambil semua session (untuk debugging)
  Future<List<UserSessionModel>> getAllSessions() async {
    try {
      final db = await _dbHelper.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'user_session',
        orderBy: 'login_time DESC',
      );
      
      return List.generate(maps.length, (i) {
        return UserSessionModel.fromMap(maps[i]);
      });
    } catch (e) {
      print('Error getting all sessions: $e');
      return [];
    }
  }
}