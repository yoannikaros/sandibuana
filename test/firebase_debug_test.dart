import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/debug/firebase_test.dart';
import '../lib/firebase_options.dart';

void main() {
  group('Firebase Debug Tests', () {
    setUpAll(() async {
      // Initialize Firebase for testing
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    });

    test('Test Firebase Connection', () async {
      await FirebaseTest.testFirebaseConnection();
    });

    test('Test User Creation', () async {
      await FirebaseTest.testCreateUser(
        email: 'test@sandibuana.com',
        password: 'test123456',
        namaPengguna: 'testuser',
        namaLengkap: 'Test User',
      );
    });

    test('Test Login', () async {
      await FirebaseTest.testLogin(
        email: 'test@sandibuana.com',
        password: 'test123456',
      );
    });

    tearDownAll(() async {
      await FirebaseTest.cleanupTestData();
    });
  });
}