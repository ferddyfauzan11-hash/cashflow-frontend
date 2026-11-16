import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/all_tables.dart';
import 'daos/app_daos.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Categories,
    Pockets,
    PocketAllocations,
    Transactions,
    Loans,
    LoanInstallments,
  ],
  daos: [
    AppDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'cashflow_rs.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
