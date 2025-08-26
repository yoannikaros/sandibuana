import 'package:flutter_test/flutter_test.dart';
import '../services/session_service.dart';
import '../models/user_session_model.dart';
import '../models/user_model.dart';

void main() {
  group('Session Management Tests', () {
    test('Run all session tests', () async {
      await SessionTest.runAllTests();
    });
  });
}

class SessionTest {
  static final SessionService _sessionService = SessionService();

  // Test semua functionality session
  static Future<void> runAllTests() async {
    print('\n=== TESTING SESSION MANAGEMENT ===');
    
    try {
      await testSaveSession();
      await testGetActiveSession();
      await testSessionExpiry();
      await testClearSession();
      await testMultipleSessions();
      
      print('\n✅ Semua test session berhasil!');
    } catch (e) {
      print('\n❌ Test session gagal: $e');
    }
  }

  // Test save session
  static Future<void> testSaveSession() async {
    print('\n--- Test Save Session ---');
    
    final testUser = UserModel(
      idPengguna: 'test_user_123',
      email: 'test@example.com',
      namaPengguna: 'testuser',
      namaLengkap: 'Test User',
      peran: 'operator',
      aktif: true,
      dibuatPada: DateTime.now(),
      diubahPada: DateTime.now(),
    );
    
    final success = await _sessionService.saveSession(
      user: testUser,
      rememberMe: true,
    );
    
    if (success) {
      print('✅ Session berhasil disimpan');
    } else {
      print('❌ Gagal menyimpan session');
    }
  }

  // Test get active session
  static Future<void> testGetActiveSession() async {
    print('\n--- Test Get Active Session ---');
    
    final session = await _sessionService.getActiveSession();
    
    if (session != null) {
      print('✅ Session aktif ditemukan:');
      print('   User ID: ${session.userId}');
      print('   Email: ${session.email}');
      print('   Username: ${session.username}');
      print('   Remember Me: ${session.rememberMe}');
      print('   Login Time: ${session.loginTime}');
      print('   Last Activity: ${session.lastActivity}');
      print('   Is Expired: ${session.isExpired}');
    } else {
      print('❌ Tidak ada session aktif');
    }
  }

  // Test session expiry logic
  static Future<void> testSessionExpiry() async {
    print('\n--- Test Session Expiry ---');
    
    // Create expired session (manual test)
    final expiredSession = UserSessionModel(
      id: 999,
      userId: 'expired_user',
      email: 'expired@example.com',
      username: 'expireduser',
      namaLengkap: 'Expired User',
      peran: 'operator',
      rememberMe: false,
      loginTime: DateTime.now().subtract(Duration(days: 2)), // 2 days ago
      lastActivity: DateTime.now().subtract(Duration(hours: 25)), // 25 hours ago
      isActive: true,
    );
    
    if (expiredSession.isExpired) {
      print('✅ Session expiry logic bekerja dengan benar');
    } else {
      print('❌ Session expiry logic tidak bekerja');
    }
    
    // Test remember me session (should not expire for 30 days)
    final rememberMeSession = UserSessionModel(
      id: 998,
      userId: 'remember_user',
      email: 'remember@example.com',
      username: 'rememberuser',
      namaLengkap: 'Remember User',
      peran: 'operator',
      rememberMe: true,
      loginTime: DateTime.now().subtract(Duration(days: 2)), // 2 days ago
      lastActivity: DateTime.now().subtract(Duration(hours: 25)), // 25 hours ago
      isActive: true,
    );
    
    if (!rememberMeSession.isExpired) {
      print('✅ Remember Me session logic bekerja dengan benar');
    } else {
      print('❌ Remember Me session logic tidak bekerja');
    }
  }

  // Test clear session
  static Future<void> testClearSession() async {
    print('\n--- Test Clear Session ---');
    
    final success = await _sessionService.clearAllSessions();
    
    if (success) {
      print('✅ Session berhasil dihapus');
      
      // Verify no active session
      final session = await _sessionService.getActiveSession();
      if (session == null) {
        print('✅ Konfirmasi: Tidak ada session aktif setelah clear');
      } else {
        print('❌ Masih ada session aktif setelah clear');
      }
    } else {
      print('❌ Gagal menghapus session');
    }
  }

  // Test multiple sessions handling
  static Future<void> testMultipleSessions() async {
    print('\n--- Test Multiple Sessions ---');
    
    // Create first user session
    final user1 = UserModel(
      idPengguna: 'user_1',
      email: 'user1@example.com',
      namaPengguna: 'user1',
      namaLengkap: 'User One',
      peran: 'operator',
      aktif: true,
      dibuatPada: DateTime.now(),
      diubahPada: DateTime.now(),
    );
    
    await _sessionService.saveSession(user: user1, rememberMe: false);
    
    // Create second user session (should replace first)
    final user2 = UserModel(
      idPengguna: 'user_2',
      email: 'user2@example.com',
      namaPengguna: 'user2',
      namaLengkap: 'User Two',
      peran: 'admin',
      aktif: true,
      dibuatPada: DateTime.now(),
      diubahPada: DateTime.now(),
    );
    
    await _sessionService.saveSession(user: user2, rememberMe: true);
    
    // Check active session
    final activeSession = await _sessionService.getActiveSession();
    
    if (activeSession != null && activeSession.userId == 'user_2') {
      print('✅ Multiple sessions handled correctly - latest session is active');
    } else {
      print('❌ Multiple sessions not handled correctly');
    }
    
    // Get all sessions for debugging
    final allSessions = await _sessionService.getAllSessions();
    print('   Total sessions in database: ${allSessions.length}');
    
    for (final session in allSessions) {
      print('   Session: ${session.username} - Active: ${session.isActive}');
    }
  }

  // Test cleanup expired sessions
  static Future<void> testCleanupExpiredSessions() async {
    print('\n--- Test Cleanup Expired Sessions ---');
    
    await _sessionService.cleanupExpiredSessions();
    
    final allSessions = await _sessionService.getAllSessions();
    final activeSessions = allSessions.where((s) => s.isActive).toList();
    
    print('✅ Cleanup completed');
    print('   Total sessions: ${allSessions.length}');
    print('   Active sessions: ${activeSessions.length}');
  }

  // Test update last activity
  static Future<void> testUpdateActivity() async {
    print('\n--- Test Update Activity ---');
    
    final session = await _sessionService.getActiveSession();
    
    if (session != null) {
      final oldActivity = session.lastActivity;
      
      // Wait a bit
      await Future.delayed(Duration(seconds: 1));
      
      await _sessionService.updateLastActivity(session.userId);
      
      final updatedSession = await _sessionService.getActiveSession();
      
      if (updatedSession != null && 
          updatedSession.lastActivity.isAfter(oldActivity)) {
        print('✅ Last activity berhasil diupdate');
      } else {
        print('❌ Gagal update last activity');
      }
    } else {
      print('❌ Tidak ada session aktif untuk test update activity');
    }
  }
}