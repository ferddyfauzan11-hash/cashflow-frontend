import 'dart:convert';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get('/categories');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] as List;
        setState(() {
          _categories = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddOrEditCategoryDialog({Map<String, dynamic>? category}) {
    final nameCtrl = TextEditingController(text: category?['name'] ?? '');
    final iconCtrl = TextEditingController(text: category?['icon'] ?? '🏷️');
    String type = category?['type'] ?? 'expense';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(category != null ? 'Edit Kategori' : 'Tambah Kategori'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: iconCtrl,
                          decoration: const InputDecoration(labelText: 'Icon'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: 'Nama Kategori *'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (category == null)
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(labelText: 'Tipe Kategori'),
                      items: const [
                        DropdownMenuItem(value: 'expense', child: Text('💸 Pengeluaran')),
                        DropdownMenuItem(value: 'income', child: Text('💰 Pemasukan')),
                      ],
                      onChanged: (val) => setDialogState(() => type = val ?? 'expense'),
                    ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('BATAL')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (nameCtrl.text.trim().isEmpty) return;
                          setDialogState(() => isSubmitting = true);

                          final body = {
                            'name': nameCtrl.text.trim(),
                            'icon': iconCtrl.text.trim(),
                            'type': type,
                          };

                          try {
                            final res = category != null
                                ? await _apiClient.put('/categories/${category['id']}', body)
                                : await _apiClient.post('/categories', body);

                            if (res.statusCode == 200 || res.statusCode == 201) {
                              Navigator.pop(ctx);
                              _fetchCategories();
                            }
                          } finally {
                            setDialogState(() => isSubmitting = false);
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('SIMPAN'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteCategory(String id) async {
    final res = await _apiClient.delete('/categories/$id');
    if (res.statusCode == 200) {
      _fetchCategories();
    } else {
      final err = jsonDecode(res.body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err['message'] ?? 'Gagal menghapus kategori'), backgroundColor: AppColors.expense),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final incomeCats = _categories.where((c) => c['type'] == 'income').toList();
    final expenseCats = _categories.where((c) => c['type'] == 'expense').toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Kelola Kategori'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddOrEditCategoryDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchCategories,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('💰 Kategori Pemasukan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  ...incomeCats.map((c) => _buildCategoryTile(c)),
                  const SizedBox(height: 20),
                  const Text('💸 Kategori Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  ...expenseCats.map((c) => _buildCategoryTile(c)),
                ],
              ),
            ),
    );
  }

  Widget _buildCategoryTile(Map<String, dynamic> c) {
    final isDefault = c['is_default'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(c['icon'] ?? '🏷️', style: const TextStyle(fontSize: 22)),
        title: Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: isDefault ? const Text('Default sistem', style: TextStyle(fontSize: 11, color: AppColors.muted)) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
              onPressed: () => _showAddOrEditCategoryDialog(category: c),
            ),
            if (!isDefault)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.expense),
                onPressed: () => _deleteCategory(c['id']),
              ),
          ],
        ),
      ),
    );
  }
}
