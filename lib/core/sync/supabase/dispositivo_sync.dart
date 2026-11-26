import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/sync/supabase/negocio_local.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_rest_client.dart';
import 'package:fiscogest_rd/features/licencias/domain/device_fingerprint.dart';
import 'package:fiscogest_rd/features/licencias/domain/dispositivo_service.dart';
import 'package:fiscogest_rd/features/licencias/domain/validacion_dispositivo.dart';
import 'package:fiscogest_rd/features/licencias/domain/validador_dispositivo_remoto_supabase.dart';

class DispositivoSync {
  DispositivoSync(this._db);

  final AppDatabase _db;

  Future<void> pushEsteEquipo() async {
    if (!SupabaseConfig.isConfigured) {
      debugPrint('DispositivoSync: Supabase no configurado');
      return;
    }

    final svc = DispositivoService(_db);
    final local = await svc.ensureDispositivoRegistrado();
    final negocioId = await NegocioLocal.getId();
    if (negocioId == null || negocioId.isEmpty) {
      debugPrint('DispositivoSync: sin negocio_id');
      return;
    }

    // F7: el alta del equipo la concede la RPC app_registrar_dispositivo.
    // El servidor aplica el cupo del plan y la vinculación (negocio_id,
    // fingerprint); el cliente no decide permisos ni fechas.
    final identity = await DeviceFingerprint.obtenerResultado();
    final validador = ValidadorDispositivoRemotoSupabase();

    final validacion = await validador.validar(
      SolicitudValidacionDispositivo(identidad: identity),
    );
    debugPrint('DispositivoSync: validación = ${validacion.estado.name}'
        ' ${validacion.errorCodigo ?? ''}');

    final registro = await validador.registrarEquipo(identidad: identity);
    final registradoEnNube =
        registro.estado == EstadoValidacionDispositivo.registrado;

    const codigosBloqueantes = {
      'limite_dispositivos',
      'vinculado_otro_negocio',
      'dispositivo_no_registrado',
      'suspendido',
};
final bloqueado =
    validacion.estado == EstadoValidacionDispositivo.negocioExistente ||
    validacion.estado == EstadoValidacionDispositivo.rechazado ||
    registro.estado == EstadoValidacionDispositivo.rechazado ||
    codigosBloqueantes.contains(validacion.errorCodigo) ||
    codigosBloqueantes.contains(registro.errorCodigo);
    if (bloqueado) {
      final motivo = registro.mensajeUsuario ??
          validacion.mensajeUsuario ??
          'registro rechazado por el servidor';
      debugPrint('DispositivoSync: $motivo; se mantiene pendiente de sync.');
      return; // no se hace upsert; la fila local conserva pendienteSync = true
    }

    final pendientes = await (_db.select(_db.dispositivosLicenciaTable)
          ..where((t) =>
              t.fingerprint.equals(local.fingerprint) |
              (t.activo.equals(false) & t.pendienteSync.equals(true))))
        .get();

    final idsOmitibles = <String>{
      if (registradoEnNube) local.fingerprint,
    };

    final rows = pendientes
        .map((dispositivo) => <String, dynamic>{
              if (dispositivo.remoteId != null &&
                  !idsOmitibles.contains(dispositivo.fingerprint))
                'id': dispositivo.remoteId,
              'negocio_id': negocioId,
              'fingerprint': dispositivo.fingerprint,
              'alias': dispositivo.alias,
              'plataforma': dispositivo.plataforma,
              'tipo': dispositivo.tipo,
              'activo': dispositivo.activo,
              'registrado_en':
                  (DateTime.tryParse(dispositivo.registradoEn) ??
                          DateTime.now())
                      .toUtc()
                      .toIso8601String(),
              'ultimo_uso':
                  (DateTime.tryParse(dispositivo.ultimoUso) ?? DateTime.now())
                      .toUtc()
                      .toIso8601String(),
            })
        .toList();

    await SupabaseRestClient().upsert(
      table: 'dispositivos_licencia',
      rows: rows,
      onConflict: 'negocio_id,fingerprint',
    );

    await svc.marcarSincronizados();
    debugPrint('DispositivoSync: OK → dispositivos_licencia');
  }
}
