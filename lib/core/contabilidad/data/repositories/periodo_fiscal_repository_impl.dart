import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/periodo_fiscal.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/enums/estado_periodo.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/repositories/i_periodo_fiscal_repository.dart';

class PeriodoFiscalRepositoryImpl implements IPeriodoFiscalRepository {
  PeriodoFiscalRepositoryImpl(this._db);

  final AppDatabase _db;

  PeriodoFiscal _map(PeriodosFiscalesTableData r) => PeriodoFiscal(
        id: r.id,
        codigo: r.codigo,
        nombre: r.nombre,
        fechaInicio: r.fechaInicio,
        fechaFin: r.fechaFin,
        estado: r.estado,
        paisCodigo: r.paisCodigo,
        creadoEn: r.creadoEn,
        actualizadoEn: r.actualizadoEn,
      );

  @override
  Future<PeriodoFiscal?> periodoAbiertoQueContiene(
    DateTime fecha, {
    String? paisCodigo,
  }) async {
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    final q = _db.select(_db.periodosFiscalesTable)
      ..where((t) => t.estado.equalsValue(EstadoPeriodo.abierto));
    if (paisCodigo != null && paisCodigo.isNotEmpty) {
      q.where((t) => t.paisCodigo.equals(paisCodigo.toUpperCase()));
    }
    final filas = await q.get();
    for (final f in filas) {
      final p = _map(f);
      if (p.contiene(dia)) return p;
    }
    return null;
  }

  @override
  Future<List<PeriodoFiscal>> listar({String? paisCodigo}) async {
    final q = _db.select(_db.periodosFiscalesTable)
      ..orderBy([(t) => OrderingTerm.desc(t.fechaInicio)]);
    if (paisCodigo != null && paisCodigo.isNotEmpty) {
      q.where((t) => t.paisCodigo.equals(paisCodigo.toUpperCase()));
    }
    final filas = await q.get();
    return filas.map(_map).toList();
  }

  @override
  Future<int> insertar(PeriodoFiscal periodo) async {
    final row = await _db.into(_db.periodosFiscalesTable).insertReturning(
          PeriodosFiscalesTableCompanion.insert(
            codigo: periodo.codigo.trim(),
            nombre: periodo.nombre.trim(),
            fechaInicio: periodo.fechaInicio,
            fechaFin: periodo.fechaFin,
            estado: Value(periodo.estado),
            paisCodigo: Value(periodo.paisCodigo.toUpperCase()),
            creadoEn: Value(periodo.creadoEn),
          ),
        );
    return row.id;
  }

  @override
  Future<bool> cerrar(int periodoId) async {
    if (periodoId <= 0) return false;
    final n = await (_db.update(_db.periodosFiscalesTable)
          ..where((t) => t.id.equals(periodoId)))
        .write(PeriodosFiscalesTableCompanion(
      estado: const Value(EstadoPeriodo.cerrado),
      actualizadoEn: Value(DateTime.now()),
    ));
    return n > 0;
  }

  @override
  Future<void> asegurarPeriodoAnualActual(String paisCodigo) async {
    final pais = paisCodigo.toUpperCase();
    final existing = await listar(paisCodigo: pais);
    if (existing.isNotEmpty) return;
    final y = DateTime.now().year;
    await insertar(PeriodoFiscal(
      codigo: '$pais-$y',
      nombre: 'Ejercicio $y',
      fechaInicio: DateTime(y, 1, 1),
      fechaFin: DateTime(y, 12, 31),
      estado: EstadoPeriodo.abierto,
      paisCodigo: pais,
      creadoEn: DateTime.now(),
    ));
  }
}
