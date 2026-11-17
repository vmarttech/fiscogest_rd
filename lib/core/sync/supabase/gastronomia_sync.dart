import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/sync/supabase/negocio_local.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';
import 'dart:io';
import 'package:fiscogest_rd/core/sync/supabase/supabase_rest_client.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_storage.dart';

/// Sincronizacion del modulo Gastronomia RD con Supabase.
/// Push full (upsert por negocio_id+id_local) de las 9 tablas locales,
/// igual que VentaSync. Pull de pedidos entrantes del catalogo web (tabla
/// remota gastro_pedidos_web; si aun no existe, el error se ignora).
class GastronomiaSync {
  GastronomiaSync(this._db);
  final AppDatabase _db;
  final _client = SupabaseRestClient();
  static const _onConflict = 'negocio_id,id_local';

  Future<void> pushPendientes() async {
    if (!SupabaseConfig.isConfigured) return;
    final negocioId = await NegocioLocal.getId();
    if (negocioId == null || negocioId.isEmpty) {
      debugPrint('GastronomiaSync: sin negocio_id');
      return;
    }
    try {
      await _pushExtras(negocioId);
      await _pushProductoExtras(negocioId);
      await _pushSectores(negocioId);
      await _pushRepartidores(negocioId);
      await _pushProductosMeta(negocioId);
      await _pushCategoriasMeta(negocioId);
      await _pushPedidos(negocioId);
      await _pushPedidoLineas(negocioId);
      await _pushPedidoLineaExtras(negocioId);
      await _subirFotosPendientes(negocioId);
      debugPrint('GastronomiaSync.push: OK');
    } catch (e) {
      debugPrint('GastronomiaSync.push: $e');
    }
  }

  Future<void> pullPedidosWeb() async {
    if (!SupabaseConfig.isConfigured) return;
    final negocioId = await NegocioLocal.getId();
    if (negocioId == null || negocioId.isEmpty) return;
    try {
      final rows = await _client.select(
        table: 'gastro_pedidos_web',
        filters: {'negocio_id': 'eq.$negocioId'},
      );
      if (rows.isEmpty) return;
      var insertados = 0;
      for (final r in rows) {
        final uuid = (r['uuid'] as String?)?.trim() ?? '';
        if (uuid.isEmpty) continue;
        final existe = await (_db.select(_db.pedidosGastronomiaTable)
              ..where((t) => t.uuid.equals(uuid)))
            .getSingleOrNull();
        if (existe != null) continue;
        final pedidoLocalId =
            await _db.into(_db.pedidosGastronomiaTable).insert(
          PedidosGastronomiaTableCompanion.insert(
            uuid: Value(uuid),
            tipo: Value((r['tipo'] as String?) ?? 'delivery'),
            estado: Value((r['estado'] as String?) ?? 'pendiente'),
            nombreCliente:
                Value((r['nombre_cliente'] as String?) ?? 'Consumidor Final'),
            telefono: Value((r['telefono'] as String?) ?? ''),
            direccionReferencia:
                Value((r['direccion_referencia'] as String?) ?? ''),
            costoEnvio: Value(_d(r['costo_envio'])),
            subtotal: Value(_d(r['subtotal'])),
            itbis: Value(_d(r['itbis'])),
            descuento: Value(_d(r['descuento'])),
            total: Value(_d(r['total'])),
            formaPago: Value((r['forma_pago'] as String?) ?? 'efectivo'),
            notas: Value((r['notas'] as String?) ?? ''),
            estadoEntrega: const Value('pendiente'),
            sincronizado: const Value(true),
          ),
        );
        // Líneas del carrito (jsonb). El catálogo web no conoce ids locales,
        // así que producto_id_local=0 y se confía en nombre_snapshot.
        final lineasRaw = r['lineas'];
        final lineas = (lineasRaw is List)
            ? lineasRaw
            : (lineasRaw is String
                ? (jsonDecode(lineasRaw) as List? ?? <dynamic>[])
                : <dynamic>[]);
        for (final ln in lineas) {
          if (ln is! Map) continue;
          final lineaLocalId =
              await _db.into(_db.pedidoGastronomiaLineaTable).insert(
            PedidoGastronomiaLineaTableCompanion.insert(
              pedidoId: pedidoLocalId,
              productoId: _int(ln['producto_id_local'], 0),
              nombreSnapshot: Value((ln['nombre'] as String?) ?? ''),
              cantidad: Value(_d(ln['cantidad'])),
              precioUnitario: Value(_d(ln['precio_unitario'])),
              subtotal: Value(_d(ln['subtotal'])),
              notas: Value((ln['notas'] as String?) ?? ''),
            ),
          );
          final extrasRaw = ln['extras'];
          final extras = (extrasRaw is List) ? extrasRaw : <dynamic>[];
          for (final ex in extras) {
            if (ex is! Map) continue;
            await _db.into(_db.pedidoLineaExtraTable).insert(
              PedidoLineaExtraTableCompanion.insert(
                lineaId: lineaLocalId,
                nombreSnapshot: Value((ex['nombre'] as String?) ?? ''),
                precioSnapshot: Value(_d(ex['precio'])),
              ),
            );
          }
        }
        insertados++;
      }
      debugPrint('GastronomiaSync.pull: $insertados pedido(s) web');
    } catch (e) {
      // Tabla remota aun no existe (catalogo web pendiente) → no es error.
      debugPrint('GastronomiaSync.pull: $e');
    }
  }

  Future<void> _upsert(String table, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await _client.upsert(table: table, rows: rows, onConflict: _onConflict);
  }

  /// Reintenta subir a Storage las fotos que quedaron en temp (sin red / RLS / 404).
  /// Corre en cada ciclo push; un fallo de una fila no interrumpe el resto.
  /// DebugPrint con statusCode: 401=key rechazada, 403=falta policy, 404=bucket ausente.
  Future<void> _subirFotosPendientes(String negocioId) async {
    int subidas = 0;
    int fallidas = 0;
    try {
      final metas = await _db.select(_db.productosGastroMetaTable).get();
      for (final m in metas) {
        final ruta = m.fotoPath.trim();
        if (ruta.isEmpty) continue;
        final f = File(ruta);
        if (!await f.exists()) {
          // El SO purgo el temp antes de subir; la proxima captura reinicia el intento.
          continue;
        }
        try {
          final bytes = await f.readAsBytes();
          final clave = await SupabaseStorage().subir(
              negocioId: negocioId, productoId: m.productoId, bytes: bytes);
          await (_db.update(_db.productosGastroMetaTable)
                ..where((t) => t.productoId.equals(m.productoId)))
              .write(ProductosGastroMetaTableCompanion(
            fotoPath: const Value(''),
            fotoRemotaKey: Value(clave),
            fotoSincronizado: const Value(true),
            fotoActualizadoEn: Value(DateTime.now()),
          ));
          try {
            await f.delete();
          } catch (_) {}
          subidas++;
          debugPrint(
              'GastronomiaSync.foto OK producto=${m.productoId} -> $clave');
        } catch (e) {
          fallidas++;
          debugPrint(
              'GastronomiaSync.foto FALLO producto=${m.productoId}: $e');
        }
      }
      if (subidas > 0 || fallidas > 0) {
        debugPrint(
            'GastronomiaSync.fotos: subidas=$subidas fallidas=$fallidas');
      }
    } catch (e) {
      debugPrint('GastronomiaSync.fotos capa: $e');
    }
  }

  dynamic _iso(DateTime? d) => d?.toUtc().toIso8601String();
  double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  int _int(dynamic v, int fallback) {
    if (v == null) return fallback;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  Future<void> _pushExtras(String negocioId) async {
    final rows = await _db.select(_db.extrasGastronomiaTable).get();
    final payload = rows
        .map((e) => <String, dynamic>{
              'negocio_id': negocioId, 'id_local': e.id,
              'nombre': e.nombre, 'precio': e.precio, 'activo': e.activo,
              'creado_en': _iso(e.creadoEn),
            })
        .toList();
    await _upsert('gastro_extras', payload);
    debugPrint('GastronomiaSync: extras ${payload.length}');
  }

  Future<void> _pushProductoExtras(String negocioId) async {
    final rows = await _db.select(_db.productoExtraTable).get();
    final payload = rows
        .map((r) => <String, dynamic>{
              'negocio_id': negocioId, 'id_local': r.id,
              'producto_id_local': r.productoId, 'extra_id_local': r.extraId,
              'activo': r.activo,
            })
        .toList();
    await _upsert('gastro_producto_extras', payload);
  }

  Future<void> _pushSectores(String negocioId) async {
    final rows = await _db.select(_db.sectoresDeliveryTable).get();
    final payload = rows
        .map((s) => <String, dynamic>{
              'negocio_id': negocioId, 'id_local': s.id,
              'nombre': s.nombre, 'tarifa_envio': s.tarifaEnvio,
              'monto_minimo_envio_gratis': s.montoMinimoEnvioGratis,
              'orden': s.orden, 'activo': s.activo,
              'creado_en': _iso(s.creadoEn),
            })
        .toList();
    await _upsert('gastro_sectores', payload);
  }

  Future<void> _pushRepartidores(String negocioId) async {
    final rows = await _db.select(_db.repartidoresTable).get();
    final payload = rows
        .map((r) => <String, dynamic>{
              'negocio_id': negocioId, 'id_local': r.id,
              'nombre': r.nombre, 'telefono': r.telefono, 'activo': r.activo,
              'creado_en': _iso(r.creadoEn),
            })
        .toList();
    await _upsert('gastro_repartidores', payload);
  }

  Future<void> _pushProductosMeta(String negocioId) async {
    final rows = await _db.select(_db.productosGastroMetaTable).get();
    final payload = rows
        .map((m) => <String, dynamic>{
              'negocio_id': negocioId, 'id_local': m.id,
              'producto_id_local': m.productoId, 'foto_path': '',
              'foto_remota_key': m.fotoRemotaKey,
              'es_gastronomico': m.esGastronomico, 'destacado': m.destacado,
              'disponible_menu': m.disponibleMenu,
              'actualizado_en': _iso(m.actualizadoEn),
            })
        .toList();
    await _upsert('gastro_productos_meta', payload);
  }

  Future<void> _pushCategoriasMeta(String negocioId) async {
    final rows = await _db.select(_db.categoriasMenuMetaTable).get();
    final payload = rows
        .map((c) => <String, dynamic>{
              'negocio_id': negocioId, 'id_local': c.id,
              'categoria_id_local': c.categoriaId,
              'visible_en_menu': c.visibleEnMenu,
              'orden_menu': c.ordenMenu,
            })
        .toList();
    await _upsert('gastro_categorias_meta', payload);
  }

  Future<void> _pushPedidos(String negocioId) async {
    final rows = await _db.select(_db.pedidosGastronomiaTable).get();
    final payload = rows
        .map((p) => <String, dynamic>{
              'negocio_id': negocioId, 'id_local': p.id,
              'uuid': p.uuid, 'tipo': p.tipo, 'estado': p.estado,
              'cliente_id_local': p.clienteId,
              'nombre_cliente': p.nombreCliente, 'telefono': p.telefono,
              'sector_id_local': p.sectorId,
              'direccion_referencia': p.direccionReferencia,
              'costo_envio': p.costoEnvio, 'subtotal': p.subtotal,
              'itbis': p.itbis, 'descuento': p.descuento, 'total': p.total,
              'forma_pago': p.formaPago, 'venta_id_local': p.ventaId,
              'repartidor_id_local': p.repartidorId,
              'estado_entrega': p.estadoEntrega, 'notas': p.notas,
              'usuario_id_local': p.usuarioId, 'fecha': _iso(p.fecha),
              'sincronizado': p.sincronizado,
            })
        .toList();
    await _upsert('gastro_pedidos', payload);
  }

  Future<void> _pushPedidoLineas(String negocioId) async {
    final rows = await _db.select(_db.pedidoGastronomiaLineaTable).get();
    final payload = rows
        .map((l) => <String, dynamic>{
              'negocio_id': negocioId, 'id_local': l.id,
              'pedido_id_local': l.pedidoId, 'producto_id_local': l.productoId,
              'nombre_snapshot': l.nombreSnapshot, 'cantidad': l.cantidad,
              'precio_unitario': l.precioUnitario, 'subtotal': l.subtotal,
              'notas': l.notas,
            })
        .toList();
    await _upsert('gastro_pedido_lineas', payload);
  }

  Future<void> _pushPedidoLineaExtras(String negocioId) async {
    final rows = await _db.select(_db.pedidoLineaExtraTable).get();
    final payload = rows
        .map((e) => <String, dynamic>{
              'negocio_id': negocioId, 'id_local': e.id,
              'linea_id_local': e.lineaId, 'extra_id_local': e.extraId,
              'nombre_snapshot': e.nombreSnapshot,
              'precio_snapshot': e.precioSnapshot,
            })
        .toList();
    await _upsert('gastro_pedido_linea_extras', payload);
  }
}
