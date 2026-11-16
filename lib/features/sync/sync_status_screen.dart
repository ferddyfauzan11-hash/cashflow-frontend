import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/database/app_database.dart';
import '../../core/services/sync_service.dart';
import '../auth/auth_provider.dart';

class SyncStatusScreen extends ConsumerStatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  ConsumerState<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends ConsumerState<SyncStatusScreen> {
  late SyncService _syncService;
  late AppDatabase _db;
  bool _isLoading = true;
  bool _isSyncing = false;
  String? _lastSynced;
  Map<String, int> _counts = {};

  @override
  void initState() {
    super.initState();
    _db = AppDatabase();
    _syncService = SyncService(_db);
    _loadSyncInfo();
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  Future<void> _loadSyncInfo() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final counts = await _syncService.getPendingCounts(user.id);
    final lastSync = await _syncService.getLastSyncedAt();

    setState(() {
      _counts = counts;
      _lastSynced = lastSync;
      _isLoading = false;
    });
  }

  void _triggerSync() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    setState(() => _isSyncing = true);

    final success = await _syncService.syncAll(user.id);

    await _loadSyncInfo();

    setState(() => _isSyncing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Sinkronisasi berhasil!' : 'Sinkronisasi gagal, coba lagi nanti.'),
          backgroundColor: success ? AppColors.income : AppColors.expense,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPending = _counts['total'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Status Sinkronisasi'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: totalPending > 0 ? AppColors.warning.withOpacity(0.12) : AppColors.income.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: totalPending > 0 ? AppColors.warning : AppColors.income,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          totalPending > 0 ? Icons.sync_problem : Icons.cloud_done,
                          color: totalPending > 0 ? AppColors.warning : AppColors.income,
                          size: 36,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                totalPending > 0 ? '$totalPending Perubahan Tertunda' : 'Semua Data Tersinkron',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: totalPending > 0 ? AppColors.warning : AppColors.income,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _lastSynced != null ? 'Terakhir sync: ${_lastSynced!.split('.')[0]}' : 'Belum pernah sync',
                                style: const TextStyle(color: AppColors.muted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Detail per table
                  const Text('Rincian Data Lokal (Drift / SQLite)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                  const SizedBox(height: 10),
                  Card(
                    child: Column(
                      children: [
                        _buildSyncRow('Kategori', _counts['categories'] ?? 0),
                        const Divider(height: 1),
                        _buildSyncRow('Pockets / Kantong', _counts['pockets'] ?? 0),
                        const Divider(height: 1),
                        _buildSyncRow('Alokasi Transfer', _counts['pocket_allocations'] ?? 0),
                        const Divider(height: 1),
                        _buildSyncRow('Transaksi', _counts['transactions'] ?? 0),
                        const Divider(height: 1),
                        _buildSyncRow('Pinjaman', _counts['loans'] ?? 0),
                        const Divider(height: 1),
                        _buildSyncRow('Cicilan', _counts['loan_installments'] ?? 0),
                      ],
                    ),
                  ),
                  const Spacer(),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: _isSyncing
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.sync),
                    label: Text(_isSyncing ? 'SINKRONISASI SEDANG BERJALAN...' : 'SYNC NOW (SINKRONKAN SEKARANG)'),
                    onPressed: _isSyncing ? null : _triggerSync,
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
    );
  }

  Widget _buildSyncRow(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: count > 0 ? AppColors.warning.withOpacity(0.15) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count > 0 ? '$count pending' : 'synced',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: count > 0 ? AppColors.warning : AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
