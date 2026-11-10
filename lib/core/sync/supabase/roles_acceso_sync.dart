import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_rest_client.dart';
import 'package:fiscogest_rd/core/auth/permisos_roles.dart';

/// Descarga public.roles_acceso y la deja en memoria + SharedPreferences.
/// Offline: usa caché; si no hay caché, fallback a permisosPorRol del APK.
class RolesAccesoSync {
  static const _prefsKey = 'roles_acceso_catalog_v1';

  /// Caché en memoria (rol normalizado → permisos + ruta).
  static Map<String, Set<String>> permisosRuntime = {};
  static Map<String, String> rutasRuntime = {};
  static bool cargado = false;

  /// Arranque / post-login / resume.
  static Future<void> pullYCachear() async {
    if (!SupabaseConfig.isConfigured) {
      _cargarFallbackLocal();
      return;
    }
    try {
      final rows = await SupabaseRestClient().select(table: 'roles_acceso');
      if (rows.isEmpty) {
        debugPrint('RolesAccesoSync: tabla vacía → fallback APK');
        _cargarFallbackLocal();
        return;
      }
      final perm = <String, Set<String>>{};
      final rutas = <String, String>{};
      for (final r in rows) {
        final rol = normalizarRol((r['rol'] as String?) ?? '');
        if (rol.isEmpty) continue;
        final raw = r['permisos'];
        final set = <String>{};
        if (raw is List) {
          for (final e in raw) {
            set.add(e.toString());
          }
        } else if (raw is String) {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            for (final e in decoded) {
              set.add(e.toString());
            }
          }
        }
        perm[rol] = set;
        rutas[rol] = (r['ruta_inicio'] as String?) ?? '/';
      }
      permisosRuntime = perm;
      rutasRuntime = rutas;
      cargado = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode({
          'permisos': perm.map((k, v) => MapEntry(k, v.toList())),
          'rutas': rutas,
        }),
      );
      debugPrint('RolesAccesoSync: OK ${perm.length} roles desde Supabase');
    } catch (e) {
      debugPrint('RolesAccesoSync: error $e → caché/fallback');
      await cargarDesdePrefsOFallback();
    }
  }

  static Future<void> cargarDesdePrefsOFallback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final p = map['permisos'] as Map<String, dynamic>? ?? {};
        final r = map['rutas'] as Map<String, dynamic>? ?? {};
        permisosRuntime = p.map(
          (k, v) => MapEntry(k, Set<String>.from(v as List)),
        );
        rutasRuntime = r.map((k, v) => MapEntry(k, v.toString()));
        cargado = permisosRuntime.isNotEmpty;
        if (cargado) {
          debugPrint('RolesAccesoSync: caché local ${permisosRuntime.length} roles');
          return;
        }
      }
    } catch (_) {}
    _cargarFallbackLocal();
  }

  static void _cargarFallbackLocal() {
    permisosRuntime = {
      for (final e in permisosPorRol.entries) e.key: Set<String>.from(e.value),
    };
    rutasRuntime = Map<String, String>.from(rutaInicioPorRol);
    cargado = true;
    debugPrint('RolesAccesoSync: fallback APK');
  }
}
