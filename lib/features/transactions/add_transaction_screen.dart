import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/currency_formatter.dart';

class AddTransactionScreen extends StatefulWidget {
  final String initialType;
  final Map<String, dynamic>? editTransaction;

  const AddTransactionScreen({
    super.key,
    this.initialType = 'expense',
    this.editTransaction,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final ApiClient _apiClient = ApiClient();

  late String _type;
  String? _selectedCategoryId;
  String? _selectedPocketId;
  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _pockets = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _type = widget.editTransaction?['type'] ?? widget.initialType;
    if (widget.editTransaction != null) {
      final t = widget.editTransaction!;
      _amountController.text = (t['amount'] as num).toInt().toString();
      _descController.text = t['description'] ?? '';
      _selectedCategoryId = t['category_id'];
      _selectedPocketId = t['pocket_id'];
      if (t['transaction_date'] != null) {
        _selectedDate = DateTime.parse(t['transaction_date']);
      }
    }
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    try {
      final resCat = await _apiClient.get('/categories');
      final resPock = await _apiClient.get('/pockets');

      if (resCat.statusCode == 200 && resPock.statusCode == 200) {
        final cats = (jsonDecode(resCat.body)['data'] as List).cast<Map<String, dynamic>>();
        final pocks = (jsonDecode(resPock.body)['data'] as List).cast<Map<String, dynamic>>();

        setState(() {
          _categories = cats;
          _pockets = pocks;
          _isLoading = false;

          // Default category matching type
          if (_selectedCategoryId == null) {
            final match = _categories.firstWhere(
              (c) => c['type'] == _type,
              orElse: () => _categories.isNotEmpty ? _categories.first : {},
            );
            if (match.isNotEmpty) _selectedCategoryId = match['id'];
          }
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu'), backgroundColor: AppColors.expense),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final amount = double.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;

    final body = {
      'category_id': _selectedCategoryId,
      'pocket_id': _selectedPocketId,
      'type': _type,
      'amount': amount,
      'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      'transaction_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
    };

    try {
      final res = widget.editTransaction != null
          ? await _apiClient.put('/transactions/${widget.editTransaction!['id']}', body)
          : await _apiClient.post('/transactions', body);

      if ((res.statusCode == 201 || res.statusCode == 200) && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        final err = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err['message'] ?? 'Gagal menyimpan transaksi'), backgroundColor: AppColors.expense),
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
    final filteredCategories = _categories.where((c) => c['type'] == _type).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editTransaction != null ? 'Edit Transaksi' : 'Tambah Transaksi'),
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
                    // Type selector tab
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _type = 'expense';
                                  _selectedCategoryId = null;
                                  final match = _categories.firstWhere((c) => c['type'] == 'expense', orElse: () => {});
                                  if (match.isNotEmpty) _selectedCategoryId = match['id'];
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _type == 'expense' ? AppColors.expense : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '💸 Pengeluaran',
                                  style: TextStyle(
                                    color: _type == 'expense' ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _type = 'income';
                                  _selectedCategoryId = null;
                                  final match = _categories.firstWhere((c) => c['type'] == 'income', orElse: () => {});
                                  if (match.isNotEmpty) _selectedCategoryId = match['id'];
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _type == 'income' ? AppColors.income : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '💰 Pemasukan',
                                  style: TextStyle(
                                    color: _type == 'income' ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Amount Field
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        labelText: 'Jumlah *',
                        prefixText: 'Rp ',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Jumlah wajib diisi';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'Kategori *'),
                      items: filteredCategories.map((c) {
                        return DropdownMenuItem<String>(
                          value: c['id'] as String,
                          child: Text('${c['icon'] ?? '🏷️'} ${c['name']}'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCategoryId = val),
                    ),
                    const SizedBox(height: 16),

                    // Pocket Dropdown
                    DropdownButtonFormField<String?>(
                      value: _selectedPocketId,
                      decoration: const InputDecoration(
                        labelText: 'Pocket / Kantong (Opsional)',
                        hintText: 'Pilih kantong tujuan',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('🏦 Unallocated (Default)'),
                        ),
                        ..._pockets.map((p) => DropdownMenuItem<String?>(
                              value: p['id'] as String,
                              child: Text('${p['icon'] ?? '💼'} ${p['name']} (${CurrencyFormatter.formatCompact(num.parse(p['current_balance'].toString()))})'),
                            )),
                      ],
                      onChanged: (val) => setState(() => _selectedPocketId = val),
                    ),
                    const SizedBox(height: 16),

                    // Transaction Date
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                      title: Text(DateFormat('dd MMMM yyyy').format(_selectedDate)),
                      subtitle: const Text('Tanggal Transaksi'),
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

                    // Description / Note
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Catatan (Opsional)',
                        hintText: 'Misal: Makan siang di warteg',
                        prefixIcon: Icon(Icons.edit_note),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                      child: _isSubmitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('SIMPAN TRANSAKSI'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
