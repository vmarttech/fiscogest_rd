import 'package:fiscogest_rd/core/contabilidad/domain/config/contabilidad_pais_config.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/asiento_contable.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/linea_asiento.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/plan_cuenta.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/enums/estado_asiento.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/repositories/i_asiento_repository.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/repositories/i_periodo_fiscal_repository.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/repositories/i_plan_cuentas_repository.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/services/validador_asientos.dart';

/// Motor de partida doble. Anulación = asiento de reversa.
/// Licencia fail-closed: sin callback o false → no escribe.
class MotorPartidaDoble {
  MotorPartidaDoble(
    this._repo, {
    IPlanCuentasRepository? planCuentas,
    IPeriodoFiscalRepository? periodos,
    this.verificarLicencia,
  })  : _planCuentas = planCuentas,
        _periodos = periodos;

  final IAsientoRepository _repo;
  final IPlanCuentasRepository? _planCuentas;
  final IPeriodoFiscalRepository? _periodos;

  /// Si es null o devuelve false, no se permiten altas/anulaciones.
  final Future<bool> Function()? verificarLicencia;

  /// Fail-closed: sin callback o false → no se escriben asientos.
  Future<void> _assertLicencia() async {
    final fn = verificarLicencia;
    if (fn == null) {
      throw StateError('acct_error_license_inactive');
    }
    final ok = await fn();
    if (!ok) {
      throw StateError('acct_error_license_inactive');
    }
  }

  Future<Map<int, PlanCuenta>?> _cargarCuentas(List<LineaAsiento> lineas) async {
    final plan = _planCuentas;
    if (plan == null) return null;
    final mapa = <int, PlanCuenta>{};
    for (final l in lineas) {
      if (mapa.containsKey(l.cuentaId)) continue;
      final c = await plan.obtenerPorId(l.cuentaId);
      if (c != null) mapa[c.id] = c;
    }
    return mapa;
  }

  Future<void> _assertPeriodoAbierto(DateTime fecha) async {
    final periodos = _periodos;
    if (periodos == null) return;
    final p = await periodos.periodoAbiertoQueContiene(
      fecha,
      paisCodigo: ContabilidadPaisConfig.paisCodigo,
    );
    if (p == null) {
      throw StateError(
        'acct_error_period_closed_or_missing:${ContabilidadPaisConfig.paisCodigo}',
      );
    }
  }

  Future<AsientoContable> registrar({
    required AsientoContable asiento,
    required List<LineaAsiento> lineas,
  }) async {
    await _assertLicencia();

    final cuentas = await _cargarCuentas(lineas);
    final errores =
        ValidadorAsientos().validar(asiento, lineas, cuentasPorId: cuentas);
    if (errores.isNotEmpty) {
      throw Exception('acct_error_validation_failed:${errores.join('|')}');
    }

    await _assertPeriodoAbierto(asiento.fecha);

    if (asiento.estado == EstadoAsiento.contabilizado) {
      throw ArgumentError('acct_error_already_posted');
    }
    if (asiento.estado == EstadoAsiento.anulado) {
      throw ArgumentError('acct_error_already_voided');
    }

    var numero = asiento.numeroAsiento.trim();
    if (numero.isEmpty) {
      numero = (await _repo.obtenerSiguienteNumero()).trim();
    }
    if (numero.isEmpty) {
      throw StateError('acct_error_sequence_failed');
    }

    final finalizado = asiento.copyWith(
      numeroAsiento: numero,
      estado: EstadoAsiento.contabilizado,
    );
    return _repo.registrar(finalizado, lineas);
  }

  Future<AsientoContable?> consultar(int asientoId) =>
      _repo.obtenerPorId(asientoId);

  Future<List<LineaAsiento>> obtenerLineas(int asientoId) =>
      _repo.obtenerLineas(asientoId);

  Future<AsientoContable> anular(int asientoId, String motivo) async {
    await _assertLicencia();

    final motivoLimpio = motivo.trim();
    if (motivoLimpio.isEmpty) {
      throw ArgumentError('acct_error_void_reason_required');
    }

    final existente = await _repo.obtenerPorId(asientoId);
    if (existente == null) {
      throw ArgumentError('acct_error_entry_not_found:$asientoId');
    }
    if (existente.estado == EstadoAsiento.anulado) {
      throw StateError('acct_error_already_voided:$asientoId');
    }
    if (existente.estado != EstadoAsiento.contabilizado) {
      throw StateError(
        'acct_error_void_requires_posted:${existente.estado.name}',
      );
    }

    final lineasOrig = await _repo.obtenerLineas(asientoId);
    if (lineasOrig.length < 2) {
      throw StateError('acct_error_void_no_lines:$asientoId');
    }

    final lineasReversa = lineasOrig
        .map(
          (l) => LineaAsiento(
            cuentaId: l.cuentaId,
            debeCents: l.haberCents,
            haberCents: l.debeCents,
            concepto: (l.concepto == null || l.concepto!.isEmpty)
                ? 'Reversa'
                : 'Reversa: ${l.concepto}',
          ),
        )
        .toList();

    final ahora = DateTime.now();
    final reversa = await registrar(
      asiento: AsientoContable(
        numeroAsiento: '',
        fecha: ahora,
        concepto: 'REVERSA AS ${existente.numeroAsiento}: $motivoLimpio',
        estado: EstadoAsiento.borrador,
        documentoOrigen: existente.numeroAsiento,
        tipoOrigen: 'reversa',
        referenciaId: existente.id,
        creadoEn: ahora,
      ),
      lineas: lineasReversa,
    );

    final ok = await _repo.anular(asientoId, motivoLimpio);
    if (!ok) {
      throw StateError('acct_error_void_mark_failed:$asientoId');
    }
    return reversa;
  }
}
