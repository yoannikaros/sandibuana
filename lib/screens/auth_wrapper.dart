import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as custom;
import 'login_screen.dart';
import 'home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<custom.AuthProvider>(
      builder: (context, authProvider, child) {
        // Show error if AuthProvider has error
        if (authProvider.errorMessage != null) {
          return _buildErrorScreen(
            context,
            'Terjadi Kesalahan',
            authProvider.errorMessage!,
          );
        }

        // Show loading if AuthProvider is loading
        if (authProvider.isLoading) {
          return _buildLoadingScreen('Memuat...');
        }

        return StreamBuilder<User?>(
          stream: authProvider.authStateChanges,
          builder: (context, snapshot) {
            // Handle connection errors
            if (snapshot.hasError) {
              return _buildErrorScreen(
                context,
                'Terjadi kesalahan koneksi',
                snapshot.error.toString(),
              );
            }

            // Show loading while checking auth state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingScreen('Memeriksa status login...');
            }

            // Check if user is logged in and user data is available
            final firebaseUser = snapshot.data;
            final userData = authProvider.user;

            if (firebaseUser != null) {
              // If Firebase user exists but userData is null, wait for it to load
              if (userData == null) {
                return _buildLoadingScreen('Memuat data pengguna...');
              }
              
              // Check if user account is active
              if (!userData.aktif) {
                // Auto logout if account is inactive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  authProvider.logout();
                });
                return _buildErrorScreen(
                  context,
                  'Akun Tidak Aktif',
                  'Akun Anda telah dinonaktifkan. Hubungi administrator untuk informasi lebih lanjut.',
                );
              }
              
              // User is logged in and active, show home screen
              return const HomeScreen();
            } else {
              // User is not logged in, show login screen
              return const LoginScreen();
            }
          },
        );
      },
    );
  }

  Widget _buildLoadingScreen(String message) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.green.shade600,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sandi Buana Hidroponik',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, String title, String message) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Clear error and try again
                  final authProvider = Provider.of<custom.AuthProvider>(context, listen: false);
                  authProvider.clearError();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}