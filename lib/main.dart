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

import 'providers/pelanggan_provider.dart';

import 'providers/rekap_pupuk_mingguan_provider.dart';
import 'providers/tipe_pupuk_provider.dart';
import 'providers/jenis_pelanggan_provider.dart';
import 'providers/perlakuan_pupuk_provider.dart';
import 'providers/dropdown_provider.dart';
import 'providers/kondisi_meja_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/transaksi_provider.dart';
import 'services/database_initializer.dart';
import 'screens/auth_wrapper.dart';
import 'screens/dropdown_management_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize locale data for Indonesian
    await initializeDateFormatting('id_ID', null);
    
    // Initialize SQLite Database
    await DatabaseInitializer.initialize();
    
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    runApp(const MyApp());
  } catch (e) {
    print('Error during app initialization: $e');
    // Run app with error state
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BenihProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final provider = TipePupukProvider();
            // Load data saat aplikasi dimulai dengan error handling
            provider.loadTipePupuk().catchError((error) {
              print('Error loading tipe pupuk: $error');
            });
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final provider = JenisPelangganProvider();
            // Load data saat aplikasi dimulai dengan error handling
            provider.loadJenisPelanggan().catchError((error) {
              print('Error loading jenis pelanggan: $error');
            });
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final provider = PerlakuanPupukProvider();
            // Load data saat aplikasi dimulai dengan error handling
            provider.loadPerlakuanPupuk().catchError((error) {
              print('Error loading perlakuan pupuk: $error');
            });
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<TipePupukProvider, PupukProvider>(
          create: (context) => PupukProvider(),
          update: (context, tipePupukProvider, pupukProvider) {
            pupukProvider ??= PupukProvider();
            pupukProvider.setTipePupukProvider(tipePupukProvider);
            return pupukProvider;
          },
        ),
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
        ChangeNotifierProvider(create: (_) => PelangganProvider()),

        ChangeNotifierProxyProvider<AuthProvider, RekapPupukMingguanProvider>(
          create: (context) => RekapPupukMingguanProvider(context.read<AuthProvider>()),
          update: (context, authProvider, previous) => 
            previous ?? RekapPupukMingguanProvider(authProvider),
        ),
        ChangeNotifierProvider(
          create: (_) {
            final provider = DropdownProvider();
            // Load data saat aplikasi dimulai dengan error handling
            provider.loadAllCategories().catchError((error) {
              print('Error loading dropdown categories: $error');
            });
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, KondisiMejaProvider>(
          create: (context) => KondisiMejaProvider(context.read<AuthProvider>()),
          update: (context, authProvider, previous) => 
            previous ?? KondisiMejaProvider(authProvider),
        ),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => TransaksiProvider()),
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
        routes: {
          '/dropdown_management': (context) => const DropdownManagementScreen(),
        },
      ),
    );
  }
}

// Error App widget untuk menangani error saat startup
class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({super.key, required this.error});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sandi Buana - Error',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
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
                const Text(
                  'Gagal Memulai Aplikasi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Terjadi kesalahan saat memulai aplikasi:\n$error',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Restart app
                    main();
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
      ),
    );
  }
}
