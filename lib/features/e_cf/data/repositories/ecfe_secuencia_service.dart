import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/tipo_ecf.dart';

class EcfeSecuenciaInfo {
  const EcfeSecuenciaInfo({
    required this.id,
    required this.tipoEcf,
    required this.secuenciaActual,
    required this.secuenciaDesde,
    required this.secuenciaHasta,
    this.fechaVencimiento,
    required this.activo,
  });

  final int id;
  final int tipoEcf;
  final int secuenciaActual;
  final int secuenciaDesde;
  final int secuenciaHasta;
  final DateTime? fechaVencimiento;
  final bool activo;

  int get disponibles {
    final left = secuenciaHasta - secuenciaActual;
    return left < 0 ? 0 : left;
  }

  bool get vencida {
    final f = fechaVencimiento;
    if (f == null) return false;
    final hoy = DateTime.now();
    final d = DateTime(hoy.year, hoy.month, hoy.day);
    final v = DateTime(f.year, f.month, f.day);
    return d.isAfter(v);
  }

  String get tipoLabel {
    final t = TipoEcf.fromCodigo(tipoEcf);
    return t != null ? 'E${t.codigo} · ${t.descripcion}' : 'E$tipoEcf';
  }
}

class EcfeSecuenciaService {
  EcfeSecuenciaService(this._db);
  final AppDatabase _db;

  static final _encfRe = RegExp(r'^E(31|32|33|34|41|43|44|45|46|47)\d{10}$');

  static bool esEncfFormal(String? value) {
    final v = (value ?? '').trim().toUpperCase();
    return _encfRe.hasMatch(v);
  }

  Future<List<EcfeSecuenciaInfo>> listar() async {
    final rows = await (_db.select(_db.ecfeSecuenciasTable)
          ..orderBy([(t) => OrderingTerm.asc(t.tipoEcf)]))
        .get();
    return rows
        .map(
          (r) => EcfeSecuenciaInfo(
            id: r.id,
            tipoEcf: r.tipoEcf,
            secuenciaActual: r.secuenciaActual,
            secuenciaDesde: r.secuenciaDesde,
            secuenciaHasta: r.secuenciaHasta,
            fechaVencimiento: r.fechaVencimiento,
            activo: r.activo,
          ),
        )
        .toList();
  }

  Future<void> asegurarTiposBase() async {
    for (final tipo in [
      TipoEcf.facturaCreditoFiscal,
      TipoEcf.facturaConsumo,
      TipoEcf.notaDebito,
      TipoEcf.notaCredito,
    ]) {
      final rows = await (_db.select(_db.ecfeSecuenciasTable)
            ..where((t) => t.tipoEcf.equals(tipo.codigo))
            ..limit(1))
          .get();
      if (rows.isEmpty) {
        await _db.into(_db.ecfeSecuenciasTable).insert(
              EcfeSecuenciasTableCompanion.insert(
                tipoEcf: tipo.codigo,
                secuenciaActual: const Value(0),
                secuenciaDesde: const Value(1),
                secuenciaHasta: const Value(100),
                fechaVencimiento:
                    Value(DateTime(DateTime.now().year + 1, 12, 31)),
                activo: const Value(true),
              ),
            );
      }
    }
  }

  Future<void> guardar({
    int? id,
    required int tipoEcf,
    required int secuenciaActual,
    required int secuenciaDesde,
    required int secuenciaHasta,
    DateTime? fechaVencimiento,
    required bool activo,
  }) async {
    if (secuenciaDesde < 1 || secuenciaHasta < secuenciaDesde) {
      throw ArgumentError('Rango inválido (desde/hasta)');
    }
    if (secuenciaActual < secuenciaDesde - 1 ||
        secuenciaActual > secuenciaHasta) {
      throw ArgumentError(
        'secuenciaActual debe estar entre ${secuenciaDesde - 1} y $secuenciaHasta',
      );
    }
    if (id != null) {
      await (_db.update(_db.ecfeSecuenciasTable)..where((t) => t.id.equals(id)))
          .write(
        EcfeSecuenciasTableCompanion(
          tipoEcf: Value(tipoEcf),
          secuenciaActual: Value(secuenciaActual),
          secuenciaDesde: Value(secuenciaDesde),
          secuenciaHasta: Value(secuenciaHasta),
          fechaVencimiento: Value(fechaVencimiento),
          activo: Value(activo),
        ),
      );
    } else {
      await _db.into(_db.ecfeSecuenciasTable).insert(
            EcfeSecuenciasTableCompanion.insert(
              tipoEcf: tipoEcf,
              secuenciaActual: Value(secuenciaActual),
              secuenciaDesde: Value(secuenciaDesde),
              secuenciaHasta: Value(secuenciaHasta),
              fechaVencimiento: Value(fechaVencimiento),
              activo: Value(activo),
            ),
          );
    }
  }

  Future<({String encf, DateTime? vencimiento})> siguiente(TipoEcf tipo) async {
    final rows = await (_db.select(_db.ecfeSecuenciasTable)
          ..where((t) => t.tipoEcf.equals(tipo.codigo) & t.activo.equals(true))
          ..limit(1))
        .get();
    if (rows.isEmpty) {
      throw StateError(
        'No hay secuencia activa para e-CF tipo ${tipo.codigo} (E${tipo.codigo}). '
        'Configúrala en e-CF → Configuración → Secuencias e-NCF.',
      );
    }
    final r = rows.first;
    if (r.fechaVencimiento != null) {
      final f = r.fechaVencimiento!;
      final hoy = DateTime.now();
      final d = DateTime(hoy.year, hoy.month, hoy.day);
      final v = DateTime(f.year, f.month, f.day);
      if (d.isAfter(v)) {
        throw StateError(
          'Secuencia e-NCF tipo ${tipo.codigo} vencida ($f). '
          'Actualiza el rango autorizado por la DGII.',
        );
      }
    }
    var next = r.secuenciaActual + 1;
    if (next < r.secuenciaDesde) {
      next = r.secuenciaDesde;
    }
    if (next > r.secuenciaHasta) {
      throw StateError(
        'Secuencia e-NCF agotada para tipo ${tipo.codigo} '
        '(actual ${r.secuenciaActual}, hasta ${r.secuenciaHasta}).',
      );
    }
    await (_db.update(_db.ecfeSecuenciasTable)..where((t) => t.id.equals(r.id)))
        .write(EcfeSecuenciasTableCompanion(secuenciaActual: Value(next)));
    return (
      encf: 'E${tipo.codigo}${next.toString().padLeft(10, '0')}',
      vencimiento: r.fechaVencimiento,
    );
  }
}
