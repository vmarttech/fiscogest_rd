import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/licencias/domain/licencia_estado.dart';
import 'package:fiscogest_rd/features/licencias/domain/licencia_gates.dart';

class LimitePlanException implements Exception {
  LimitePlanException(this.mensaje);
  final String mensaje;
  @override
  String toString() => mensaje;
}

/// Lee la licencia activa desde BD y aplica topes de plan.
class LicenciaLimitesGuard {
  LicenciaLimitesGuard(this.db);
  final AppDatabase db;

  Future<LicenciaInfo?> _licenciaActual() async {
    final rows = await db.select(db.licenciasTable).get();
    if (rows.isEmpty) return null;
    rows.sort((a, b) => b.id.compareTo(a.id));
    final dev = rows.where((r) => r.plan == 'desarrollador' || r.vitalicia);
    final r = (dev.isNotEmpty ? dev : rows).first;
    return LicenciaInfo(
      id: r.id,
      plan: r.plan,
      vigenciaTipo: r.vigenciaTipo,
      fechaInicio: DateTime.tryParse(r.fechaInicio) ?? DateTime.now(),
      fechaFin: r.fechaFin != null ? DateTime.tryParse(r.fechaFin!) : null,
      maxDispositivos: r.maxDispositivos,
      maxCajas: r.maxCajas,
      ecfHabilitado: r.ecfHabilitado,
      vitalicia: r.vitalicia,
      estado: r.estado,
      fingerprint: r.fingerprint,
      codigoActivacion: r.codigoActivacion,
    );
  }

  Future<LicenciaGates> _gates() async => LicenciaGates(await _licenciaActual());

  Future<void> assertPuedeCrearProducto() async {
    final g = await _gates();
    final max = g.maxProductos;
    if (max == null) return;
    final n = (await db.select(db.productosTable).get()).length;
    if (n >= max) {
      throw LimitePlanException(g.mensajeTope('productos (máx. $max)'));
    }
  }

  Future<void> assertPuedeCrearCliente() async {
    final g = await _gates();
    final max = g.maxClientes;
    if (max == null) return;
    final n = (await db.select(db.clientesTable).get()).length;
    if (n >= max) {
      throw LimitePlanException(g.mensajeTope('clientes (máx. $max)'));
    }
  }

  /// Solo ventas del mes calendario actual (por columna [fecha]).
  /// No aplica a borradores/cotizaciones si [soloConfirmadas] y el estado no es venta.
  Future<void> assertPuedeRegistrarVenta({bool contarBorradores = false}) async {
    final g = await _gates();
    final max = g.maxVentasMes;
    if (max == null) return;

    final ahora = DateTime.now();
    final inicio = DateTime(ahora.year, ahora.month, 1);
    final finMes = DateTime(ahora.year, ahora.month + 1, 1);

    final q = db.select(db.ventasTable)
      ..where((t) => t.fecha.isBiggerOrEqualValue(inicio))
      ..where((t) => t.fecha.isSmallerThanValue(finMes));

    final rows = await q.get();
    int count = rows.length;
    if (!contarBorradores) {
      count = rows
          .where((v) {
            final e = v.estadoDocumento.toLowerCase();
            // Cotización / borrador no consumen cupo de "venta del mes"
            return e != 'borrador' &&
                e != 'cotizacion' &&
                e != 'cotización' &&
                e != 'draft';
          })
          .length;
    }
    if (count >= max) {
      throw LimitePlanException(g.mensajeTope('ventas del mes (máx. $max)'));
    }
  }
}
