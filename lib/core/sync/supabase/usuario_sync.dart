import 'package:flutter/foundation.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/sync/supabase/negocio_local.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_rest_client.dart';

/// Sube usuarios locales a public.usuarios (incluye password_hash si existe).
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

    final conHash = <Map<String, dynamic>>[];
    final sinHash = <Map<String, dynamic>>[];
    for (final u in rows) {
      final nombreCompleto = [
        u.nombre.trim(),
        if (u.apellido != null && u.apellido!.trim().isNotEmpty)
          u.apellido!.trim(),
      ].join(' ').trim();
      final base = <String, dynamic>{
        'negocio_id': negocioId,
        'id_local': u.id,
        'username': u.username,
        'nombre': nombreCompleto.isEmpty ? u.username : nombreCompleto,
        'rol': u.rol,
        'activo': u.estado.toLowerCase() == 'activo',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      final hash = u.passwordHash.trim();
      if (hash.isNotEmpty) {
        conHash.add({...base, 'password_hash': hash});
        debugPrint('UsuarioSync push ${u.username} hashLen=${hash.length}');
      } else {
        sinHash.add(base);
        debugPrint('UsuarioSync push ${u.username} hashLen=0 (sin columna)');
      }
    }

    final client = SupabaseRestClient();
    if (conHash.isNotEmpty) {
      await client.upsert(
        table: 'usuarios',
        rows: conHash,
        onConflict: 'negocio_id,username',
      );
    }
    if (sinHash.isNotEmpty) {
      await client.upsert(
        table: 'usuarios',
        rows: sinHash,
        onConflict: 'negocio_id,username',
      );
    }
    debugPrint(
      'UsuarioSync: OK → ${conHash.length} con hash, ${sinHash.length} sin hash',
    );
  }
}
