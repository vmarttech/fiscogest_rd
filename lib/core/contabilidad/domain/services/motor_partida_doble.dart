import 'package:fiscogest_rd/core/contabilidad/domain/entities/asiento_contable.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/linea_asiento.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/enums/estado_asiento.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/repositories/i_asiento_repository.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/services/validador_asientos.dart';

/// Motor de registro de asientos en partida doble.
class MotorPartidaDoble {
  MotorPartidaDoble(this._repo, {this.verificarLicencia});

  final IAsientoRepository _repo;

  // Seam de integracion con licencias: si se provee y devuelve false,
  // el registro de asientos se bloquea mientras la licencia no este vigente.
  final Future<bool> Function()? verificarLicencia;

  Future<AsientoContable> registrar({
    required AsientoContable asiento,
    required List<LineaAsiento> lineas,
  }) async {
    // Validar reglas de negocio
    final errores = ValidadorAsientos().validar(asiento, lineas);
    if (errores.isNotEmpty) {
      // Codigo de dominio con detalle: cada item ya es un acct_error_* (sufijo opcional tras ':').
      throw Exception('acct_error_validation_failed:${errores.join('|')}');
    }

    // Integracion con licencias: no registrar si la licencia esta vencida o inactiva.
    // Falla cerrada: si la verificacion lanza error (red, servicio), se bloquea el registro.
    if (verificarLicencia != null) {
      bool licenciaVigente;
      try {
        licenciaVigente = await verificarLicencia!();
      } catch (_) {
        licenciaVigente = false;
      }
      if (!licenciaVigente) {
        throw StateError('acct_error_license_inactive');
      }
    }

    // No re-registrar un asiento ya contabilizado ni uno anulado previamente
    if (asiento.estado == EstadoAsiento.contabilizado) {
      throw ArgumentError('acct_error_already_posted');
    }
    if (asiento.estado == EstadoAsiento.anulado) {
      throw ArgumentError('acct_error_already_voided');
    }

    // Normalizar y generar número secuencial si no tiene
    var numero = asiento.numeroAsiento.trim();
    if (numero.isEmpty) {
      numero = (await _repo.obtenerSiguienteNumero()).trim();
    }
    if (numero.isEmpty) {
      throw StateError('acct_error_sequence_failed');
    }

    // Cambiar estado a contabilizado
    final finalizado = asiento.copyWith(
      numeroAsiento: numero,
      estado: EstadoAsiento.contabilizado,
    );

    // Persistir transaccionalmente
    return _repo.registrar(finalizado, lineas);
  }

  Future<AsientoContable?> consultar(int asientoId) async {
    return _repo.obtenerPorId(asientoId);
  }

  Future<List<LineaAsiento>> obtenerLineas(int asientoId) async {
    return _repo.obtenerLineas(asientoId);
  }

  Future<bool> anular(int asientoId, String motivo) async {
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
      throw StateError('acct_error_void_requires_posted:${existente.estado.name}');
    }

    return _repo.anular(asientoId, motivoLimpio);
  }
}
