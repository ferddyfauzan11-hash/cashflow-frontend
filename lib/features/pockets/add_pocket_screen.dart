import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';

class AddPocketScreen extends StatefulWidget {
  const AddPocketScreen({super.key});

  @override
  State<AddPocketScreen> createState() => _AddPocketScreenState();
}

class _AddPocketScreenState extends State<AddPocketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _iconController = TextEditingController(text: '💼');
  final ApiClient _apiClient = ApiClient();

  bool _hasAutoTarget = false;
  int _targetMonths = 6;
  String _selectedColor = '#3B82F6';
  bool _isLoading = false;

  final List<String> _presetIcons = ['💼', '🛡️', '🏠', '✈️', '🚗', '🎮', '📱', '🎓', '💍', '🎁'];
  final List<String> _presetColors = ['#3B82F6', '#22C55E', '#F59E0B', '#EF4444', '#8B5CF6', '#EC4899', '#14B8A6'];

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final body = {
      'name': _nameController.text.trim(),
      'icon': _iconController.text.trim(),
      'color': _selectedColor,
      'has_auto_target': _hasAutoTarget,
      if (_hasAutoTarget) 'target_months': _targetMonths,
      if (!_hasAutoTarget && _targetController.text.isNotEmpty)
        'target_amount': double.tryParse(_targetController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0,
    };

    try {
      final res = await _apiClient.post('/pockets', body);
      if (res.statusCode == 201 && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuat pocket'), backgroundColor: AppColors.expense),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.expense),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Pocket Baru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon selector
              const Text('Pilih Emoji / Ikon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: _presetIcons.map((ico) {
                  final isSelected = _iconController.text == ico;
                  return GestureDetector(
                    onTap: () => setState(() => _iconController.text = ico),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accent.withOpacity(0.2) : AppColors.surfaceWhite,
                        border: Border.all(color: isSelected ? AppColors.accent : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(ico, style: const TextStyle(fontSize: 22)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Kantong / Pocket *',
                  hintText: 'Misal: Liburan Jepang, DP Rumah',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Nama wajib diisi';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Color picker
              const Text('Warna Label', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: _presetColors.map((hex) {
                  final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                  final isSelected = _selectedColor == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = hex),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.black, width: 2.5) : null,
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Dana Darurat toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Mode Dana Darurat (Auto Target)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Otomatis menghitung target dari rata-rata pengeluaran 3 bulan'),
                value: _hasAutoTarget,
                activeColor: AppColors.accent,
                onChanged: (val) => setState(() => _hasAutoTarget = val),
              ),
              const SizedBox(height: 10),

              if (_hasAutoTarget) ...[
                DropdownButtonFormField<int>(
                  value: _targetMonths,
                  decoration: const InputDecoration(labelText: 'Berapa Bulan Pengeluaran?'),
                  items: [3, 6, 9, 12].map((m) {
                    return DropdownMenuItem(value: m, child: Text('$m Bulan'));
                  }).toList(),
                  onChanged: (val) => setState(() => _targetMonths = val ?? 6),
                ),
              ] else ...[
                TextFormField(
                  controller: _targetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Target Dana (Opsional)',
                    hintText: 'Misal: 10000000',
                    prefixText: 'Rp ',
                  ),
                ),
              ],
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('SIMPAN POCKET'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
