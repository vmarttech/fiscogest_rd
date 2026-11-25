import 'dart:async';

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

class LicenciaValidacionPendienteException implements Exception {
  const LicenciaValidacionPendienteException();
  @override
  String toString() =>
      'La licencia de este dispositivo aún debe validarse para permitir registros.';
}

class LicenciaUsoSignals {
  LicenciaUsoSignals._();
  static final StreamController<void> _controller =
      StreamController<void>.broadcast();
  static Stream<void> get cambios => _controller.stream;
  static void notificarCambio() => _controller.add(null);
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

  Future<LicenciaGates> _gates() async =>
      LicenciaGates(await _licenciaActual());

  Future<void> _exigirLicenciaValidada() async {
    final licencia = await _licenciaActual();
    if (licencia == null || !licencia.puedeEscribir) {
      throw const LicenciaValidacionPendienteException();
    }
  }

  String _periodoActual() {
    final ahora = DateTime.now();
    return '${ahora.year.toString().padLeft(4, '0')}-'
        '${ahora.month.toString().padLeft(2, '0')}';
  }

  Future<int> _usoMensual(String recurso) async {
    final rows = await db
        .customSelect(
          'SELECT cantidad FROM licencia_consumos_mensuales '
          'WHERE recurso = ? AND periodo = ?',
          variables: [
            Variable.withString(recurso),
            Variable.withString(_periodoActual()),
          ],
        )
        .get();
    return rows.isEmpty ? 0 : rows.first.read<int>('cantidad');
  }

  Future<void> _registrarUso(String recurso, int? max) async {
    await _exigirLicenciaValidada();
    if (max == null) return;
    final uso = await _usoMensual(recurso);
    if (uso >= max) {
      throw LimitePlanException(
        'Límite del plan Gratis: $uso/$max $recurso utilizados este mes.',
      );
    }
    await db.customStatement(
      'INSERT INTO licencia_consumos_mensuales (recurso, periodo, cantidad) '
      'VALUES (?, ?, 1) ON CONFLICT(recurso, periodo) '
      'DO UPDATE SET cantidad = cantidad + 1',
      [recurso, _periodoActual()],
    );
    LicenciaUsoSignals.notificarCambio();
  }

  Future<void> registrarProductoNuevo() async {
    final g = await _gates();
    if (g.esGratis) {
      await _registrarUso('productos', g.maxProductos);
    } else {
      await _exigirLicenciaValidada();
    }
  }

  Future<void> registrarClienteNuevo() async {
    final g = await _gates();
    if (g.esGratis) {
      await _registrarUso('clientes', g.maxClientes);
    } else {
      await _exigirLicenciaValidada();
    }
  }

  /// Solo ventas del mes calendario actual (por columna [fecha]).
  /// No aplica a borradores/cotizaciones si [soloConfirmadas] y el estado no es venta.
  Future<void> assertPuedeRegistrarVenta({
    bool contarBorradores = false,
    int? excluirVentaId,
  }) async {
    final g = await _gates();
    await _exigirLicenciaValidada();
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
      count = rows.where((v) {
        if (v.id == excluirVentaId) return false;
        final e = v.estadoDocumento.toLowerCase();
        // Cotización / borrador no consumen cupo de "venta del mes"
        return e != 'borrador' &&
            e != 'cotizacion' &&
            e != 'cotización' &&
            e != 'draft';
      }).length;
    }
    if (count >= max) {
      throw LimitePlanException(
        g.mensajeTope('ventas del mes: $count/$max utilizadas'),
      );
    }
  }

  Future<Map<String, int>> resumenUsoGratis() async => {
    'ventas': await _usoVentasMes(),
    'productos': await _usoMensual('productos'),
    'clientes': await _usoMensual('clientes'),
  };

  Future<int> _usoVentasMes() async {
    final ahora = DateTime.now();
    final inicio = DateTime(ahora.year, ahora.month, 1);
    final finMes = DateTime(ahora.year, ahora.month + 1, 1);
    final rows =
        await (db.select(db.ventasTable)
              ..where((t) => t.fecha.isBiggerOrEqualValue(inicio))
              ..where((t) => t.fecha.isSmallerThanValue(finMes)))
            .get();
    return rows.where((v) {
      final estado = v.estadoDocumento.toLowerCase();
      return estado != 'borrador' &&
          estado != 'cotizacion' &&
          estado != 'cotización' &&
          estado != 'draft';
    }).length;
  }
}
