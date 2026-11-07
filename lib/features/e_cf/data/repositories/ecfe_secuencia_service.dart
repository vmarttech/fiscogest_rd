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

  /// H-21: No crear secuencias predeterminadas.
  ///
  /// Los rangos e-NCF deben provenir de una autorización real de la DGII
  /// y cargarse explícitamente en Configuración → Secuencias e-NCF.
  /// Inventar rangos (p. ej. 1–100 activos) confunde configuración fiscal
  /// y puede permitir emisión con números no asignados.
  ///
  /// Conservado como no-op por compatibilidad con llamadas existentes.
  Future<void> asegurarTiposBase() async {
    // Intencionalmente vacío (H-21).
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
    // Ajuste comercial: solo puede existir UNA secuencia activa por tipo e-CF.
    // Si se activa esta, se desactivan las demás del mismo tipo.
    await _db.transaction(() async {
      if (activo) {
        await (_db.update(_db.ecfeSecuenciasTable)
              ..where((t) =>
                  t.tipoEcf.equals(tipoEcf) &
                  t.activo.equals(true) &
                  (id != null ? t.id.isNotValue(id) : const Constant(true))))
            .write(const EcfeSecuenciasTableCompanion(activo: Value(false)));
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
    });
  }

  /// Reserva el siguiente e-NCF de forma **atómica**.
  /// Usa transacción + actualización condicional para evitar duplicados
  /// bajo concurrencia (dos llamadas simultáneas no pueden obtener el mismo número).
  Future<({String encf, DateTime? vencimiento})> siguiente(TipoEcf tipo) async {
    const maxIntentos = 5;

    for (var intento = 1; intento <= maxIntentos; intento++) {
      try {
        return await _db.transaction(() async {
          final rows = await (_db.select(_db.ecfeSecuenciasTable)
                ..where((t) =>
                    t.tipoEcf.equals(tipo.codigo) & t.activo.equals(true))
                ..orderBy([(t) => OrderingTerm.asc(t.id)])
                ..limit(1))
              .get();

          if (rows.isEmpty) {
            throw StateError(
              'No hay secuencia activa para e-CF tipo ${tipo.codigo} (E${tipo.codigo}). '
              'Configúrala en e-CF → Configuración → Secuencias e-NCF.',
            );
          }

          final r = rows.first;

          // Validación de vencimiento
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

          // Actualización CONDICIONAL: solo si el valor leído sigue siendo el mismo.
          // Si otra transacción ya lo cambió → 0 filas afectadas → reintento.
          final actualizadas = await (_db.update(_db.ecfeSecuenciasTable)
                ..where((t) =>
                    t.id.equals(r.id) &
                    t.secuenciaActual.equals(r.secuenciaActual)))
              .write(
            EcfeSecuenciasTableCompanion(
              secuenciaActual: Value(next),
            ),
          );

          if (actualizadas == 0) {
            // Condición de carrera detectada → forzar reintento
            throw StateError('conflicto_secuencia');
          }

          return (
            encf: 'E${tipo.codigo}${next.toString().padLeft(10, '0')}',
            vencimiento: r.fechaVencimiento,
          );
        });
      } on StateError catch (e) {
        if (e.message == 'conflicto_secuencia' && intento < maxIntentos) {
          // Pequeña espera aleatoria para reducir contención
          await Future<void>.delayed(Duration(milliseconds: 15 * intento));
          continue;
        }
        rethrow;
      }
    }

    throw StateError(
      'No se pudo reservar e-NCF tipo ${tipo.codigo} después de $maxIntentos intentos '
      '(alta contención). Reintente la emisión.',
    );
  }
}
