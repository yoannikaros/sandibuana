# Setup Firebase untuk Aplikasi Sandi Buana

## Langkah-langkah Setup Firebase

### 1. Buat Project Firebase
1. Buka [Firebase Console](https://console.firebase.google.com/)
2. Klik "Add project" atau "Tambah project"
3. Masukkan nama project: `sandibuana-hidroponik`
4. Ikuti langkah-langkah setup hingga selesai

### 2. Setup Authentication
1. Di Firebase Console, pilih project Anda
2. Klik "Authentication" di menu sebelah kiri
3. Klik tab "Sign-in method"
4. Enable "Email/Password" authentication
5. Opsional: Enable "Email link (passwordless sign-in)" jika diperlukan

### 3. Setup Firestore Database
1. Di Firebase Console, klik "Firestore Database"
2. Klik "Create database"
3. Pilih "Start in test mode" (untuk development)
4. Pilih lokasi server (pilih yang terdekat dengan Indonesia, misalnya asia-southeast1)
5. Klik "Done"

### 4. Setup Android App
1. Di Firebase Console, klik ikon Android untuk menambah app
2. Masukkan package name: `com.sbapp.sandibuana`
3. Masukkan app nickname: `Sandi Buana Android`
4. Download file `google-services.json`
5. **PENTING**: Ganti file `android/app/google-services.json` yang sudah ada dengan file yang baru didownload

### 5. Firestore Security Rules
Untuk development, gunakan rules berikut di Firestore:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write access to authenticated users only
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 6. Struktur Collection Firestore
Buat collection berikut di Firestore:

#### Collection: `pengguna`
Struktur dokumen:
```json
{
  "nama_pengguna": "string",
  "nama_lengkap": "string",
  "email": "string",
  "peran": "admin" | "operator",
  "aktif": true,
  "dibuat_pada": "timestamp",
  "diubah_pada": "timestamp"
}
```

#### Collection: `kategori_pengeluaran`
```json
{
  "nama_kategori": "string",
  "keterangan": "string",
  "aktif": true
}
```

#### Collection: `jenis_benih`
```json
{
  "nama_benih": "string",
  "pemasok": "string",
  "harga_per_satuan": "number",
  "jenis_satuan": "string",
  "ukuran_satuan": "string",
  "aktif": true,
  "dibuat_pada": "timestamp"
}
```

### 7. Menjalankan Aplikasi

1. Install dependencies:
```bash
flutter pub get
```

2. Jalankan aplikasi:
```bash
flutter run
```

### 8. Testing

#### Akun Default untuk Testing
Setelah setup selesai, Anda bisa membuat akun admin pertama melalui aplikasi dengan:
- Email: admin@sandibuana.com
- Password: admin123
- Username: admin
- Nama Lengkap: Administrator
- Peran: admin

### 9. Troubleshooting

#### Error: "Firebase not initialized"
- Pastikan `Firebase.initializeApp()` dipanggil di `main()` function
- Pastikan file `google-services.json` sudah benar

#### Error: "Permission denied"
- Periksa Firestore security rules
- Pastikan user sudah login

#### Error: "Network error"
- Periksa koneksi internet
- Pastikan Firebase project sudah aktif

### 10. Production Setup

Untuk production:
1. Update Firestore security rules menjadi lebih ketat
2. Enable App Check untuk keamanan tambahan
3. Setup monitoring dan analytics
4. Backup database secara berkala

## Fitur yang Tersedia

### Authentication
- ✅ Register dengan email dan password
- ✅ Login dengan email atau username
- ✅ Reset password
- ✅ Logout
- ✅ Role-based access (admin/operator)

### User Management
- ✅ Profile management
- ✅ User status (aktif/tidak aktif)
- ✅ Role assignment

### Keamanan
- ✅ Password hashing (handled by Firebase Auth)
- ✅ Input validation
- ✅ Error handling
- ✅ Session management

## Struktur Database

Aplikasi ini menggunakan Firestore sebagai database NoSQL yang mengikuti struktur dari `database.sql` yang sudah ada, dengan adaptasi untuk NoSQL:

- Relasi foreign key diganti dengan document references
- Auto increment ID diganti dengan Firestore document ID
- Timestamp menggunakan Firestore Timestamp
- Enum values tetap menggunakan string

## Kontribusi

Untuk berkontribusi pada project ini:
1. Fork repository
2. Buat feature branch
3. Commit changes
4. Push ke branch
5. Create Pull Request

## Lisensi

Project ini dibuat untuk keperluan internal Sandi Buana Hidroponik.