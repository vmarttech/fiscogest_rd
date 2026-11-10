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
      } else {
        sinHash.add(base);
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


  /// Sube un solo usuario (p. ej. tras activar/desactivar).
  Future<void> pushUsuario(UsuarioData u) async {
    if (!SupabaseConfig.isConfigured) return;
    final negocioId = await NegocioLocal.getId();
    if (negocioId == null || negocioId.isEmpty) return;

    final body = <String, dynamic>{
      'negocio_id': negocioId,
      'username': u.username,
      'nombre': u.nombre,
      if (u.apellido != null && u.apellido!.isNotEmpty) 'apellido': u.apellido,
      'rol': u.rol,
      'activo': u.estado.toLowerCase() == 'activo',
      if (u.passwordHash.isNotEmpty) 'password_hash': u.passwordHash,
    };
    final client = SupabaseRestClient();
    await client.upsert(
      table: 'usuarios',
      rows: [body],
      onConflict: 'negocio_id,username',
    );
    debugPrint('UsuarioSync: pushUsuario ${u.username} activo=${body['activo']}');
  }

  /// Autoridad en nube: ¿este username está activo en el negocio actual?
  /// null = no se pudo consultar (sin red / sin config) → el caller decide política.
  static Future<bool?> verificarActivoEnNube(String username) async {
    if (!SupabaseConfig.isConfigured) return null;
    final negocioId = await NegocioLocal.getId();
    if (negocioId == null || negocioId.isEmpty) return null;
    try {
      final client = SupabaseRestClient();
      final rows = await client.select(
        table: 'usuarios',
        filters: {
          'negocio_id': 'eq.$negocioId',
          'username': 'eq.${username.trim()}',
        },
      );
      if (rows.isEmpty) return null;
      return rows.first['activo'] == true;
    } catch (e) {
      debugPrint('UsuarioSync: verificarActivoEnNube $e');
      return null;
    }
  }
}

