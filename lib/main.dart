import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/benih_provider.dart';
import 'providers/pupuk_provider.dart';
import 'providers/tandon_provider.dart';
import 'providers/pengeluaran_provider.dart';
import 'providers/monitoring_nutrisi_provider.dart';
import 'providers/penanaman_sayur_provider.dart';
import 'providers/kegagalan_panen_provider.dart';
import 'providers/jadwal_pemupukan_provider.dart';
import 'providers/catatan_perlakuan_provider.dart';
import 'providers/pembelian_benih_provider.dart';
import 'providers/kategori_pengeluaran_provider.dart';
import 'providers/pelanggan_provider.dart';
import 'providers/penjualan_harian_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/rekap_benih_mingguan_provider.dart';
import 'providers/rekap_pupuk_mingguan_provider.dart';
import 'screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize locale data for Indonesian
  await initializeDateFormatting('id_ID', null);
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BenihProvider()),
        ChangeNotifierProvider(create: (_) => PupukProvider()),
        ChangeNotifierProvider(create: (_) => TandonProvider()),
        ChangeNotifierProvider(create: (_) => PengeluaranProvider()),
        ChangeNotifierProvider(create: (_) => MonitoringNutrisiProvider()),
        ChangeNotifierProvider(create: (_) => PenanamanSayurProvider()),
        ChangeNotifierProvider(create: (_) => KegagalanPanenProvider()),
        ChangeNotifierProxyProvider<AuthProvider, JadwalPemupukanProvider>(
          create: (context) => JadwalPemupukanProvider(context.read<AuthProvider>()),
          update: (context, authProvider, previous) => 
            previous ?? JadwalPemupukanProvider(authProvider),
        ),
        ChangeNotifierProxyProvider<AuthProvider, CatatanPerlakuanProvider>(
          create: (context) => CatatanPerlakuanProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, authProvider, previous) =>
              previous ?? CatatanPerlakuanProvider(authProvider),
        ),
        ChangeNotifierProxyProvider<AuthProvider, PembelianBenihProvider>(
          create: (context) => PembelianBenihProvider(context.read<AuthProvider>()),
          update: (context, authProvider, previous) => 
            previous ?? PembelianBenihProvider(authProvider),
        ),
        ChangeNotifierProxyProvider<AuthProvider, KategoriPengeluaranProvider>(
          create: (context) => KategoriPengeluaranProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) => KategoriPengeluaranProvider(auth),
        ),
        ChangeNotifierProvider(create: (_) => PelangganProvider()),
        ChangeNotifierProvider(create: (_) => PenjualanHarianProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProxyProvider<AuthProvider, RekapBenihMingguanProvider>(
          create: (context) => RekapBenihMingguanProvider(context.read<AuthProvider>()),
          update: (context, authProvider, previous) => 
            previous ?? RekapBenihMingguanProvider(authProvider),
        ),
        ChangeNotifierProxyProvider<AuthProvider, RekapPupukMingguanProvider>(
          create: (context) => RekapPupukMingguanProvider(context.read<AuthProvider>()),
          update: (context, authProvider, previous) => 
            previous ?? RekapPupukMingguanProvider(authProvider),
        ),
      ],
      child: MaterialApp(
        title: 'Sandi Buana - Hidroponik',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.shade600, width: 2),
            ),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}
