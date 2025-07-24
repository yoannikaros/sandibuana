import 'package:cloud_firestore/cloud_firestore.dart';

class JadwalPemupukanModel {
  final String idJadwal;
  final DateTime bulanTahun; // format: YYYY-MM-01
  final int mingguKe; // 1-4
  final int hariDalamMinggu; // 1=Senin, 2=Selasa, dst
  final String perlakuanPupuk;
  final String? perlakuanTambahan;
  final String? catatan;
  final bool sudahSelesai;
  final String? diselesaikanOleh;
  final DateTime? diselesaikanPada;
  final String dibuatOleh;
  final DateTime dibuatPada;

  JadwalPemupukanModel({
    required this.idJadwal,
    required this.bulanTahun,
    required this.mingguKe,
    required this.hariDalamMinggu,
    required this.perlakuanPupuk,
    this.perlakuanTambahan,
    this.catatan,
    this.sudahSelesai = false,
    this.diselesaikanOleh,
    this.diselesaikanPada,
    required this.dibuatOleh,
    required this.dibuatPada,
  });

  // Factory constructor untuk membuat instance dari Firestore
  factory JadwalPemupukanModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return JadwalPemupukanModel(
      idJadwal: doc.id,
      bulanTahun: (data['bulan_tahun'] as Timestamp).toDate(),
      mingguKe: data['minggu_ke'] ?? 1,
      hariDalamMinggu: data['hari_dalam_minggu'] ?? 1,
      perlakuanPupuk: data['perlakuan_pupuk'] ?? '',
      perlakuanTambahan: data['perlakuan_tambahan'],
      catatan: data['catatan'],
      sudahSelesai: data['sudah_selesai'] ?? false,
      diselesaikanOleh: data['diselesaikan_oleh'],
      diselesaikanPada: data['diselesaikan_pada'] != null 
          ? (data['diselesaikan_pada'] as Timestamp).toDate() 
          : null,
      dibuatOleh: data['dibuat_oleh'] ?? '',
      dibuatPada: (data['dibuat_pada'] as Timestamp).toDate(),
    );
  }

  // Method untuk mengkonversi ke Map untuk Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'bulan_tahun': Timestamp.fromDate(bulanTahun),
      'minggu_ke': mingguKe,
      'hari_dalam_minggu': hariDalamMinggu,
      'perlakuan_pupuk': perlakuanPupuk,
      'perlakuan_tambahan': perlakuanTambahan,
      'catatan': catatan,
      'sudah_selesai': sudahSelesai,
      'diselesaikan_oleh': diselesaikanOleh,
      'diselesaikan_pada': diselesaikanPada != null 
          ? Timestamp.fromDate(diselesaikanPada!) 
          : null,
      'dibuat_oleh': dibuatOleh,
      'dibuat_pada': Timestamp.fromDate(dibuatPada),
    };
  }

  // Method untuk membuat copy dengan perubahan
  JadwalPemupukanModel copyWith({
    String? idJadwal,
    DateTime? bulanTahun,
    int? mingguKe,
    int? hariDalamMinggu,
    String? perlakuanPupuk,
    String? perlakuanTambahan,
    String? catatan,
    bool? sudahSelesai,
    String? diselesaikanOleh,
    DateTime? diselesaikanPada,
    String? dibuatOleh,
    DateTime? dibuatPada,
  }) {
    return JadwalPemupukanModel(
      idJadwal: idJadwal ?? this.idJadwal,
      bulanTahun: bulanTahun ?? this.bulanTahun,
      mingguKe: mingguKe ?? this.mingguKe,
      hariDalamMinggu: hariDalamMinggu ?? this.hariDalamMinggu,
      perlakuanPupuk: perlakuanPupuk ?? this.perlakuanPupuk,
      perlakuanTambahan: perlakuanTambahan ?? this.perlakuanTambahan,
      catatan: catatan ?? this.catatan,
      sudahSelesai: sudahSelesai ?? this.sudahSelesai,
      diselesaikanOleh: diselesaikanOleh ?? this.diselesaikanOleh,
      diselesaikanPada: diselesaikanPada ?? this.diselesaikanPada,
      dibuatOleh: dibuatOleh ?? this.dibuatOleh,
      dibuatPada: dibuatPada ?? this.dibuatPada,
    );
  }

  // Static method untuk mendapatkan nama hari
  static String getNamaHari(int hariDalamMinggu) {
    switch (hariDalamMinggu) {
      case 1:
        return 'Senin';
      case 2:
        return 'Selasa';
      case 3:
        return 'Rabu';
      case 4:
        return 'Kamis';
      case 5:
        return 'Jumat';
      case 6:
        return 'Sabtu';
      case 7:
        return 'Minggu';
      default:
        return 'Tidak Diketahui';
    }
  }

  // Static method untuk mendapatkan opsi hari
  static List<int> getHariOptions() {
    return [1, 2, 3, 4, 5, 6, 7];
  }

  // Static method untuk mendapatkan opsi minggu
  static List<int> getMingguOptions() {
    return [1, 2, 3, 4];
  }

  // Static method untuk mendapatkan opsi hari (alias)
  static List<int> getOptionsHari() {
    return getHariOptions();
  }

  // Static method untuk mendapatkan opsi minggu (alias)
  static List<int> getOptionsMinggu() {
    return getMingguOptions();
  }

  // Static method untuk mendapatkan template perlakuan pupuk
  static List<String> getPerlakuanPupukTemplates() {
    return [
      'Pupuk CEF + PTh',
      'Pupuk Coklat',
      'Pupuk Putih',
      'Pupuk CEF',
      'Pupuk Coklat + HIRACOL',
      'Pupuk Putih + ANTRACOL',
      'Bawang Putih + Pupuk CEF',
      'Treatment Khusus',
    ];
  }

  // Static method untuk mendapatkan template perlakuan tambahan
  static List<String> getPerlakuanTambahanTemplates() {
    return [
      'HIRACOL',
      'ANTRACOL',
      'Bawang Putih',
      'PTh (Pythium Treatment)',
      'Kombinasi HIRACOL + ANTRACOL',
      'Ekstrak Bawang Putih',
      'Treatment Anti Jamur',
      'Tidak Ada',
    ];
  }

  // Method untuk mendapatkan status color
  static String getStatusColor(bool sudahSelesai) {
    return sudahSelesai ? '#4CAF50' : '#FF9800'; // Green : Orange
  }

  // Method untuk mendapatkan status text
  static String getStatusText(bool sudahSelesai) {
    return sudahSelesai ? 'Selesai' : 'Belum Selesai';
  }

  // Method untuk mendapatkan tanggal target berdasarkan minggu dan hari
  DateTime getTanggalTarget() {
    // Hitung tanggal berdasarkan minggu ke dan hari dalam minggu
    DateTime firstDayOfMonth = DateTime(bulanTahun.year, bulanTahun.month, 1);
    
    // Cari hari pertama dalam minggu yang diminta
    int daysToAdd = ((mingguKe - 1) * 7) + (hariDalamMinggu - firstDayOfMonth.weekday);
    if (daysToAdd < 0) {
      daysToAdd += 7;
    }
    
    return firstDayOfMonth.add(Duration(days: daysToAdd));
  }

  // Method untuk cek apakah jadwal sudah terlambat
  bool isOverdue() {
    if (sudahSelesai) return false;
    DateTime targetDate = getTanggalTarget();
    return DateTime.now().isAfter(targetDate.add(const Duration(days: 1)));
  }

  // Method untuk mendapatkan prioritas berdasarkan status
  int getPriority() {
    if (sudahSelesai) return 3; // Lowest priority
    if (isOverdue()) return 1; // Highest priority
    return 2; // Medium priority
  }

  @override
  String toString() {
    return 'JadwalPemupukanModel(idJadwal: $idJadwal, bulanTahun: $bulanTahun, mingguKe: $mingguKe, hariDalamMinggu: $hariDalamMinggu, perlakuanPupuk: $perlakuanPupuk, sudahSelesai: $sudahSelesai)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JadwalPemupukanModel && other.idJadwal == idJadwal;
  }

  @override
  int get hashCode => idJadwal.hashCode;
}