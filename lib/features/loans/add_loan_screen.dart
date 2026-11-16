import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';

class AddLoanScreen extends StatefulWidget {
  const AddLoanScreen({super.key});

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final ApiClient _apiClient = ApiClient();

  String _type = 'lend'; // 'lend' | 'borrow'
  DateTime? _dueDate;
  bool _isSubmitting = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final amount = double.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;

    final body = {
      'contact_name': _nameController.text.trim(),
      'type': _type,
      'principal_amount': amount,
      if (_dueDate != null) 'due_date': DateFormat('yyyy-MM-dd').format(_dueDate!),
      'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    };

    try {
      final res = await _apiClient.post('/loans', body);
      if (res.statusCode == 201 && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mencatat pinjaman'), backgroundColor: AppColors.expense),
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
        title: const Text('Catat Pinjaman Baru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type Selector
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = 'lend'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _type == 'lend' ? AppColors.income : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '🤝 Saya Beri Pinjaman',
                            style: TextStyle(
                              color: _type == 'lend' ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = 'borrow'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _type == 'borrow' ? AppColors.expense : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '💳 Saya Berhutang',
                            style: TextStyle(
                              color: _type == 'borrow' ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Contact Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Kontak / Teman *',
                  hintText: 'Misal: Budi Santoso',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Nama kontak wajib diisi';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Pinjaman *',
                  prefixText: 'Rp ',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Jumlah wajib diisi';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Due Date (Optional)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined, color: AppColors.primary),
                title: Text(_dueDate != null ? DateFormat('dd MMMM yyyy').format(_dueDate!) : 'Pilih Jatuh Tempo (Opsional)'),
                trailing: _dueDate != null
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _dueDate = null))
                    : const Icon(Icons.calendar_month),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
              ),
              const SizedBox(height: 14),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  hintText: 'Misal: Keperluan renovasi rumah',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('SIMPAN PINJAMAN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
