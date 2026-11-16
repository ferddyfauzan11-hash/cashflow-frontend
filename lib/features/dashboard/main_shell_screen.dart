import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../transactions/add_transaction_screen.dart';
import 'dashboard_screen.dart';
import '../transactions/transactions_screen.dart';
import '../analytics/analytics_screen.dart';
import '../more/more_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    TransactionsScreen(),
    AnalyticsScreen(),
    MoreScreen(),
  ];

  void _showQuickAddBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Tambah Transaksi Baru',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.income.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('💰', style: TextStyle(fontSize: 22)),
                ),
                title: const Text('Pemasukan', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Gaji, bonus, penjualan, freelance'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddTransactionScreen(initialType: 'income'),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.expense.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('💸', style: TextStyle(fontSize: 22)),
                ),
                title: const Text('Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Makan, belanja, transport, tagihan'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddTransactionScreen(initialType: 'expense'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _showQuickAddBottomSheet,
              child: const Icon(Icons.add, size: 28),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Transaksi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Analisis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.widgets_outlined),
            activeIcon: Icon(Icons.widgets),
            label: 'Lainnya',
          ),
        ],
      ),
    );
  }
}
