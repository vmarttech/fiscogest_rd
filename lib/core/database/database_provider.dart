import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';

final Provider<AppDatabase> databaseProvider = Provider<AppDatabase>((ref) {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  // ✅ ÚNICA instancia creada en todo el proyecto
  final db = ref.watch<AppDatabase>(databaseProvider);

  ref.onDispose(() async {
    await db.close();
  });

  return db;
});