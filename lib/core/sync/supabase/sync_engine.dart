import 'package:fiscogest_rd/core/sync/supabase/renovar_token.dart';
import 'package:flutter/foundation.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/sync/supabase/cliente_sync.dart';
import 'package:fiscogest_rd/core/sync/supabase/dispositivo_sync.dart';
import 'package:fiscogest_rd/core/sync/supabase/pedido_sync.dart';
import 'package:fiscogest_rd/core/sync/supabase/producto_sync.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';
import 'package:fiscogest_rd/core/sync/supabase/sync_pull.dart';
import 'package:fiscogest_rd/core/sync/supabase/usuario_sync.dart';
import 'package:fiscogest_rd/core/sync/supabase/venta_sync.dart';
import 'package:fiscogest_rd/core/sync/supabase/caja_sync.dart';
import 'package:fiscogest_rd/core/sync/supabase/fio_sync.dart';

/// Único punto de entrada para sync del negocio + plataforma.
///
/// Día a día: usuarios, productos, clientes, (ventas… se irán sumando).
/// Plataforma: pedidos_licencia, dispositivos_licencia.
class SyncEngine {
  SyncEngine(this._db);
  final AppDatabase _db;

  /// Local → Supabase (todas las tablas registradas).
  Future<void> pushAll() async {
    await RenovarToken.asegurar();
    if (!SupabaseConfig.isConfigured) {
      debugPrint('SyncEngine.pushAll: Supabase no configurado');
      return;
    }
        debugPrint('SyncEngine.pushAll: inicio');
    Future<void> step(String name, Future<void> Function() fn) async {
      try {
        await fn();
      } catch (e, st) {
        debugPrint('SyncEngine.pushAll [$name]: $e');
        debugPrint('$st');
      }
    }

    await step('dispositivos', () => DispositivoSync(_db).pushEsteEquipo());
    await step('usuarios', () => UsuarioSync(_db).pushTodos());
    await step('pedidos', () => PedidoSync(_db).pushTodos());
    await step('productos', () => ProductoSync(_db).pushTodos());
    await step('clientes', () => ClienteSync(_db).pushTodos());
    await step('ventas', () => VentaSync(_db).pushTodos());
    await step('caja', () => CajaSync(_db).pushTodos());
    await step('fios', () => FioSync(_db).pushTodos());
    debugPrint('SyncEngine.pushAll: fin');
  }

  /// Supabase → local (negocio actual vía NegocioLocal / pull).
  Future<void> pullAll() async {
    if (!SupabaseConfig.isConfigured) {
      debugPrint('SyncEngine.pullAll: Supabase no configurado');
      return;
    }
        debugPrint('SyncEngine.pullAll: inicio');
    try {
      await SyncPull(_db).pullTodoElNegocio();
      // Cuando existan pulls de ventas/caja, se llaman aquí o dentro de SyncPull.
      debugPrint('SyncEngine.pullAll: OK');
    } catch (e, st) {
      debugPrint('SyncEngine.pullAll: $e');
      debugPrint('$st');
      rethrow;
    }
  }
}
