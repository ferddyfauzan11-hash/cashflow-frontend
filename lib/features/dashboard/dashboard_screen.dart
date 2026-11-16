import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/currency_formatter.dart';
import '../auth/auth_provider.dart';
import '../pockets/add_pocket_screen.dart';
import '../pockets/pocket_detail_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _summaryData;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get('/dashboard/summary');
      if (res.statusCode == 200) {
        setState(() {
          _summaryData = jsonDecode(res.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/rs-logo-light.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.wallet, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ${user?.name ?? 'User'}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Cashflow RS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchSummary,
            tooltip: 'Segarkan data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchSummary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. Month Net Balance Card
                  _buildMonthSaldoCard(),
                  const SizedBox(height: 16),

                  // 2. Unallocated & Quick Stats
                  _buildUnallocatedCard(),
                  const SizedBox(height: 20),

                  // 3. Pockets Section
                  _buildPocketsSection(),
                  const SizedBox(height: 20),

                  // 4. Mini 7-day Bar Chart
                  _buildMiniChartSection(),
                  const SizedBox(height: 20),

                  // 5. Loans Summary Card
                  _buildLoansSummaryCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthSaldoCard() {
    final month = _summaryData?['month'] ?? {};
    final net = (month['net'] ?? 0) as num;
    final income = (month['income'] ?? 0) as num;
    final expense = (month['expense'] ?? 0) as num;
    final isPositive = net >= 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo Bersih Bulan Ini',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(net),
            style: GoogleFonts.plusJakartaSans(
              color: isPositive ? AppColors.income : AppColors.expense,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.income.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_downward, color: AppColors.income, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pemasukan', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        Text(
                          CurrencyFormatter.format(income),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.expense.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_upward, color: AppColors.expense, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pengeluaran', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        Text(
                          CurrencyFormatter.format(expense),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnallocatedCard() {
    final overall = _summaryData?['overall'] ?? {};
    final unallocated = (overall['unallocated_balance'] ?? 0) as num;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('🏦', style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saldo Unallocated (Bebas)',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                Text(
                  CurrencyFormatter.format(unallocated),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.shield_outlined, color: AppColors.accent, size: 20),
        ],
      ),
    );
  }

  Widget _buildPocketsSection() {
    final pockets = (_summaryData?['pockets'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kantong Saya (Pockets)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              '${pockets.length} kantong',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: pockets.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) {
              if (i == pockets.length) {
                return _buildAddPocketCard();
              }
              final pocket = pockets[i];
              return _buildPocketItemCard(pocket);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPocketItemCard(Map<String, dynamic> pocket) {
    final balance = (num.tryParse(pocket['current_balance']?.toString() ?? '0')) ?? 0;
    final target = num.tryParse(pocket['target_amount']?.toString() ?? '');
    final double progress = (target != null && target > 0)
        ? (balance / target).clamp(0.0, 1.0).toDouble()
        : 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PocketDetailScreen(pocketId: pocket['id']),
          ),
        ).then((_) => _fetchSummary());
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(pocket['icon'] ?? '💼', style: const TextStyle(fontSize: 22)),
                const Spacer(),
                if (pocket['has_auto_target'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.income.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('AUTO', style: TextStyle(fontSize: 9, color: AppColors.income, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              pocket['name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              CurrencyFormatter.format(balance),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            if (target != null && target > 0) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(
                    progress >= 1.0 ? AppColors.income : AppColors.accent,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddPocketCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddPocketScreen()),
        ).then((_) => _fetchSummary());
      },
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.accent.withOpacity(0.3), style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_circle_outline, color: AppColors.accent, size: 28),
            SizedBox(height: 8),
            Text(
              '+ Tambah\nPocket',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChartSection() {
    final recent = (_summaryData?['recent_expense_7_days'] as List?) ?? [];
    if (recent.isEmpty) return const SizedBox.shrink();

    double maxY = 100000;
    for (var r in recent) {
      final amt = (r['amount'] ?? 0).toDouble();
      if (amt > maxY) maxY = amt;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Pengeluaran 7 Hari Terakhir',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
              ),
              Icon(Icons.bar_chart, color: AppColors.accent, size: 20),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 130,
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.15,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < recent.length) {
                          final dateStr = recent[idx]['date']?.toString() ?? '';
                          final parts = dateStr.split('-');
                          if (parts.length == 3) {
                            return Text('${parts[2]}/${parts[1]}', style: const TextStyle(fontSize: 9));
                          }
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(recent.length, (idx) {
                  final amt = (recent[idx]['amount'] ?? 0).toDouble();
                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: amt,
                        color: amt > 0 ? AppColors.expense : Colors.grey.shade300,
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoansSummaryCard() {
    final loans = _summaryData?['loans'] ?? {};
    final activeCount = (loans['active_count'] ?? 0) as int;
    final lend = (loans['total_lend_remaining'] ?? 0) as num;
    final borrow = (loans['total_borrow_remaining'] ?? 0) as num;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pinjaman & Piutang Aktif',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$activeCount Aktif',
                  style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Saya Pinjamkan (Piutang)', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(lend),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.income, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Saya Berhutang', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(borrow),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.expense, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
