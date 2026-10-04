import 'package:flutter/foundation.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/sync/supabase/negocio_local.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_rest_client.dart';

class ProductoSync {
  ProductoSync(this._db);
  final AppDatabase _db;

  Future<void> pushTodos() async {
    if (!SupabaseConfig.isConfigured) return;

    final negocioId = await NegocioLocal.getId();
    if (negocioId == null || negocioId.isEmpty) {
      debugPrint('ProductoSync: sin negocio_id');
      return;
    }

    final rows = await _db.select(_db.productosTable).get();
    if (rows.isEmpty) {
      debugPrint('ProductoSync: no hay productos locales');
      return;
    }

    final payload = rows
        .map((p) => <String, dynamic>{
              'negocio_id': negocioId,
              'id_local': p.id,
              'codigo': p.codigo,
              'nombre': p.nombre,
              'precio_venta': p.precioVenta ?? 0,
              'precio_compra': p.precioCompra ?? 0,
              'stock': p.stock ?? 0,
              'activo': (p.activo) == 1,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
        .toList();

    await SupabaseRestClient().upsert(
      table: 'productos',
      rows: payload,
      onConflict: 'negocio_id,id_local',
    );
    debugPrint('ProductoSync: OK → ${payload.length} producto(s)');
  }
}
