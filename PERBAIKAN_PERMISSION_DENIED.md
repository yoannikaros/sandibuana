# Perbaikan Error Permission Denied Firebase

## Masalah
Aplikasi mengalami error "permission denied" saat melakukan login atau register ke Cloud Firestore.

## Penyebab Umum
1. **Firestore Rules tidak dikonfigurasi dengan benar**
2. **User belum terautentikasi saat mengakses Firestore**
3. **Firebase Authentication belum diaktifkan**
4. **Konfigurasi Firebase tidak sesuai**

## Solusi yang Telah Diterapkan

### 1. Perbaikan Firestore Rules
✅ **File**: `firestore.rules`

Rules telah diperbaiki untuk memberikan akses yang tepat:
- Collection `pengguna`: User hanya bisa read/write data mereka sendiri
- Collection lainnya: Semua authenticated user bisa read/write
- Nested collections (seperti transaksi): Authenticated user bisa akses

### 2. Deploy Firestore Rules
✅ **Command**: `firebase deploy --only firestore:rules`

Rules telah berhasil di-deploy ke Firebase Console.

### 3. Perbaikan Error Handling
✅ **File**: `lib/services/auth_service.dart`

Ditambahkan:
- Pengecekan authentication sebelum akses Firestore
- Error handling yang lebih spesifik untuk permission denied
- Pesan error yang lebih user-friendly

### 4. Validasi Authentication
✅ **Improvement**: 
- Pastikan user terautentikasi sebelum akses Firestore
- Better error messages untuk berbagai jenis error

## Cara Mengatasi Error Permission Denied

### Langkah 1: Pastikan Firebase Authentication Aktif
1. Buka [Firebase Console](https://console.firebase.google.com/)
2. Pilih project `gudangku-dc355`
3. Klik "Authentication" di sidebar
4. Klik tab "Sign-in method"
5. Pastikan "Email/Password" sudah enabled

### Langkah 2: Verifikasi Firestore Rules
1. Di Firebase Console, klik "Firestore Database"
2. Klik tab "Rules"
3. Pastikan rules sesuai dengan yang ada di file `firestore.rules`
4. Jika berbeda, deploy ulang dengan: `firebase deploy --only firestore:rules`

### Langkah 3: Test Authentication
1. Coba register user baru
2. Coba login dengan user yang sudah ada
3. Periksa console log untuk error details

### Langkah 4: Debug Firestore Access
Jika masih ada masalah, gunakan debug script:
```dart
import '../lib/debug/firebase_test.dart';

// Test koneksi Firebase
await FirebaseTest.testFirebaseConnection();

// Test create user
await FirebaseTest.testCreateUser(
  email: 'test@example.com',
  password: 'test123',
  namaPengguna: 'testuser',
  namaLengkap: 'Test User',
);
```

## Error Messages dan Solusinya

### "permission-denied"
**Penyebab**: Firestore rules tidak mengizinkan akses
**Solusi**: 
- Deploy ulang Firestore rules
- Pastikan user sudah login
- Periksa rules di Firebase Console

### "User tidak terautentikasi"
**Penyebab**: Mencoba akses Firestore tanpa login
**Solusi**: 
- Login terlebih dahulu
- Periksa auth state di aplikasi

### "Email sudah digunakan"
**Penyebab**: Email sudah terdaftar
**Solusi**: 
- Gunakan email lain
- Atau login dengan email tersebut

### "Password terlalu lemah"
**Penyebab**: Password kurang dari 6 karakter
**Solusi**: 
- Gunakan password minimal 6 karakter

## Monitoring dan Maintenance

### 1. Monitoring Error
- Periksa console log untuk error details
- Monitor Firebase Console untuk usage dan errors

### 2. Regular Maintenance
- Review Firestore rules secara berkala
- Update security rules sesuai kebutuhan
- Monitor authentication metrics

### 3. Best Practices
- Selalu validate input sebelum kirim ke Firebase
- Handle semua possible error cases
- Provide user-friendly error messages
- Log errors untuk debugging

## Testing

Untuk test manual:
1. Buka aplikasi
2. Coba register user baru
3. Coba login dengan user yang baru dibuat
4. Periksa apakah data tersimpan di Firestore
5. Test berbagai fitur yang menggunakan Firestore

## Troubleshooting Lanjutan

Jika masih ada masalah:
1. **Restart aplikasi** - kadang perlu restart untuk apply changes
2. **Clear cache** - `flutter clean && flutter pub get`
3. **Periksa network** - pastikan koneksi internet stabil
4. **Periksa Firebase project** - pastikan menggunakan project yang benar
5. **Periksa API keys** - pastikan `google-services.json` up to date

## Kontak Support

Jika masalah masih berlanjut:
- Periksa Firebase Console untuk error logs
- Periksa Flutter console untuk detailed error messages
- Review konfigurasi Firebase di `firebase_options.dart`