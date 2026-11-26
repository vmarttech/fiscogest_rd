import 'dart:convert';

import 'package:fiscogest_rd/core/sync/supabase/supabase_rest_client.dart';
import 'package:fiscogest_rd/features/licencias/domain/device_fingerprint.dart';
import 'package:fiscogest_rd/features/licencias/domain/validacion_dispositivo.dart';

/// Implementación remota de [ValidadorDispositivoRemoto] contra las RPC
/// app_* de Supabase. El servidor decide estados y fechas; esta clase solo
/// traduce el contrato JSON al dominio de la app.
class ValidadorDispositivoRemotoSupabase implements ValidadorDispositivoRemoto {
  ValidadorDispositivoRemotoSupabase({SupabaseRestClient? client})
      : _client = client ?? SupabaseRestClient();

  final SupabaseRestClient _client;

  /// Valida el equipo actual contra la nube. Sin sesión o sin conexión
  /// devuelve [EstadoValidacionDispositivo.pendiente]; nunca bloquea la app.
  @override
  Future<ResultadoValidacionDispositivo> validar(
    SolicitudValidacionDispositivo solicitud,
  ) async {
    final raw = await _client.rpc('app_validar_dispositivo', {
      'p_fingerprint': solicitud.identidad.fingerprint,
      'p_plataforma': DeviceFingerprint.plataformaActual(),
      'p_alias': DeviceFingerprint.aliasSugerido(),
    });

    if (raw == null) {
      return const ResultadoValidacionDispositivo(
        estado: EstadoValidacionDispositivo.pendiente,
        mensajeUsuario: 'Sin conexión: se mantiene la validación local.',
      );
    }

    final map = _asMap(raw);
    if (map['ok'] != true) {
      return ResultadoValidacionDispositivo(
        estado: EstadoValidacionDispositivo.rechazado,
        mensajeUsuario: _mensaje(map['error']?.toString()),
      errorCodigo: map['error']?.toString(),
      );
    }
    return _mapear(map);
  }

  /// Da de alta el equipo en la nube por la RPC de registro.
  Future<ResultadoValidacionDispositivo> registrarEquipo({
    required DeviceIdentity identidad,
  }) async {
    final raw = await _client.rpc('app_registrar_dispositivo', {
      'p_fingerprint': identidad.fingerprint,
      'p_plataforma': DeviceFingerprint.plataformaActual(),
      'p_alias': DeviceFingerprint.aliasSugerido(),
    });
    if (raw == null) {
      return const ResultadoValidacionDispositivo(
        estado: EstadoValidacionDispositivo.pendiente,
        mensajeUsuario: 'Registro del equipo pendiente de conexión.',
      );
    }
    final map = _asMap(raw);
    if (map['ok'] != true) {
      return ResultadoValidacionDispositivo(
        estado: EstadoValidacionDispositivo.rechazado,
        mensajeUsuario: _mensaje(map['error']?.toString()),
      errorCodigo: map['error']?.toString(),
      );
    }
    return const ResultadoValidacionDispositivo(
      estado: EstadoValidacionDispositivo.registrado,
    );
  }

  /// Inicia la prueba de 30 días; el servidor fija fechas y gracia de 3 días.
  Future<Map<String, dynamic>?> iniciarPrueba(String fingerprint) async {
    final raw = await _client.rpc('app_iniciar_prueba', {
      'p_fingerprint': fingerprint,
    });
    final map = _asMap(raw);
    return map['ok'] == true ? map : null;
  }

  /// Contrato completo de licencia para mostrar en la UI.
  Future<Map<String, dynamic>?> consultarLicencia(String? fingerprint) async {
    final raw = await _client.rpc('app_consultar_licencia', {
      if (fingerprint != null && fingerprint.isNotEmpty)
        'p_fingerprint': fingerprint,
    });
    final map = _asMap(raw);
    return map.isEmpty ? null : map;
  }

  ResultadoValidacionDispositivo _mapear(Map<String, dynamic> map) {
    final device = map['device_status']?.toString();
    final license = map['license_status']?.toString();

    switch (device) {
      case 'otro_negocio':
        return const ResultadoValidacionDispositivo(
          estado: EstadoValidacionDispositivo.negocioExistente,
          mensajeUsuario: 'Este equipo ya está vinculado a otro negocio.',
        );
      case 'prueba_usada':
        return const ResultadoValidacionDispositivo(
          estado: EstadoValidacionDispositivo.pruebaUtilizada,
          mensajeUsuario: 'La prueba gratuita ya fue usada en este equipo.',
        );
    }

    switch (license) {
      case 'prueba_activa':
      case 'concesion_activa':
      case 'activa':
      case 'vitalicia':
        return const ResultadoValidacionDispositivo(
          estado: EstadoValidacionDispositivo.autorizado,
        );
      case 'gracia':
        return const ResultadoValidacionDispositivo(
          estado: EstadoValidacionDispositivo.concesionPromocional,
          mensajeUsuario: 'Período de gracia activo.',
        );
      case 'prueba_vencida':
      case 'vencida':
        return const ResultadoValidacionDispositivo(
          estado: EstadoValidacionDispositivo.rechazado,
          mensajeUsuario: 'La licencia está vencida.',
        );
      case 'suspendida':
        return const ResultadoValidacionDispositivo(
          estado: EstadoValidacionDispositivo.rechazado,
          mensajeUsuario: 'El negocio está suspendido.',
        );
      default:
        return const ResultadoValidacionDispositivo(
          estado: EstadoValidacionDispositivo.pendiente,
          mensajeUsuario: 'Sin sesión o sin licencia activa.',
        );
    }
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return const <String, dynamic>{};
  }

  String _mensaje(String? error) {
    switch (error) {
      case 'sin_sesion':
        return 'Inicia sesión para continuar.';
      case 'limite_dispositivos':
        return 'Se alcanzó el límite de equipos del plan.';
      case 'vinculado_otro_negocio':
        return 'Este equipo ya pertenece a otro negocio.';
      case 'prueba_utilizada':
        return 'La prueba gratuita ya fue utilizada.';
      case 'prueba_no_aplica':
        return 'Este negocio no aplica para la prueba gratuita.';
      case 'suspendido':
        return 'El negocio está suspendido.';
      case 'dispositivo_no_registrado':
        return 'El equipo no está registrado en este negocio.';
      default:
        return 'No fue posible validar el equipo.';
    }
  }
}
