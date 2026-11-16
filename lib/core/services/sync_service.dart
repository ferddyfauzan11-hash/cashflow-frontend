import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../database/app_database.dart';
import '../database/daos/app_daos.dart';
import '../network/api_client.dart';

class SyncService {
  final ApiClient _apiClient = ApiClient();
  final _storage = const FlutterSecureStorage();
  final AppDao _dao;

  SyncService(AppDatabase db) : _dao = AppDao(db);

  Future<String?> getLastSyncedAt() async {
    return await _storage.read(key: 'last_synced_at');
  }

  Future<void> _setLastSyncedAt(String timestamp) async {
    await _storage.write(key: 'last_synced_at', value: timestamp);
  }

  Future<Map<String, int>> getPendingCounts(String userId) async {
    final catCount = (await _dao.getPendingCategories(userId)).length;
    final pockCount = (await _dao.getPendingPockets(userId)).length;
    final allocCount = (await _dao.getPendingAllocations(userId)).length;
    final trxCount = (await _dao.getPendingTransactions(userId)).length;
    final loanCount = (await _dao.getPendingLoans(userId)).length;
    final instCount = (await _dao.getPendingInstallments(userId)).length;

    return {
      'categories': catCount,
      'pockets': pockCount,
      'pocket_allocations': allocCount,
      'transactions': trxCount,
      'loans': loanCount,
      'loan_installments': instCount,
      'total': catCount + pockCount + allocCount + trxCount + loanCount + instCount,
    };
  }

  Future<bool> syncAll(String userId) async {
    try {
      // 1. PUSH
      final pendingCats = await _dao.getPendingCategories(userId);
      final pendingPocks = await _dao.getPendingPockets(userId);
      final pendingAllocs = await _dao.getPendingAllocations(userId);
      final pendingTrxs = await _dao.getPendingTransactions(userId);
      final pendingLoans = await _dao.getPendingLoans(userId);
      final pendingInsts = await _dao.getPendingInstallments(userId);

      final hasPending = pendingCats.isNotEmpty ||
          pendingPocks.isNotEmpty ||
          pendingAllocs.isNotEmpty ||
          pendingTrxs.isNotEmpty ||
          pendingLoans.isNotEmpty ||
          pendingInsts.isNotEmpty;

      if (hasPending) {
        final pushBody = {
          'categories': pendingCats.map((c) => {
            'id': c.id,
            'name': c.name,
            'type': c.type,
            'icon': c.icon,
            'is_default': c.isDefault,
            'is_deleted': c.isDeleted,
            'updated_at': c.updatedAt.toIso8601String(),
          }).toList(),
          'pockets': pendingPocks.map((p) => {
            'id': p.id,
            'name': p.name,
            'icon': p.icon,
            'color': p.color,
            'target_amount': p.targetAmount,
            'current_balance': p.currentBalance,
            'has_auto_target': p.hasAutoTarget,
            'target_months': p.targetMonths,
            'order_index': p.orderIndex,
            'is_deleted': p.isDeleted,
            'updated_at': p.updatedAt.toIso8601String(),
          }).toList(),
          'pocket_allocations': pendingAllocs.map((a) => {
            'id': a.id,
            'from_pocket_id': a.fromPocketId,
            'to_pocket_id': a.toPocketId,
            'amount': a.amount,
            'note': a.note,
            'allocation_date': a.allocationDate.toIso8601String().split('T')[0],
            'is_deleted': a.isDeleted,
            'updated_at': a.updatedAt.toIso8601String(),
          }).toList(),
          'transactions': pendingTrxs.map((t) => {
            'id': t.id,
            'category_id': t.categoryId,
            'pocket_id': t.pocketId,
            'type': t.type,
            'amount': t.amount,
            'description': t.description,
            'transaction_date': t.transactionDate.toIso8601String().split('T')[0],
            'is_deleted': t.isDeleted,
            'updated_at': t.updatedAt.toIso8601String(),
          }).toList(),
          'loans': pendingLoans.map((l) => {
            'id': l.id,
            'contact_name': l.contactName,
            'type': l.type,
            'principal_amount': l.principalAmount,
            'remaining_amount': l.remainingAmount,
            'due_date': l.dueDate?.toIso8601String().split('T')[0],
            'status': l.status,
            'notes': l.notes,
            'is_deleted': l.isDeleted,
            'updated_at': l.updatedAt.toIso8601String(),
          }).toList(),
          'loan_installments': pendingInsts.map((i) => {
            'id': i.id,
            'loan_id': i.loanId,
            'amount_paid': i.amountPaid,
            'overpayment_amount': i.overpaymentAmount,
            'payment_date': i.paymentDate.toIso8601String().split('T')[0],
            'auto_income_generated': i.autoIncomeGenerated,
            'notes': i.notes,
            'is_deleted': i.isDeleted,
            'updated_at': i.updatedAt.toIso8601String(),
          }).toList(),
        };

        final pushRes = await _apiClient.post('/sync/push', pushBody);
        if (pushRes.statusCode == 200) {
          final resData = jsonDecode(pushRes.body);
          final syncedIds = resData['synced_ids'] as Map<String, dynamic>;

          // Mark synced locally
          for (var id in (syncedIds['categories'] as List? ?? [])) {
            final cat = pendingCats.firstWhere((c) => c.id == id);
            await _dao.insertOrUpdateCategory(cat.toCompanion(true).copyWith(syncStatus: const Value('SYNCED')));
          }
          for (var id in (syncedIds['pockets'] as List? ?? [])) {
            final p = pendingPocks.firstWhere((item) => item.id == id);
            await _dao.insertOrUpdatePocket(p.toCompanion(true).copyWith(syncStatus: const Value('SYNCED')));
          }
          for (var id in (syncedIds['pocket_allocations'] as List? ?? [])) {
            final a = pendingAllocs.firstWhere((item) => item.id == id);
            await _dao.insertOrUpdateAllocation(a.toCompanion(true).copyWith(syncStatus: const Value('SYNCED')));
          }
          for (var id in (syncedIds['transactions'] as List? ?? [])) {
            final t = pendingTrxs.firstWhere((item) => item.id == id);
            await _dao.insertOrUpdateTransaction(t.toCompanion(true).copyWith(syncStatus: const Value('SYNCED')));
          }
          for (var id in (syncedIds['loans'] as List? ?? [])) {
            final l = pendingLoans.firstWhere((item) => item.id == id);
            await _dao.insertOrUpdateLoan(l.toCompanion(true).copyWith(syncStatus: const Value('SYNCED')));
          }
          for (var id in (syncedIds['loan_installments'] as List? ?? [])) {
            final i = pendingInsts.firstWhere((item) => item.id == id);
            await _dao.insertOrUpdateInstallment(i.toCompanion(true).copyWith(syncStatus: const Value('SYNCED')));
          }
        }
      }

      // 2. PULL
      final lastSynced = await getLastSyncedAt();
      final pullUrl = lastSynced != null ? '/sync/pull?last_synced_at=$lastSynced' : '/sync/pull';
      final pullRes = await _apiClient.get(pullUrl);

      if (pullRes.statusCode == 200) {
        final pullData = jsonDecode(pullRes.body);
        final data = pullData['data'] as Map<String, dynamic>;
        final serverTs = pullData['server_timestamp'] as String;

        // Categories
        for (var c in (data['categories'] as List? ?? [])) {
          await _dao.insertOrUpdateCategory(CategoriesCompanion(
            id: Value(c['id']),
            userId: Value(userId),
            name: Value(c['name']),
            type: Value(c['type']),
            icon: Value(c['icon']),
            isDefault: Value(c['is_default'] == true || c['is_default'] == 1),
            isDeleted: Value(c['is_deleted'] == true || c['is_deleted'] == 1),
            syncStatus: const Value('SYNCED'),
            createdAt: Value(DateTime.parse(c['created_at'])),
            updatedAt: Value(DateTime.parse(c['updated_at'])),
          ));
        }

        // Pockets
        for (var p in (data['pockets'] as List? ?? [])) {
          await _dao.insertOrUpdatePocket(PocketsCompanion(
            id: Value(p['id']),
            userId: Value(userId),
            name: Value(p['name']),
            icon: Value(p['icon']),
            color: Value(p['color'] ?? '#3B82F6'),
            targetAmount: Value(p['target_amount'] != null ? double.parse(p['target_amount'].toString()) : null),
            currentBalance: Value(double.parse(p['current_balance'].toString())),
            hasAutoTarget: Value(p['has_auto_target'] == true || p['has_auto_target'] == 1),
            targetMonths: Value(p['target_months'] ?? 6),
            orderIndex: Value(p['order_index'] ?? 0),
            isDeleted: Value(p['is_deleted'] == true || p['is_deleted'] == 1),
            syncStatus: const Value('SYNCED'),
            createdAt: Value(DateTime.parse(p['created_at'])),
            updatedAt: Value(DateTime.parse(p['updated_at'])),
          ));
        }

        // Transactions
        for (var t in (data['transactions'] as List? ?? [])) {
          await _dao.insertOrUpdateTransaction(TransactionsCompanion(
            id: Value(t['id']),
            userId: Value(userId),
            categoryId: Value(t['category_id']),
            pocketId: Value(t['pocket_id']),
            type: Value(t['type']),
            amount: Value(double.parse(t['amount'].toString())),
            description: Value(t['description']),
            transactionDate: Value(DateTime.parse(t['transaction_date'])),
            isDeleted: Value(t['is_deleted'] == true || t['is_deleted'] == 1),
            syncStatus: const Value('SYNCED'),
            createdAt: Value(DateTime.parse(t['created_at'])),
            updatedAt: Value(DateTime.parse(t['updated_at'])),
          ));
        }

        await _setLastSyncedAt(serverTs);
      }

      return true;
    } catch (_) {
      return false;
    }
  }
}

