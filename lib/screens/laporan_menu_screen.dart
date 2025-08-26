import 'package:flutter/material.dart';
import 'laporan_kegagalan_panen_screen.dart';


class LaporanMenuScreen extends StatelessWidget {
  const LaporanMenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Laporan'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.assessment,
                      size: 48,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Laporan & Analisis',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Akses berbagai laporan dan analisis data pertanian',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Menu Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    // Laporan Kegagalan Panen
                    _buildMenuCard(
                      context,
                      title: 'Laporan Kegagalan Panen',
                      subtitle: 'Analisis kegagalan & kebusukan tanaman',
                      icon: Icons.report_problem,
                      color: Colors.red,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LaporanKegagalanPanenScreen(),
                          ),
                        );
                      },
                    ),
                    
                    // Laporan Penjualan
                  
                    // Laporan Produksi (Coming Soon)
                    _buildMenuCard(
                      context,
                      title: 'Laporan Produksi',
                      subtitle: 'Analisis hasil produksi',
                      icon: Icons.agriculture,
                      color: Colors.green,
                      isComingSoon: true,
                      onTap: () {
                        _showComingSoonDialog(context, 'Laporan Produksi');
                      },
                    ),
                    
                    // Laporan Keuangan (Coming Soon)
                    _buildMenuCard(
                      context,
                      title: 'Laporan Keuangan',
                      subtitle: 'Analisis keuangan & profit',
                      icon: Icons.account_balance,
                      color: Colors.orange,
                      isComingSoon: true,
                      onTap: () {
                        _showComingSoonDialog(context, 'Laporan Keuangan');
                      },
                    ),
                    
                    // Laporan Inventori (Coming Soon)
                    _buildMenuCard(
                      context,
                      title: 'Laporan Inventori',
                      subtitle: 'Analisis stok & persediaan',
                      icon: Icons.inventory,
                      color: Colors.purple,
                      isComingSoon: true,
                      onTap: () {
                        _showComingSoonDialog(context, 'Laporan Inventori');
                      },
                    ),
                    

                    
                    // Laporan Performa (Coming Soon)
                    _buildMenuCard(
                      context,
                      title: 'Laporan Performa',
                      subtitle: 'Analisis performa keseluruhan',
                      icon: Icons.analytics,
                      color: Colors.teal,
                      isComingSoon: true,
                      onTap: () {
                        _showComingSoonDialog(context, 'Laporan Performa');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isComingSoon = false,
  }) {
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
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 32,
                      color: color,
                    ),
                  ),
                  if (isComingSoon)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Soon',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade600,
              ),
              const SizedBox(width: 8),
              const Text('Coming Soon'),
            ],
          ),
          content: Text(
            '$featureName sedang dalam tahap pengembangan dan akan segera tersedia.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}