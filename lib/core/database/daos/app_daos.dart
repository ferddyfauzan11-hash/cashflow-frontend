import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/all_tables.dart';

part 'app_daos.g.dart';

@DriftAccessor(tables: [
  Categories,
  Pockets,
  PocketAllocations,
  Transactions,
  Loans,
  LoanInstallments,
])
class AppDao extends DatabaseAccessor<AppDatabase> with _$AppDaoMixin {
  AppDao(super.db);

  // CATEGORIES
  Stream<List<Category>> watchCategories(String userId) {
    return (select(categories)
          ..where((c) => c.userId.equals(userId) & c.isDeleted.equals(false))
          ..orderBy([
            (c) => OrderingTerm(expression: c.type),
            (c) => OrderingTerm(expression: c.isDefault, mode: OrderingMode.desc),
            (c) => OrderingTerm(expression: c.name),
          ]))
        .watch();
  }

  Future<List<Category>> getCategories(String userId) {
    return (select(categories)
          ..where((c) => c.userId.equals(userId) & c.isDeleted.equals(false)))
        .get();
  }

  Future<void> insertOrUpdateCategory(CategoriesCompanion entry) {
    return into(categories).insertOnConflictUpdate(entry);
  }

  // POCKETS
  Stream<List<Pocket>> watchPockets(String userId) {
    return (select(pockets)
          ..where((p) => p.userId.equals(userId) & p.isDeleted.equals(false))
          ..orderBy([(p) => OrderingTerm(expression: p.orderIndex)]))
        .watch();
  }

  Future<List<Pocket>> getPockets(String userId) {
    return (select(pockets)
          ..where((p) => p.userId.equals(userId) & p.isDeleted.equals(false)))
        .get();
  }

  Future<Pocket?> getPocket(String id) {
    return (select(pockets)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertOrUpdatePocket(PocketsCompanion entry) {
    return into(pockets).insertOnConflictUpdate(entry);
  }

  // POCKET ALLOCATIONS
  Stream<List<PocketAllocation>> watchAllocations(String userId, {String? pocketId}) {
    var query = select(pocketAllocations)
      ..where((a) => a.userId.equals(userId) & a.isDeleted.equals(false));
    if (pocketId != null) {
      query = query
        ..where((a) => a.fromPocketId.equals(pocketId) | a.toPocketId.equals(pocketId));
    }
    query = query..orderBy([(a) => OrderingTerm(expression: a.allocationDate, mode: OrderingMode.desc)]);
    return query.watch();
  }

  Future<void> insertOrUpdateAllocation(PocketAllocationsCompanion entry) {
    return into(pocketAllocations).insertOnConflictUpdate(entry);
  }

  // TRANSACTIONS
  Stream<List<Transaction>> watchTransactions(String userId, {String? type, String? pocketId}) {
    var query = select(transactions)
      ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false));
    if (type != null) {
      query = query..where((t) => t.type.equals(type));
    }
    if (pocketId != null) {
      if (pocketId == 'unallocated') {
        query = query..where((t) => t.pocketId.isNull());
      } else {
        query = query..where((t) => t.pocketId.equals(pocketId));
      }
    }
    query = query
      ..orderBy([
        (t) => OrderingTerm(expression: t.transactionDate, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);
    return query.watch();
  }

  Future<List<Transaction>> getTransactions(String userId) {
    return (select(transactions)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false)))
        .get();
  }

  Future<void> insertOrUpdateTransaction(TransactionsCompanion entry) {
    return into(transactions).insertOnConflictUpdate(entry);
  }

  // LOANS
  Stream<List<Loan>> watchLoans(String userId, {String? status, String? type}) {
    var query = select(loans)
      ..where((l) => l.userId.equals(userId) & l.isDeleted.equals(false));
    if (status != null) {
      query = query..where((l) => l.status.equals(status));
    }
    if (type != null) {
      query = query..where((l) => l.type.equals(type));
    }
    query = query..orderBy([(l) => OrderingTerm(expression: l.createdAt, mode: OrderingMode.desc)]);
    return query.watch();
  }

  Future<Loan?> getLoan(String id) {
    return (select(loans)..where((l) => l.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertOrUpdateLoan(LoansCompanion entry) {
    return into(loans).insertOnConflictUpdate(entry);
  }

  // LOAN INSTALLMENTS
  Stream<List<LoanInstallment>> watchInstallments(String loanId) {
    return (select(loanInstallments)
          ..where((i) => i.loanId.equals(loanId) & i.isDeleted.equals(false))
          ..orderBy([(i) => OrderingTerm(expression: i.paymentDate, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<void> insertOrUpdateInstallment(LoanInstallmentsCompanion entry) {
    return into(loanInstallments).insertOnConflictUpdate(entry);
  }

  // PENDING SYNC RECORDS
  Future<List<Category>> getPendingCategories(String userId) {
    return (select(categories)..where((c) => c.userId.equals(userId) & c.syncStatus.equals('PENDING'))).get();
  }

  Future<List<Pocket>> getPendingPockets(String userId) {
    return (select(pockets)..where((p) => p.userId.equals(userId) & p.syncStatus.equals('PENDING'))).get();
  }

  Future<List<PocketAllocation>> getPendingAllocations(String userId) {
    return (select(pocketAllocations)..where((a) => a.userId.equals(userId) & a.syncStatus.equals('PENDING'))).get();
  }

  Future<List<Transaction>> getPendingTransactions(String userId) {
    return (select(transactions)..where((t) => t.userId.equals(userId) & t.syncStatus.equals('PENDING'))).get();
  }

  Future<List<Loan>> getPendingLoans(String userId) {
    return (select(loans)..where((l) => l.userId.equals(userId) & l.syncStatus.equals('PENDING'))).get();
  }

  Future<List<LoanInstallment>> getPendingInstallments(String userId) {
    return (select(loanInstallments)..where((i) => i.userId.equals(userId) & i.syncStatus.equals('PENDING'))).get();
  }
}
