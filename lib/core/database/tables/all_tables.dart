import 'package:drift/drift.dart';

// 1. Categories Table
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text().withLength(max: 50)();
  TextColumn get type => text()(); // 'income' | 'expense'
  TextColumn get icon => text().nullable()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus => text().withDefault(const Constant('PENDING'))(); // 'PENDING' | 'SYNCED'
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// 2. Pockets Table
class Pockets extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text().withLength(max: 50)();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().withDefault(const Constant('#3B82F6'))();
  RealColumn get targetAmount => real().nullable()();
  RealColumn get currentBalance => real().withDefault(const Constant(0.0))();
  BoolColumn get hasAutoTarget => boolean().withDefault(const Constant(false))();
  IntColumn get targetMonths => integer().withDefault(const Constant(6))();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus => text().withDefault(const Constant('PENDING'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// 3. Pocket Allocations Table
class PocketAllocations extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get fromPocketId => text().nullable()();
  TextColumn get toPocketId => text().nullable()();
  RealColumn get amount => real()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get allocationDate => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus => text().withDefault(const Constant('PENDING'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// 4. Transactions Table
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get categoryId => text()();
  TextColumn get pocketId => text().nullable()();
  TextColumn get type => text()(); // 'income' | 'expense'
  RealColumn get amount => real()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get transactionDate => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus => text().withDefault(const Constant('PENDING'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// 5. Loans Table
class Loans extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get contactName => text().withLength(max: 100)();
  TextColumn get type => text()(); // 'lend' | 'borrow'
  RealColumn get principalAmount => real()();
  RealColumn get remainingAmount => real()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))(); // 'active' | 'completed' | 'overdue'
  TextColumn get notes => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus => text().withDefault(const Constant('PENDING'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// 6. Loan Installments Table
class LoanInstallments extends Table {
  TextColumn get id => text()();
  TextColumn get loanId => text()();
  TextColumn get userId => text()();
  RealColumn get amountPaid => real()();
  RealColumn get overpaymentAmount => real().withDefault(const Constant(0.0))();
  DateTimeColumn get paymentDate => dateTime()();
  BoolColumn get autoIncomeGenerated => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus => text().withDefault(const Constant('PENDING'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
