import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/asiento_contable.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/linea_asiento.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/enums/estado_asiento.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/repositories/i_asiento_repository.dart';

/// Implementación local (Drift) de [IAsientoRepository].
/// Repositorio plano sobre [AppDatabase]. Cabecera + líneas en una sola
/// transacción. Todos los montos se manejan en centavos enteros.
class AsientoRepositoryImpl implements IAsientoRepository {
  AsientoRepositoryImpl(this._db);

  final AppDatabase _db;

  AsientoContable _aEntidad(
    AsientosTableData fila, [
    List<LineaAsiento> lineas = const <LineaAsiento>[],
  ]) {
    return AsientoContable(
      id: fila.id,
      numeroAsiento: fila.numeroAsiento,
      fecha: fila.fecha,
      concepto: fila.concepto,
      estado: fila.estado,
      documentoOrigen: fila.documentoOrigen,
      tipoOrigen: fila.tipoOrigen,
      referenciaId: fila.referenciaId,
      lineas: lineas,
      creadoEn: fila.creadoEn,
      actualizadoEn: fila.actualizadoEn,
    );
  }

  @override
  Future<AsientoContable> registrar(
    AsientoContable asiento,
    List<LineaAsiento> lineas,
  ) async {
    // Validación de dominio antes de tocar la base de datos.
    if (!asiento.esValido) {
      throw ArgumentError(
          'acct_error_invalid_asiento:${asiento.errores.join('|')}');
    }
    if (lineas.isEmpty) {
      throw ArgumentError('acct_error_no_lines');
    }
    for (final linea in lineas) {
      if (!linea.esValida) {
        throw ArgumentError('acct_error_invalid_line:${linea.cuentaId}');
      }
    }
    // Defensa en profundidad (R5): los estados terminales no se re-registran.
    if (asiento.estado == EstadoAsiento.contabilizado) {
      throw StateError('acct_error_already_posted:${asiento.estado.name}');
    }
    if (asiento.estado == EstadoAsiento.anulado) {
      throw StateError('acct_error_already_voided:${asiento.estado.name}');
    }

    final numero = asiento.numeroAsiento.trim();
    if (numero.isEmpty) {
      throw ArgumentError('acct_error_number_required');
    }

    return _db.transaction(() async {
      // El número es único; el chequeo va dentro de la transacción.
      final duplicado = await (_db.select(_db.asientosTable)
            ..where((t) => t.numeroAsiento.equals(numero)))
          .getSingleOrNull();
      if (duplicado != null) {
        throw StateError('acct_error_number_duplicated:$numero');
      }

      final cabecera = await _db
          .into(_db.asientosTable)
          .insertReturning(AsientosTableCompanion.insert(
            numeroAsiento: numero,
            fecha: asiento.fecha,
            concepto: asiento.concepto.trim(),
            estado: Value(asiento.estado),
            documentoOrigen: Value(asiento.documentoOrigen),
            tipoOrigen: Value(asiento.tipoOrigen),
            referenciaId: Value(asiento.referenciaId),
            creadoEn: Value(asiento.creadoEn),
            actualizadoEn: Value(asiento.actualizadoEn),
          ));

      for (final linea in lineas) {
        await _db.into(_db.lineasAsientoTable).insert(
              LineasAsientoTableCompanion.insert(
                asientoId: cabecera.id,
                cuentaId: linea.cuentaId,
                debeCents: Value(linea.debeCents),
                haberCents: Value(linea.haberCents),
                conceptoLinea: Value(linea.concepto),
              ),
            );
      }

      final persistidas = await obtenerLineas(cabecera.id);
      return _aEntidad(cabecera, persistidas);
    });
  }

  @override
  Future<AsientoContable?> obtenerPorId(int asientoId) async {
    if (asientoId <= 0) return null;
    final fila = await (_db.select(_db.asientosTable)
          ..where((t) => t.id.equals(asientoId)))
        .getSingleOrNull();
    if (fila == null) return null;
    return _aEntidad(fila, await obtenerLineas(asientoId));
  }

  @override
  Future<List<LineaAsiento>> obtenerLineas(int asientoId) async {
    if (asientoId <= 0) return const <LineaAsiento>[];
    final filas = await (_db.select(_db.lineasAsientoTable)
          ..where((t) => t.asientoId.equals(asientoId))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    return filas
        .map((l) => LineaAsiento(
              id: l.id,
              asientoId: l.asientoId,
              cuentaId: l.cuentaId,
              debeCents: l.debeCents,
              haberCents: l.haberCents,
              concepto: l.conceptoLinea,
            ))
        .toList();
  }

  @override
  Future<List<AsientoContable>> listar({
    DateTime? desde,
    DateTime? hasta,
    int? cuentaId,
    int limite = 50,
    int offset = 0,
  }) async {
    limite = limite < 1 ? 1 : (limite > 500 ? 500 : limite);
    offset = offset < 0 ? 0 : offset;
    if (desde != null && hasta != null && desde.isAfter(hasta)) {
      return const <AsientoContable>[];
    }
    var idsCuenta = <int>{};
    if (cuentaId != null && cuentaId > 0) {
      final lineas = await (_db.select(_db.lineasAsientoTable)
            ..where((t) => t.cuentaId.equals(cuentaId)))
          .get();
      idsCuenta = lineas.map((l) => l.asientoId).toSet();
      if (idsCuenta.isEmpty) return const <AsientoContable>[];
    }

    final consulta = _db.select(_db.asientosTable);
    consulta.where((t) {
      final clausulas = <Expression<bool>>[];
      if (desde != null) clausulas.add(t.fecha.isBiggerOrEqualValue(desde));
      if (hasta != null) clausulas.add(t.fecha.isSmallerOrEqualValue(hasta));
      if (idsCuenta.isNotEmpty) clausulas.add(t.id.isIn(idsCuenta));
      if (clausulas.isEmpty) return const Constant(true);
      return clausulas.reduce((a, b) => a & b);
    });
    consulta
      ..orderBy([
        (t) => OrderingTerm.desc(t.fecha),
        (t) => OrderingTerm.desc(t.id),
      ])
      ..limit(limite, offset: offset);

    final filas = await consulta.get();
    final porAsiento = <int, List<LineaAsiento>>{};
    if (filas.isNotEmpty) {
      final ids = filas.map((f) => f.id).toList();
      final todasLineas = await (_db.select(_db.lineasAsientoTable)
            ..where((t) => t.asientoId.isIn(ids))
            ..orderBy([
              (t) => OrderingTerm.asc(t.asientoId),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .get();
      for (final l in todasLineas) {
        porAsiento
            .putIfAbsent(l.asientoId, () => <LineaAsiento>[])
            .add(LineaAsiento(
              id: l.id,
              asientoId: l.asientoId,
              cuentaId: l.cuentaId,
              debeCents: l.debeCents,
              haberCents: l.haberCents,
              concepto: l.conceptoLinea,
            ));
      }
    }
    return filas
        .map((fila) =>
            _aEntidad(fila, porAsiento[fila.id] ?? const <LineaAsiento>[]))
        .toList();
  }

  @override
  Future<bool> anular(int asientoId, String motivo) async {
    final motivoLimpio = motivo.trim();
    if (asientoId <= 0 || motivoLimpio.isEmpty) return false;

    return _db.transaction(() async {
      final existente = await (_db.select(_db.asientosTable)
            ..where((t) => t.id.equals(asientoId)))
          .getSingleOrNull();
      if (existente == null) return false;
      if (existente.estado == EstadoAsiento.anulado) return false;
      if (existente.estado != EstadoAsiento.contabilizado) return false;

      final afectadas = await (_db.update(_db.asientosTable)
            ..where((t) => t.id.equals(asientoId)))
          .write(AsientosTableCompanion(
        estado: const Value(EstadoAsiento.anulado),
        motivoAnulacion: Value(motivoLimpio),
        actualizadoEn: Value(DateTime.now()),
      ));
      return afectadas > 0;
    });
  }

  @override
  Future<String> obtenerSiguienteNumero() async {
    final filas = await (_db.select(_db.asientosTable)
          ..where((t) => t.numeroAsiento.like('AS-%')))
        .get();
    final formato = RegExp(r'^AS-(\d+)$');
    var maximo = 0;
    for (final fila in filas) {
      final numero = fila.numeroAsiento.trim();
      if (numero.isEmpty) continue;
      final coincidencia = formato.firstMatch(numero);
      if (coincidencia == null) continue;
      final valor = int.tryParse(coincidencia.group(1)!);
      if (valor == null) continue;
      maximo = math.max(maximo, valor);
    }
    final siguiente = maximo + 1;
    return 'AS-${siguiente.toString().padLeft(6, '0')}';
  }
}
