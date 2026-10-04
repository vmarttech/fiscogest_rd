import 'package:flutter/foundation.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/sync/supabase/negocio_local.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_rest_client.dart';

/// Sube usuarios locales a public.usuarios (sin password ni hashes).
class UsuarioSync {
  UsuarioSync(this._db);
  final AppDatabase _db;

  Future<void> pushTodos() async {
    if (!SupabaseConfig.isConfigured) {
      debugPrint('UsuarioSync: Supabase no configurado');
      return;
    }

    final negocioId = await NegocioLocal.getId();
    if (negocioId == null || negocioId.isEmpty) {
      debugPrint('UsuarioSync: sin negocio_id');
      return;
    }

    final rows = await _db.select(_db.usuariosTable).get();
    if (rows.isEmpty) {
      debugPrint('UsuarioSync: no hay usuarios locales');
      return;
    }

    final payload = <Map<String, dynamic>>[];
    for (final u in rows) {
      final nombreCompleto = [
        u.nombre.trim(),
        if (u.apellido != null && u.apellido!.trim().isNotEmpty)
          u.apellido!.trim(),
      ].join(' ').trim();

      payload.add({
        'negocio_id': negocioId,
        'id_local': u.id,
        'username': u.username,
        'nombre': nombreCompleto.isEmpty ? u.username : nombreCompleto,
        'rol': u.rol,
        'activo': u.estado.toLowerCase() == 'activo',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    }

    await SupabaseRestClient().upsert(
      table: 'usuarios',
      rows: payload,
      onConflict: 'negocio_id,username',
    );

    debugPrint('UsuarioSync: OK → ${payload.length} usuario(s)');
  }
}
