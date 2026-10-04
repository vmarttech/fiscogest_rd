import 'package:flutter/foundation.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/sync/supabase/negocio_local.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_rest_client.dart';

/// Sube pedidos de licencia locales → public.pedidos_licencia
class PedidoSync {
  PedidoSync(this._db);
  final AppDatabase _db;

  Future<void> pushTodos() async {
    if (!SupabaseConfig.isConfigured) {
      debugPrint('PedidoSync: Supabase no configurado');
      return;
    }

    final negocioId = await NegocioLocal.getId();
    final rows = await _db.select(_db.pedidosLicenciaTable).get();
    if (rows.isEmpty) {
      debugPrint('PedidoSync: no hay pedidos locales');
      return;
    }

    final payload = <Map<String, dynamic>>[];
    for (final p in rows) {
      DateTime? expira;
      if (p.fechaExpiracionPedido.isNotEmpty) {
        expira = DateTime.tryParse(p.fechaExpiracionPedido);
      }
      DateTime? creado;
      if (p.fechaCreacion.isNotEmpty) {
        creado = DateTime.tryParse(p.fechaCreacion);
      }

      payload.add({
        if (negocioId != null && negocioId.isNotEmpty) 'negocio_id': negocioId,
        'referencia': p.referencia,
        'plan': p.plan,
        'vigencia_tipo': p.vigenciaTipo,
        'monto': p.monto,
        'estado': p.estado,
        'created_at':
            (creado ?? DateTime.now()).toUtc().toIso8601String(),
        if (expira != null) 'expires_at': expira.toUtc().toIso8601String(),
      });
    }

    await SupabaseRestClient().upsert(
      table: 'pedidos_licencia',
      rows: payload,
      onConflict: 'referencia',
    );

    debugPrint('PedidoSync: OK → ${payload.length} pedido(s)');
  }
}
