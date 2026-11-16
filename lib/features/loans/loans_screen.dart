import 'dart:convert';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/currency_formatter.dart';
import 'add_loan_screen.dart';
import 'loan_detail_screen.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<Map<String, dynamic>> _loans = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchLoans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchLoans() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get('/loans');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] as List;
        setState(() {
          _loans = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeLoans = _loans.where((l) => l['status'] != 'completed').toList();
    final completedLoans = _loans.where((l) => l['status'] == 'completed').toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Pinjaman & Hutang'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'Aktif (${activeLoans.length})'),
            Tab(text: 'Lunas (${completedLoans.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddLoanScreen()),
              ).then((_) => _fetchLoans());
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLoanList(activeLoans, 'Belum ada pinjaman aktif.'),
                _buildLoanList(completedLoans, 'Belum ada pinjaman yang lunas.'),
              ],
            ),
    );
  }

  Widget _buildLoanList(List<Map<String, dynamic>> list, String emptyMessage) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_outlined, size: 48, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(emptyMessage, style: const TextStyle(color: AppColors.muted)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchLoans,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (ctx, i) {
          final l = list[i];
          final isLend = l['type'] == 'lend';
          final remaining = (num.tryParse(l['remaining_amount']?.toString() ?? '0')) ?? 0;
          final isOverdue = l['status'] == 'overdue';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isLend ? AppColors.income : AppColors.expense).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isLend ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isLend ? AppColors.income : AppColors.expense,
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      l['contact_name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  if (isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.expense.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('JATUH TEMPO', style: TextStyle(color: AppColors.expense, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    isLend ? 'Saya pinjamkan' : 'Saya pinjam',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  if (l['due_date'] != null)
                    Text('Jatuh tempo: ${l['due_date']}', style: const TextStyle(fontSize: 11)),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(remaining),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isLend ? AppColors.income : AppColors.expense,
                    ),
                  ),
                  Text(
                    '${l['installments_count'] ?? 0} cicilan',
                    style: const TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LoanDetailScreen(loanId: l['id'])),
                ).then((_) => _fetchLoans());
              },
            ),
          );
        },
      ),
    );
  }
}
