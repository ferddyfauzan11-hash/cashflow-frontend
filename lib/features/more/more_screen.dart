import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../auth/auth_provider.dart';
import '../categories/categories_screen.dart';
import '../loans/loans_screen.dart';
import '../pockets/add_pocket_screen.dart';
import '../pockets/transfer_pocket_screen.dart';
import '../sync/sync_status_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Menu Lainnya'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Profile Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'User',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: AppColors.expense),
                  tooltip: 'Keluar Akun',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Logout?'),
                        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('BATAL')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('LOGOUT'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      ref.read(authProvider.notifier).logout();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Features Section
          const Text('Fitur & Manajemen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.wallet, color: AppColors.accent),
                  title: const Text('Tambah Pocket Baru'),
                  subtitle: const Text('Buat kantong dana darurat atau impian'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPocketScreen()));
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.sync_alt, color: AppColors.primary),
                  title: const Text('Transfer Dana Antar Pocket'),
                  subtitle: const Text('Pindahkan saldo dari/ke kantong'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferPocketScreen()));
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.handshake_outlined, color: AppColors.income),
                  title: const Text('Pinjaman & Hutang'),
                  subtitle: const Text('Kelola hutang piutang dan cicilan'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoansScreen()));
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.category_outlined, color: AppColors.warning),
                  title: const Text('Kelola Kategori'),
                  subtitle: const Text('Atur kategori pengeluaran dan pemasukan'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen()));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // System Section
          const Text('Sistem & Konektivitas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_sync_outlined, color: AppColors.accent),
                  title: const Text('Status Sinkronisasi'),
                  subtitle: const Text('Cek data lokal dan sinkronkan ke server'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SyncStatusScreen()));
                  },
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.info_outline, color: AppColors.muted),
                  title: Text('Versi Aplikasi'),
                  subtitle: Text('Cashflow RS v1.0.0 (Release)'),
                  trailing: Text('Build #1', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

