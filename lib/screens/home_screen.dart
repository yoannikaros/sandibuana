import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'jenis_benih_screen.dart';
import 'jenis_pupuk_screen.dart';
import 'tandon_air_screen.dart';
import 'monitoring_nutrisi_screen.dart';
import 'pelanggan_screen.dart';
import 'penggunaan_pupuk_screen.dart';
import 'pengeluaran_harian_screen.dart';
import 'monitoring_nutrisi_harian_screen.dart';
import 'catatan_pembenihan_screen.dart';
import 'penanaman_sayur_screen.dart';
import 'kegagalan_panen_screen.dart';
import 'jadwal_pemupukan_screen.dart';
import 'catatan_perlakuan_screen.dart';
import 'pembelian_benih_screen.dart';
import 'kondisi_meja_screen.dart';


import 'rekap_pupuk_mingguan_screen.dart';
import 'rekap_nutrisi_screen.dart';
import 'kasir_screen.dart';
import 'laporan_transaksi_screen.dart';

import 'laporan_kegagalan_panen_screen.dart';
import 'laporan_catatan_pembenihan_screen.dart';
import '../debug/permission_test.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sandi Buana Dashboard'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'logout') {
                    await authProvider.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    }
                  } else if (value == 'debug_permission') {
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PermissionTestScreen(),
                        ),
                      );
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(Icons.person),
                        const SizedBox(width: 8),
                        Text(authProvider.user?.namaLengkap ?? 'Profile'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'debug_permission',
                    child: Row(
                      children: [
                        const Icon(Icons.bug_report, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text('Debug Permission'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Keluar'),
                      ],
                    ),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Text(
                          authProvider.user?.namaLengkap.substring(0, 1).toUpperCase() ?? 'U',
                          style: TextStyle(color: Colors.green.shade600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;
          
          if (user == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.green.shade600,
                  Colors.green.shade50,
                ],
                stops: const [0.0, 0.3],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Welcome Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat Datang,',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.namaLengkap,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.peran.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Dashboard Content
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dashboard Hidroponik',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Menu Categories
                          _buildCategorySection(
                            context,
                            'Manajemen Data',
                            Icons.data_array_outlined,
                            Colors.blue,
                            [
                              _buildMenuCard(
                                context,
                                'Jenis Benih',
                                Icons.grass,
                                Colors.green,
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const JenisBenihScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildMenuCard(
                                context,
                                'Jenis Pupuk',
                                Icons.eco,
                                Colors.lightGreen,
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const JenisPupukScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildMenuCard(
                                context,
                                'Tandon Air',
                                Icons.water_drop_outlined,
                                Colors.blue,
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const TandonAirScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildMenuCard(
                                context,
                                'Pelanggan',
                                Icons.people,
                                Colors.indigo,
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const PelangganScreen(),
                                    ),
                                  );
                                },
                              ),

                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          _buildCategorySection(
                            context,
                            'Aktivitas Harian',
                            Icons.today,
                            Colors.orange,
                            [
                              _buildMenuCard(
                                context,
                                'Catatan Pembenihan',
                                Icons.spa,
                                Colors.lightGreen,
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const CatatanPembenihanScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildMenuCard(
                                context,
                                'Penanaman Sayur',
                                Icons.eco,
                                Colors.green,
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const PenanamanSayurScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildMenuCard(
                                context,
                                'Jadwal Pemupukan',
                                Icons.schedule,
                                Colors.purple,
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const JadwalPemupukanScreen(),
                                    ),
                                  );
                                },
                              ),
                              // _buildMenuCard(
                              //   context,
                              //   'Catatan Aktivitas',
                              //   Icons.note_alt,
                              //   Colors.teal,
                              //   () {
                              //     Navigator.of(context).push(
                              //       MaterialPageRoute(
                              //         builder: (context) => const CatatanPerlakuanScreen(),
                              //       ),
                              //     );
                              //   },
                              // ),
                              // _buildMenuCard(
                              //   context,
                              //   'Kegagalan Panen',
                              //   Icons.warning_amber,
                              //   Colors.red,
                              //   () {
                              //     Navigator.of(context).push(
                              //       MaterialPageRoute(
                              //         builder: (context) => const KegagalanPanenScreen(),
                              //       ),
                              //     );
                              //   },
                              // ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          _buildCategorySection(
                            context,
                            'Monitoring & Tracking',
                            Icons.monitor,
                            Colors.cyan,
                            [
                              _buildMenuCard(
                                context,
                                'Monitoring Nutrisi',
                                Icons.science,
                                Colors.teal,
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const MonitoringNutrisiScreen(),
                                    ),
                                  );
                                },
                              ),
                              // _buildMenuCard(
                              //   context,
                              //   'Monitoring Nutrisi Harian',
                              //   Icons.water_drop,
                              //   Colors.cyan,
                              //   () {
                              //     Navigator.of(context).push(
                              //       MaterialPageRoute(
                              //         builder: (context) => const MonitoringNutrisiHarianScreen(),
                              //       ),
                              //     );
                              //   },
                              // ),
                              _buildMenuCard(
                                context,
                                'Penggunaan Pupuk',
                                Icons.agriculture,
                                Colors.brown,
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const PenggunaanPupukScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildMenuCard(
                                context,
                                'Kondisi Meja',
                                Icons.table_restaurant,
                                Colors.amber,
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const KondisiMejaScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          _buildCategorySection(
                            context,
                            'Keuangan',
                            Icons.attach_money,
                            Colors.green,
                            [
                              _buildMenuCard(
                                context,
                                'Pembelian Benih',
                                Icons.shopping_cart,
                                Colors.orange,
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const PembelianBenihScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildMenuCard(
                                context,
                                'Pengeluaran Harian',
                                Icons.receipt_long,
                                Colors.red,
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const PengeluaranHarianScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildMenuCard(
                                context,
                                'Kasir',
                                Icons.point_of_sale,
                                Colors.purple,
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const KasirScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          _buildCategorySection(
                            context,
                            'Laporan & Analisis',
                            Icons.assessment,
                            Colors.deepOrange,
                            [
                              // _buildMenuCard(
                              //   context,
                              //   'Laporan',
                              //   Icons.assessment,
                              //   Colors.deepOrange,
                              //   () {
                              //     Navigator.of(context).push(
                              //       MaterialPageRoute(
                              //         builder: (context) => const LaporanMenuScreen(),
                              //       ),
                              //     );
                              //   },
                              // ),
                              _buildMenuCard(
                                context,
                                'Laporan Transaksi',
                                Icons.receipt_long,
                                Colors.blue,
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const LaporanTransaksiScreen(),
                                    ),
                                  );
                                },
                              ),

                              // _buildMenuCard(
                              //   context,
                              //   'Rekap Pupuk Mingguan',
                              //   Icons.water_drop,
                              //   Colors.blue,
                              //   () {
                              //     Navigator.of(context).push(
                              //       MaterialPageRoute(
                              //         builder: (context) => const RekapPupukMingguanScreen(),
                              //       ),
                              //     );
                              //   },
                              // ),
                              _buildMenuCard(
                                context,
                                'Rekap Nutrisi',
                                Icons.analytics,
                                Colors.teal,
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const RekapNutrisiScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildMenuCard(
                                context,
                                'Laporan Catatan Pembenihan',
                                Icons.grass,
                                Colors.green,
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const LaporanCatatanPembenihanScreen(),
                                    ),
                                  );
                                },
                              ),
                              // _buildMenuCard(
                              //   context,
                              //   'Laporan Kegagalan Panen',
                              //   Icons.analytics,
                              //   Colors.orange,
                              //   () {
                              //     Navigator.of(context).push(
                              //       MaterialPageRoute(
                              //         builder: (context) => const LaporanKegagalanPanenScreen(),
                              //       ),
                              //     );
                              //   },
                              // ),
                              // _buildMenuCard(
                              //   context,
                              //   'Laporan Penjualan',
                              //   Icons.bar_chart,
                              //   Colors.green,
                              //   () {
                              //     Navigator.of(context).push(
                              //       MaterialPageRoute(
                              //         builder: (context) => const LaporanPenjualanScreen(),
                              //       ),
                              //     );
                              //   },
                              // ),


                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // _buildCategorySection(
                          //   context,
                          //   'Pengaturan',
                          //   Icons.settings,
                          //   Colors.grey,
                          //   [
                          //     _buildMenuCard(
                          //       context,
                          //       'Pengaturan',
                          //       Icons.settings,
                          //       Colors.grey,
                          //       () {
                          //         // TODO: Navigate to settings
                          //         _showComingSoon(context, 'Pengaturan');
                          //       },
                          //     ),
                          //   ],
                          // ),
                         
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<Widget> menuCards,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: menuCards,
        ),
      ],
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.8),
                color.withOpacity(0.6),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: Text('Fitur $feature akan segera tersedia.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}