import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/currency_formatter.dart';

class LoanDetailScreen extends StatefulWidget {
  final String loanId;

  const LoanDetailScreen({super.key, required this.loanId});

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _loan;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get('/loans/${widget.loanId}');
      if (res.statusCode == 200) {
        setState(() {
          _loan = jsonDecode(res.body)['data'];
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showPayInstallmentDialog() {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime payDate = DateTime.now();
    bool isPaying = false;

    final remaining = (num.tryParse(_loan?['remaining_amount']?.toString() ?? '0')) ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Bayar Cicilan / Pelunasan',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sisa Pinjaman: ${CurrencyFormatter.format(remaining)}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah Bayar *',
                        prefixText: 'Rp ',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Catatan (Opsional)',
                        hintText: 'Misal: Cicilan ke-2 via transfer',
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                      onPressed: isPaying
                          ? null
                          : () async {
                              final amt = double.tryParse(amountCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
                              if (amt <= 0) return;

                              setSheetState(() => isPaying = true);

                              final body = {
                                'amount_paid': amt,
                                'payment_date': DateFormat('yyyy-MM-dd').format(payDate),
                                'notes': notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                              };

                              try {
                                final res = await _apiClient.post('/loans/${widget.loanId}/installments', body);
                                if (res.statusCode == 201 && mounted) {
                                  Navigator.pop(ctx);
                                  final resData = jsonDecode(res.body);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(resData['message'] ?? 'Cicilan berhasil dibayar!'),
                                      backgroundColor: AppColors.income,
                                    ),
                                  );
                                  _fetchDetail();
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.expense),
                                );
                              } finally {
                                setSheetState(() => isPaying = false);
                              }
                            },
                      child: isPaying
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('PROSES PEMBAYARAN'),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteLoan() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Catatan Pinjaman?'),
        content: const Text('Catatan pinjaman beserta seluruh riwayat cicilannya akan dihapus.'),
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
      final res = await _apiClient.delete('/loans/${widget.loanId}');
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

    final l = _loan ?? {};
    final isLend = l['type'] == 'lend';
    final principal = (num.tryParse(l['principal_amount']?.toString() ?? '0')) ?? 0;
    final remaining = (num.tryParse(l['remaining_amount']?.toString() ?? '0')) ?? 0;
    final isCompleted = l['status'] == 'completed';
    final installments = (l['installments'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(l['contact_name'] ?? 'Detail Pinjaman'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _deleteLoan,
            tooltip: 'Hapus Pinjaman',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDetail,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Loan Header Card
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isLend ? AppColors.income : AppColors.expense).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isLend ? '🤝 SAYA PINJAMKAN' : '💳 SAYA BERHUTANG',
                          style: TextStyle(
                            color: isLend ? AppColors.income : AppColors.expense,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isCompleted ? AppColors.income.withOpacity(0.2) : AppColors.warning.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isCompleted ? 'LUNAS' : (l['status'] == 'overdue' ? 'JATUH TEMPO' : 'AKTIF'),
                          style: TextStyle(
                            color: isCompleted ? AppColors.income : AppColors.warning,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l['contact_name'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sisa yang harus ${isLend ? 'diterima' : 'dibayar'}:',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(remaining),
                    style: TextStyle(
                      color: isCompleted ? Colors.white60 : Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pokok: ${CurrencyFormatter.format(principal)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      if (l['due_date'] != null)
                        Text(
                          'Jatuh Tempo: ${l['due_date']}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (!isCompleted)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.payment),
                label: const Text('BAYAR CICILAN / LUNASI'),
                onPressed: _showPayInstallmentDialog,
              ),

            const SizedBox(height: 24),

            // Installments History
            const Text('Riwayat Pembayaran Cicilan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
            const SizedBox(height: 10),
            if (installments.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(12)),
                child: const Center(
                  child: Text('Belum ada cicilan yang dibayar.', style: TextStyle(color: AppColors.muted)),
                ),
              )
            else
              ...installments.map((inst) {
                final overpay = (num.tryParse(inst['overpayment_amount']?.toString() ?? '0')) ?? 0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.income.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: AppColors.income, size: 20),
                    ),
                    title: Text(
                      CurrencyFormatter.format(num.parse(inst['amount_paid'].toString())),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(inst['payment_date'] ?? ''),
                        if (inst['notes'] != null && inst['notes'].toString().isNotEmpty)
                          Text(inst['notes'], style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                        if (overpay > 0)
                          Text(
                            'Kelebihan ${CurrencyFormatter.format(overpay)} (Auto Income)',
                            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                      ],
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

