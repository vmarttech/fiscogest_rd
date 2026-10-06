import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/auth/dueno_plataforma.dart';
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_rest_client.dart';

/// Pedidos pendientes de plataforma (solo dueño). 0 para el resto.
final pedidosPendientesCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final sesion = ref.watch(sesionProvider);
  if (!esDuenoPlataforma(sesion?.username)) return 0;

  if (SupabaseConfig.isConfigured) {
    try {
      final a = await SupabaseRestClient().select(
        table: 'pedidos_licencia',
        filters: {'estado': 'eq.pendiente_pago', 'select': 'id'},
      );
      final b = await SupabaseRestClient().select(
        table: 'pedidos_licencia',
        filters: {'estado': 'eq.pago_reportado', 'select': 'id'},
      );
      return a.length + b.length;
    } catch (_) {}
  }

  final db = ref.watch(databaseProvider);
  final rows = await db.select(db.pedidosLicenciaTable).get();
  return rows
      .where(
        (p) =>
            p.estado == 'pendiente_pago' || p.estado == 'pago_reportado',
      )
      .length;
});
