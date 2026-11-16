import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/currency_formatter.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final ApiClient _apiClient = ApiClient();
  int _selectedMode = 0; // 0 = Bulanan, 1 = Tahunan

  // Monthly State
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  Map<String, dynamic>? _monthlyData;
  bool _isLoadingMonth = true;

  // Yearly State
  int _selectedYear = DateTime.now().year;
  Map<String, dynamic>? _yearlyData;
  bool _isLoadingYear = false;

  final List<Color> _pieColors = [
    const Color(0xFFEF4444),
    const Color(0xFF3B82F6),
    const Color(0xFFF59E0B),
    const Color(0xFF10B981),
    const Color(0xFF8B5CF6),
    const Color(0xFFEC4899),
    const Color(0xFF6B7280),
  ];

  @override
  void initState() {
    super.initState();
    _fetchMonthly();
  }

  Future<void> _fetchMonthly() async {
    setState(() => _isLoadingMonth = true);
    try {
      final res = await _apiClient.get(
        '/analytics/monthly?month=${_selectedMonth.month}&year=${_selectedMonth.year}',
      );
      if (res.statusCode == 200) {
        setState(() {
          _monthlyData = jsonDecode(res.body);
          _isLoadingMonth = false;
        });
      }
    } catch (_) {
      setState(() => _isLoadingMonth = false);
    }
  }

  Future<void> _fetchYearly() async {
    setState(() => _isLoadingYear = true);
    try {
      final res = await _apiClient.get('/analytics/yearly?year=$_selectedYear');
      if (res.statusCode == 200) {
        setState(() {
          _yearlyData = jsonDecode(res.body);
          _isLoadingYear = false;
        });
      }
    } catch (_) {
      setState(() => _isLoadingYear = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Analisis & Laporan'),
      ),
      body: Column(
        children: [
          // Mode Toggle (Bulanan / Tahunan)
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.primary,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedMode = 0);
                        if (_monthlyData == null) _fetchMonthly();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedMode == 0 ? AppColors.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Bulanan',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: _selectedMode == 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedMode = 1);
                        if (_yearlyData == null) _fetchYearly();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedMode == 1 ? AppColors.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Tahunan',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: _selectedMode == 1 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: _selectedMode == 0 ? _buildMonthlyView() : _buildYearlyView(),
          ),
        ],
      ),
    );
  }

  // MONTHLY VIEW
  Widget _buildMonthlyView() {
    if (_isLoadingMonth) return const Center(child: CircularProgressIndicator());

    final summary = _monthlyData?['summary'] ?? {};
    final income = (summary['income'] ?? 0) as num;
    final expense = (summary['expense'] ?? 0) as num;
    final net = (summary['net'] ?? 0) as num;

    final breakdown = (_monthlyData?['category_breakdown'] as List?) ?? [];
    final daily = (_monthlyData?['daily_spending'] as List?) ?? [];
    final topExpenses = (_monthlyData?['top_expenses'] as List?) ?? [];

    return RefreshIndicator(
      onRefresh: _fetchMonthly,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Month selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1));
                  _fetchMonthly();
                },
              ),
              Text(
                DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1));
                  _fetchMonthly();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Summary Cards
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Pemasukan', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                    Text(CurrencyFormatter.format(income), style: const TextStyle(color: AppColors.income, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  children: [
                    const Text('Pengeluaran', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                    Text(CurrencyFormatter.format(expense), style: const TextStyle(color: AppColors.expense, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  children: [
                    const Text('Net Saldo', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                    Text(
                      CurrencyFormatter.format(net),
                      style: TextStyle(color: net >= 0 ? AppColors.income : AppColors.expense, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Pie Chart Breakdown
          const Text('Proporsi Pengeluaran per Kategori', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
          const SizedBox(height: 10),
          if (breakdown.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: const Text('Belum ada data pengeluaran.', style: TextStyle(color: AppColors.muted)),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: List.generate(breakdown.length, (i) {
                          final b = breakdown[i];
                          final pct = (b['percentage'] ?? 0).toDouble();
                          return PieChartSectionData(
                            color: _pieColors[i % _pieColors.length],
                            value: pct,
                            title: '$pct%',
                            radius: 48,
                            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: List.generate(breakdown.length, (i) {
                      final b = breakdown[i];
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 10, height: 10, color: _pieColors[i % _pieColors.length]),
                          const SizedBox(width: 4),
                          Text('${b['icon'] ?? ''} ${b['name']}', style: const TextStyle(fontSize: 11)),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Top 3 Largest Expenses
          const Text('Top 3 Pengeluaran Terbesar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
          const SizedBox(height: 10),
          if (topExpenses.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(12)),
              child: const Text('Belum ada pengeluaran besar.', style: TextStyle(color: AppColors.muted)),
            )
          else
            ...topExpenses.map((t) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.expense.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(t['category']?['icon'] ?? '💸', style: const TextStyle(fontSize: 20)),
                    ),
                    title: Text(t['description'] ?? t['category']?['name'] ?? 'Pengeluaran', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(t['transaction_date'] ?? ''),
                    trailing: Text(
                      CurrencyFormatter.format(num.parse(t['amount'].toString())),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.expense),
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  // YEARLY VIEW
  Widget _buildYearlyView() {
    if (_isLoadingYear) return const Center(child: CircularProgressIndicator());

    final summary = _yearlyData?['summary'] ?? {};
    final totalIncome = (summary['total_income'] ?? 0) as num;
    final totalExpense = (summary['total_expense'] ?? 0) as num;
    final avgMonthlySave = (summary['avg_monthly_saving'] ?? 0) as num;
    final trends = (_yearlyData?['monthly_trend'] as List?) ?? [];
    final highlights = _yearlyData?['highlights'] ?? {};
    final boros = highlights['most_expensive_month'];
    final hemat = highlights['least_expensive_month'];

    return RefreshIndicator(
      onRefresh: _fetchYearly,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Year Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() => _selectedYear -= 1);
                  _fetchYearly();
                },
              ),
              Text(
                'Tahun $_selectedYear',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() => _selectedYear += 1);
                  _fetchYearly();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Annual Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Total Masuk', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                        Text(CurrencyFormatter.format(totalIncome), style: const TextStyle(color: AppColors.income, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Total Keluar', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                        Text(CurrencyFormatter.format(totalExpense), style: const TextStyle(color: AppColors.expense, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text(
                  'Rata-rata Tabungan / Bulan: ${CurrencyFormatter.format(avgMonthlySave)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Highlights: Bulan Boros vs Hemat
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🔴 Paling Boros', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(boros != null ? '${boros['month_name']}: ${CurrencyFormatter.formatCompact(boros['expense'])}' : '-', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🟢 Paling Hemat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(hemat != null ? '${hemat['month_name']}: ${CurrencyFormatter.formatCompact(hemat['expense'])}' : '-', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Line Chart Trend 12 Bulan
          const Text('Tren 12 Bulan (Pemasukan vs Pengeluaran)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(12)),
            child: SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt() - 1;
                          if (idx >= 0 && idx < trends.length) {
                            return Text(trends[idx]['month_name'] ?? '', style: const TextStyle(fontSize: 9));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    // Income Line (Green)
                    LineChartBarData(
                      spots: List.generate(trends.length, (i) {
                        return FlSpot((i + 1).toDouble(), (trends[i]['income'] ?? 0).toDouble());
                      }),
                      isCurved: true,
                      color: AppColors.income,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                    ),
                    // Expense Line (Red)
                    LineChartBarData(
                      spots: List.generate(trends.length, (i) {
                        return FlSpot((i + 1).toDouble(), (trends[i]['expense'] ?? 0).toDouble());
                      }),
                      isCurved: true,
                      color: AppColors.expense,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
