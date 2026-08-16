import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';

/// Proveedor de base de datos | Instancia única gestionada por Riverpod
/// Riverpod cachea automáticamente el valor retornado (comportamiento por defecto)
/// En producción se sobreescribe vía overrideWithValue desde main.dart
final Provider<AppDatabase> databaseProvider = Provider<AppDatabase>((ref) {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  // ✅ INSTANCIA ÚNICA: creada directamente, SIN autoreferencia circular
  // Riverpod garantiza que esto se ejecute UNA SOLA VEZ y cachee el resultado
  final db = AppDatabase();

  // ✅ Cierre limpio de conexión al desechar el provider
  ref.onDispose(() async {
    await db.close();
  });

  return db;
});
