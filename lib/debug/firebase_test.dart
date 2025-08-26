import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

class FirebaseTest {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Test Firebase connection
  static Future<void> testFirebaseConnection() async {
    try {
      print('=== Testing Firebase Connection ===');
      
      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('✅ Firebase initialized successfully');
      } else {
        print('✅ Firebase already initialized');
      }
      
      // Test Firestore connection
      await _testFirestoreConnection();
      
      // Test Authentication
      await _testAuthentication();
      
    } catch (e) {
      print('❌ Firebase connection test failed: $e');
    }
  }
  
  // Test Firestore connection
  static Future<void> _testFirestoreConnection() async {
    try {
      print('\n=== Testing Firestore Connection ===');
      
      // Try to read from a simple collection
      final testDoc = await _firestore.collection('test').doc('connection').get();
      print('✅ Firestore connection successful');
      
      // Test writing (if authenticated)
      if (_auth.currentUser != null) {
        await _firestore.collection('test').doc('connection').set({
          'timestamp': FieldValue.serverTimestamp(),
          'test': 'connection_test'
        });
        print('✅ Firestore write test successful');
      }
      
    } catch (e) {
      print('❌ Firestore connection failed: $e');
      if (e.toString().contains('permission-denied')) {
        print('🔍 Permission denied - check Firestore rules');
      }
    }
  }
  
  // Test Authentication
  static Future<void> _testAuthentication() async {
    try {
      print('\n=== Testing Authentication ===');
      
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        print('✅ User is authenticated: ${currentUser.email}');
        print('   UID: ${currentUser.uid}');
        
        // Test reading user data from Firestore
        try {
          final userDoc = await _firestore.collection('pengguna').doc(currentUser.uid).get();
          if (userDoc.exists) {
            print('✅ User data found in Firestore');
            final userData = userDoc.data();
            print('   User data: $userData');
          } else {
            print('⚠️  User authenticated but no data in Firestore');
          }
        } catch (e) {
          print('❌ Failed to read user data: $e');
        }
      } else {
        print('⚠️  No user is currently authenticated');
      }
      
    } catch (e) {
      print('❌ Authentication test failed: $e');
    }
  }
  
  // Test creating a test user (for debugging)
  static Future<void> testCreateUser({
    required String email,
    required String password,
    required String namaPengguna,
    required String namaLengkap,
  }) async {
    try {
      print('\n=== Testing User Creation ===');
      
      // Create user with Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user;
      if (user != null) {
        print('✅ User created in Firebase Auth: ${user.email}');
        
        // Try to save user data to Firestore
        try {
          await _firestore.collection('pengguna').doc(user.uid).set({
            'nama_pengguna': namaPengguna,
            'nama_lengkap': namaLengkap,
            'email': email,
            'peran': 'operator',
            'aktif': true,
            'dibuat_pada': FieldValue.serverTimestamp(),
            'diubah_pada': FieldValue.serverTimestamp(),
          });
          print('✅ User data saved to Firestore');
        } catch (e) {
          print('❌ Failed to save user data to Firestore: $e');
          // Clean up - delete the auth user if Firestore save failed
          await user.delete();
          print('🧹 Cleaned up auth user due to Firestore error');
        }
      }
      
    } catch (e) {
      print('❌ User creation failed: $e');
      if (e.toString().contains('permission-denied')) {
        print('🔍 Permission denied - check Firestore rules');
      }
    }
  }
  
  // Test login
  static Future<void> testLogin({
    required String email,
    required String password,
  }) async {
    try {
      print('\n=== Testing Login ===');
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user;
      if (user != null) {
        print('✅ Login successful: ${user.email}');
        
        // Test reading user data
        try {
          final userDoc = await _firestore.collection('pengguna').doc(user.uid).get();
          if (userDoc.exists) {
            print('✅ User data retrieved from Firestore');
            final userData = userDoc.data();
            print('   User data: $userData');
          } else {
            print('⚠️  User logged in but no data in Firestore');
          }
        } catch (e) {
          print('❌ Failed to read user data after login: $e');
        }
      }
      
    } catch (e) {
      print('❌ Login failed: $e');
    }
  }
  
  // Clean up test data
  static Future<void> cleanupTestData() async {
    try {
      print('\n=== Cleaning up test data ===');
      
      // Delete test document
      await _firestore.collection('test').doc('connection').delete();
      print('✅ Test data cleaned up');
      
    } catch (e) {
      print('❌ Cleanup failed: $e');
    }
  }
}