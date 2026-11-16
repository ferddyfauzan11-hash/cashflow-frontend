import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/currency_formatter.dart';

class TransferPocketScreen extends StatefulWidget {
  final String? initialFromPocketId;
  final String? initialToPocketId;

  const TransferPocketScreen({
    super.key,
    this.initialFromPocketId,
    this.initialToPocketId,
  });

  @override
  State<TransferPocketScreen> createState() => _TransferPocketScreenState();
}

class _TransferPocketScreenState extends State<TransferPocketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final ApiClient _apiClient = ApiClient();

  String? _fromPocketId;
  String? _toPocketId;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _pockets = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fromPocketId = widget.initialFromPocketId;
    _toPocketId = widget.initialToPocketId;
    _loadPockets();
  }

  Future<void> _loadPockets() async {
    try {
      final res = await _apiClient.get('/pockets');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] as List;
        setState(() {
          _pockets = data.map((e) => e as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromPocketId == _toPocketId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pocket asal dan tujuan tidak boleh sama'), backgroundColor: AppColors.expense),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final amount = double.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;

    final body = {
      'from_pocket_id': _fromPocketId,
      'to_pocket_id': _toPocketId,
      'amount': amount,
      'allocation_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'note': _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    };

    try {
      final res = await _apiClient.post('/pocket-allocations', body);
      if (res.statusCode == 201 && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        final err = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err['message'] ?? 'Gagal transfer dana'), backgroundColor: AppColors.expense),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.expense),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Antar Pocket'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // From Pocket
                    DropdownButtonFormField<String?>(
                      value: _fromPocketId,
                      decoration: const InputDecoration(
                        labelText: 'Dari Mana? *',
                        prefixIcon: Icon(Icons.outbox),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('🏦 Unallocated (Saldo Bebas)'),
                        ),
                        ..._pockets.map((p) => DropdownMenuItem<String?>(
                              value: p['id'] as String,
                              child: Text('${p['icon'] ?? '💼'} ${p['name']} (${CurrencyFormatter.formatCompact(num.parse(p['current_balance'].toString()))})'),
                            )),
                      ],
                      onChanged: (val) => setState(() => _fromPocketId = val),
                    ),
                    const SizedBox(height: 14),

                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_downward, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // To Pocket
                    DropdownButtonFormField<String?>(
                      value: _toPocketId,
                      decoration: const InputDecoration(
                        labelText: 'Ke Mana? *',
                        prefixIcon: Icon(Icons.move_to_inbox),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('🏦 Unallocated (Kembali Bebas)'),
                        ),
                        ..._pockets.map((p) => DropdownMenuItem<String?>(
                              value: p['id'] as String,
                              child: Text('${p['icon'] ?? '💼'} ${p['name']} (${CurrencyFormatter.formatCompact(num.parse(p['current_balance'].toString()))})'),
                            )),
                      ],
                      onChanged: (val) => setState(() => _toPocketId = val),
                    ),
                    const SizedBox(height: 20),

                    // Amount
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah Transfer *',
                        prefixText: 'Rp ',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Jumlah transfer wajib diisi';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                      title: Text(DateFormat('dd MMMM yyyy').format(_selectedDate)),
                      subtitle: const Text('Tanggal Transfer'),
                      trailing: const Icon(Icons.edit_calendar),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => _selectedDate = picked);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Note
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Catatan (Opsional)',
                        hintText: 'Misal: Alokasi bulanan',
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),
                    const SizedBox(height: 30),

                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                      child: _isSubmitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('TRANSFER SEKARANG'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
