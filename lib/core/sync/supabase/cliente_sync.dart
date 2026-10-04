import 'package:flutter/foundation.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/sync/supabase/negocio_local.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_rest_client.dart';

class ClienteSync {
  ClienteSync(this._db);
  final AppDatabase _db;

  Future<void> pushTodos() async {
    if (!SupabaseConfig.isConfigured) return;

    final negocioId = await NegocioLocal.getId();
    if (negocioId == null || negocioId.isEmpty) {
      debugPrint('ClienteSync: sin negocio_id');
      return;
    }

    final rows = await _db.select(_db.clientesTable).get();
    if (rows.isEmpty) {
      debugPrint('ClienteSync: no hay clientes locales');
      return;
    }

    final payload = rows
        .map((c) => <String, dynamic>{
              'negocio_id': negocioId,
              'id_local': c.id,
              'codigo': c.codigo,
              'nombre': c.nombre,
              'telefono': c.telefono,
              'rnc_cedula': c.rncCedula,
              'activo': c.activo,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
        .toList();

    await SupabaseRestClient().upsert(
      table: 'clientes',
      rows: payload,
      onConflict: 'negocio_id,id_local',
    );
    debugPrint('ClienteSync: OK → ${payload.length} cliente(s)');
  }
}
