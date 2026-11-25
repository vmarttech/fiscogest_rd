import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/sync/supabase/negocio_local.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_rest_client.dart';
import 'package:fiscogest_rd/features/licencias/domain/dispositivo_service.dart';

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

    final pendientes =
        await (_db.select(_db.dispositivosLicenciaTable)..where(
              (t) =>
                  t.fingerprint.equals(local.fingerprint) |
                  (t.activo.equals(false) & t.pendienteSync.equals(true)),
            ))
            .get();
    final rows = pendientes
        .map(
          (dispositivo) => <String, dynamic>{
            if (dispositivo.remoteId != null) 'id': dispositivo.remoteId,
            'negocio_id': negocioId,
            'fingerprint': dispositivo.fingerprint,
            'alias': dispositivo.alias,
            'plataforma': dispositivo.plataforma,
            'tipo': dispositivo.tipo,
            'activo': dispositivo.activo,
            'registrado_en':
                (DateTime.tryParse(dispositivo.registradoEn) ?? DateTime.now())
                    .toUtc()
                    .toIso8601String(),
            'ultimo_uso':
                (DateTime.tryParse(dispositivo.ultimoUso) ?? DateTime.now())
                    .toUtc()
                    .toIso8601String(),
          },
        )
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
