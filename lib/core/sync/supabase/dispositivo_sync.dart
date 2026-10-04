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

    final row = <String, dynamic>{
      if (local.remoteId != null) 'id': local.remoteId,
      'negocio_id': negocioId,
      'fingerprint': local.fingerprint,
      'alias': local.alias,
      'plataforma': local.plataforma,
      'tipo': local.tipo,
      'activo': local.activo,
      'registrado_en':
          (local.registradoEn ?? DateTime.now()).toUtc().toIso8601String(),
      'ultimo_uso':
          (local.ultimoUso ?? DateTime.now()).toUtc().toIso8601String(),
    };

    await SupabaseRestClient().upsert(
      table: 'dispositivos_licencia',
      rows: [row],
      onConflict: 'negocio_id,fingerprint',
    );

    await svc.marcarSincronizados();
    debugPrint('DispositivoSync: OK → dispositivos_licencia');
  }
}
