import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/currency_formatter.dart';
import 'transfer_pocket_screen.dart';

class PocketDetailScreen extends StatefulWidget {
  final String pocketId;

  const PocketDetailScreen({super.key, required this.pocketId});

  @override
  State<PocketDetailScreen> createState() => _PocketDetailScreenState();
}

class _PocketDetailScreenState extends State<PocketDetailScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _reportData;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get('/analytics/pocket/${widget.pocketId}');
      if (res.statusCode == 200) {
        setState(() {
          _reportData = jsonDecode(res.body);
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _deletePocket() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pocket?'),
        content: const Text(
          'Saldo pocket ini akan dikembalikan ke Unallocated, dan transaksi terkait akan dilepaskan dari kantong ini.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('BATAL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('HAPUS'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await _apiClient.delete('/pockets/${widget.pocketId}');
      if (res.statusCode == 200 && mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pocket = _reportData?['pocket'] ?? {};
    final balance = (pocket['current_balance'] ?? 0) as num;
    final target = pocket['target_amount'] != null ? (pocket['target_amount'] as num) : null;
    final progress = pocket['progress_percentage'] != null ? (pocket['progress_percentage'] as num) : null;
    final allocations = (_reportData?['recent_allocations'] as List?) ?? [];
    final transactions = (_reportData?['recent_transactions'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(pocket['name'] ?? 'Detail Pocket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _deletePocket,
            tooltip: 'Hapus Pocket',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDetail,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Pocket Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(pocket['icon'] ?? '💼', style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pocket['name'] ?? '',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Saldo Saat Ini',
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.sync_alt, size: 16),
                        label: const Text('Transfer', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TransferPocketScreen(initialFromPocketId: widget.pocketId),
                            ),
                          ).then((_) => _fetchDetail());
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    CurrencyFormatter.format(balance),
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  if (target != null && target > 0) ...[
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Target: ${CurrencyFormatter.format(target)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('${progress ?? 0}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ((progress ?? 0) / 100).clamp(0.0, 1.0).toDouble(),
                        minHeight: 6,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(AppColors.income),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Allocations History
            const Text('Riwayat Alokasi / Transfer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
            const SizedBox(height: 10),
            if (allocations.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(12)),
                child: const Text('Belum ada riwayat transfer.', style: TextStyle(color: AppColors.muted)),
              )
            else
              ...allocations.map((a) {
                final isIncoming = a['to_pocket_id'] == widget.pocketId;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isIncoming ? AppColors.income : AppColors.expense,
                    ),
                    title: Text(
                      isIncoming ? 'Dari: ${a['from_pocket']?['name'] ?? 'Unallocated'}' : 'Ke: ${a['to_pocket']?['name'] ?? 'Unallocated'}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text(a['allocation_date']?.toString().split('T')[0] ?? ''),
                    trailing: Text(
                      '${isIncoming ? '+' : '-'}${CurrencyFormatter.format(num.parse(a['amount'].toString()))}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isIncoming ? AppColors.income : AppColors.expense,
                      ),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 20),

            // Transactions in this pocket
            const Text('Transaksi Terkait', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
            const SizedBox(height: 10),
            if (transactions.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(12)),
                child: const Text('Belum ada transaksi di pocket ini.', style: TextStyle(color: AppColors.muted)),
              )
            else
              ...transactions.map((t) {
                final isIncome = t['type'] == 'income';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Text(t['category']?['icon'] ?? '💳', style: const TextStyle(fontSize: 20)),
                    title: Text(t['description'] ?? t['category']?['name'] ?? 'Transaksi', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(t['transaction_date'] ?? ''),
                    trailing: Text(
                      '${isIncome ? '+' : '-'}${CurrencyFormatter.format(num.parse(t['amount'].toString()))}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: isIncome ? AppColors.income : AppColors.expense),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
