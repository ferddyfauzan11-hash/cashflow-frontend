import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/currency_formatter.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final ApiClient _apiClient = ApiClient();
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String _typeFilter = 'all'; // 'all', 'income', 'expense'

  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];
  num _totalIncome = 0;
  num _totalExpense = 0;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);

    final start = DateFormat('yyyy-MM-01').format(_currentMonth);
    final end = DateFormat('yyyy-MM-dd').format(
      DateTime(_currentMonth.year, _currentMonth.month + 1, 0),
    );

    var endpoint = '/transactions?start_date=$start&end_date=$end';
    if (_typeFilter != 'all') {
      endpoint += '&type=$_typeFilter';
    }

    try {
      final res = await _apiClient.get(endpoint);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] as List;
        final list = data.map((e) => e as Map<String, dynamic>).toList();

        num inc = 0;
        num exp = 0;
        for (var t in list) {
          final amt = num.tryParse(t['amount']?.toString() ?? '0') ?? 0;
          if (t['type'] == 'income') inc += amt;
          if (t['type'] == 'expense') exp += amt;
        }

        setState(() {
          _transactions = list;
          _totalIncome = inc;
          _totalExpense = exp;
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
    _fetchTransactions();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
    _fetchTransactions();
  }

  void _deleteTransaction(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: const Text('Saldo pocket terkait akan dikembalikan seperti semula.'),
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
      final res = await _apiClient.delete('/transactions/$id');
      if (res.statusCode == 200) {
        _fetchTransactions();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Daftar Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
              ).then((_) => _fetchTransactions());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Month picker header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.primary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: _previousMonth,
                ),
                Text(
                  DateFormat('MMMM yyyy', 'id_ID').format(_currentMonth),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          // Summary header card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Pemasukan', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(_totalIncome),
                      style: const TextStyle(color: AppColors.income, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                Container(height: 28, width: 1, color: Colors.grey.shade200),
                Column(
                  children: [
                    const Text('Pengeluaran', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(_totalExpense),
                      style: const TextStyle(color: AppColors.expense, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                Container(height: 28, width: 1, color: Colors.grey.shade200),
                Column(
                  children: [
                    const Text('Selisih (Net)', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(_totalIncome - _totalExpense),
                      style: TextStyle(
                        color: (_totalIncome - _totalExpense) >= 0 ? AppColors.income : AppColors.expense,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Semua'),
                  selected: _typeFilter == 'all',
                  onSelected: (_) {
                    setState(() => _typeFilter = 'all');
                    _fetchTransactions();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Pemasukan'),
                  selected: _typeFilter == 'income',
                  onSelected: (_) {
                    setState(() => _typeFilter = 'income');
                    _fetchTransactions();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Pengeluaran'),
                  selected: _typeFilter == 'expense',
                  onSelected: (_) {
                    setState(() => _typeFilter = 'expense');
                    _fetchTransactions();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Transaction List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.muted),
                            SizedBox(height: 12),
                            Text('Belum ada transaksi di bulan ini.', style: TextStyle(color: AppColors.muted)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchTransactions,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _transactions.length,
                          itemBuilder: (ctx, i) {
                            final t = _transactions[i];
                            final isIncome = t['type'] == 'income';
                            final cat = t['category'] ?? {};
                            final pocket = t['pocket'];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (isIncome ? AppColors.income : AppColors.expense).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(cat['icon'] ?? '🏷️', style: const TextStyle(fontSize: 22)),
                                ),
                                title: Text(
                                  t['description'] ?? cat['name'] ?? 'Transaksi',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: Row(
                                  children: [
                                    Text(t['transaction_date'] ?? ''),
                                    if (pocket != null) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${pocket['icon'] ?? '💼'} ${pocket['name']}',
                                          style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Text(
                                  '${isIncome ? '+' : '-'}${CurrencyFormatter.format(num.parse(t['amount'].toString()))}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isIncome ? AppColors.income : AppColors.expense,
                                    fontSize: 14,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddTransactionScreen(editTransaction: t),
                                    ),
                                  ).then((_) => _fetchTransactions());
                                },
                                onLongPress: () => _deleteTransaction(t['id']),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
