import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';

/// Fiaos pendientes (saldo > 0 y estado pendiente).
final fiosPendientesProvider =
    StreamProvider.autoDispose<List<FioData>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.fiosTable)
        ..where((t) => t.estado.equals('pendiente'))
        ..where((t) => t.saldoPendiente.isBiggerThanValue(0))
        ..orderBy([(t) => OrderingTerm.desc(t.fecha)]))
      .watch();
});

/// Todos los fiaos (historial simple).
final fiosTodosProvider = StreamProvider.autoDispose<List<FioData>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.fiosTable)
        ..orderBy([(t) => OrderingTerm.desc(t.fecha)]))
      .watch();
});

class FiosRepository {
  FiosRepository(this._db);
  final AppDatabase _db;

  /// Abono parcial o total. Si el saldo queda 0 → estado pagado.
  Future<void> abonar(int id, double monto) async {
    if (monto <= 0) throw ArgumentError('El abono debe ser mayor a 0');

    final row = await (_db.select(_db.fiosTable)
          ..where((t) => t.id.equals(id)))
        .getSingle();

    final nuevoAbonado = row.montoAbonado + monto;
    final nuevoSaldo = (row.saldoPendiente - monto).clamp(0.0, double.infinity);
    final estado = nuevoSaldo <= 0.001 ? 'pagado' : 'pendiente';

    await (_db.update(_db.fiosTable)..where((t) => t.id.equals(id))).write(
      FiosTableCompanion(
        montoAbonado: Value(nuevoAbonado),
        saldoPendiente: Value(nuevoSaldo),
        estado: Value(estado),
      ),
    );
  }
}

final fiosRepositoryProvider = Provider<FiosRepository>((ref) {
  return FiosRepository(ref.watch(databaseProvider));
});
