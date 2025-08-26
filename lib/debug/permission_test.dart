import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class PermissionTestScreen extends StatefulWidget {
  const PermissionTestScreen({Key? key}) : super(key: key);

  @override
  State<PermissionTestScreen> createState() => _PermissionTestScreenState();
}

class _PermissionTestScreenState extends State<PermissionTestScreen> {
  final AuthService _authService = AuthService();
  String _testResult = 'Belum ada test';
  bool _isLoading = false;

  Future<void> _testFirebaseConnection() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing Firebase connection...';
    });

    try {
      // Test 1: Check current user
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _testResult = 'ERROR: User tidak terautentikasi. Silakan login terlebih dahulu.';
          _isLoading = false;
        });
        return;
      }

      String result = 'Test Firebase Connection:\n';
      result += 'User ID: ${currentUser.uid}\n';
      result += 'Email: ${currentUser.email}\n';
      result += 'Email Verified: ${currentUser.emailVerified}\n\n';

      // Test 2: Try to read from pengguna collection
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('pengguna')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          result += 'READ pengguna: SUCCESS\n';
          result += 'Data: ${userDoc.data()}\n\n';
        } else {
          result += 'READ pengguna: Document tidak ditemukan\n\n';
        }
      } catch (e) {
        result += 'READ pengguna: ERROR - $e\n\n';
      }

      // Test 3: Try to write to pengguna collection
      try {
        await FirebaseFirestore.instance
            .collection('pengguna')
            .doc(currentUser.uid)
            .set({
          'test_timestamp': FieldValue.serverTimestamp(),
          'test_message': 'Permission test successful'
        }, SetOptions(merge: true));
        
        result += 'WRITE pengguna: SUCCESS\n\n';
      } catch (e) {
        result += 'WRITE pengguna: ERROR - $e\n\n';
      }

      // Test 4: Try to read from pelanggan collection
      try {
        QuerySnapshot pelangganQuery = await FirebaseFirestore.instance
            .collection('pelanggan')
            .limit(1)
            .get();
        
        result += 'READ pelanggan: SUCCESS (${pelangganQuery.docs.length} documents)\n\n';
      } catch (e) {
        result += 'READ pelanggan: ERROR - $e\n\n';
      }

      // Test 5: Try to write to pelanggan collection
      try {
        await FirebaseFirestore.instance
            .collection('pelanggan')
            .add({
          'nama': 'Test Permission',
          'created_at': FieldValue.serverTimestamp(),
          'test_data': true
        });
        
        result += 'WRITE pelanggan: SUCCESS\n\n';
      } catch (e) {
        result += 'WRITE pelanggan: ERROR - $e\n\n';
      }

      setState(() {
        _testResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResult = 'GENERAL ERROR: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testFirebaseConnection,
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Test Firebase Permission'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _testResult,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}