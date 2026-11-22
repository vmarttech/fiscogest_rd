import 'package:flutter/foundation.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/sync/supabase/negocio_local.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_rest_client.dart';

class CompraSync {
  CompraSync(this._db);
  final AppDatabase _db;

  Future<void> pushTodos() async {
    if (!SupabaseConfig.isConfigured) return;
    final negocioId = await NegocioLocal.getId();
    if (negocioId == null || negocioId.isEmpty) {
      debugPrint('CompraSync: sin negocio_id');
      return;
    }

    final compras = await _db.select(_db.comprasTable).get();
    if (compras.isEmpty) {
      debugPrint('CompraSync: no hay compras locales');
    } else {
      final payload = compras
          .map((c) {
            final estado = c.estado;
            final estadoStr =
                estado is String ? estado : estado.toString().split('.').last;
            return <String, dynamic>{
              'negocio_id': negocioId,
              'id_local': c.id,
              'proveedor_id': c.proveedorId,
              'nombre_proveedor': c.nombreProveedor,
              'numero_comprobante': c.numeroComprobante,
              'tipo_comprobante': c.tipoComprobante,
              'ncf': c.ncf,
              'forma_pago': c.formaPago,
              'condicion_pago': c.condicionPago,
              'dias_credito': c.diasCredito,
              'fecha_emision': c.fechaEmision.toUtc().toIso8601String(),
              'fecha_confirmacion':
                  c.fechaConfirmacion?.toUtc().toIso8601String(),
              'fecha_vencimiento':
                  c.fechaVencimiento?.toUtc().toIso8601String(),
              'fecha_recepcion': c.fechaRecepcion?.toUtc().toIso8601String(),
              'fecha_pago': c.fechaPago?.toUtc().toIso8601String(),
              'subtotal_sin_impuestos': c.subtotalSinImpuestos,
              'monto_descuento_global': c.montoDescuentoGlobal,
              'tasa_impuesto': c.tasaImpuesto,
              'monto_impuesto': c.montoImpuesto,
              'total_compra': c.totalCompra,
              'estado': estadoStr,
              'observaciones': c.observaciones,
              'creado_en': c.creadoEn.toUtc().toIso8601String(),
              'actualizado_en': c.actualizadoEn?.toUtc().toIso8601String(),
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            };
          })
          .toList();
      await SupabaseRestClient().upsert(
        table: 'compras',
        rows: payload,
        onConflict: 'negocio_id,id_local',
      );
      debugPrint('CompraSync: OK → ${payload.length} compra(s)');
    }

    final dets = await _db.select(_db.detalleCompraTable).get();
    if (dets.isEmpty) {
      debugPrint('CompraSync: no hay detalle local');
      return;
    }
    final detPayload = dets
        .map((d) => <String, dynamic>{
              'negocio_id': negocioId,
              'id_local': d.id,
              'compra_id': d.compraId,
              'producto_id': d.productoId,
              'nombre_producto': d.nombreProducto,
              'cantidad': d.cantidad ?? 0,
              'costo_unitario': d.costoUnitario ?? 0,
              'flete_unitario': d.fleteUnitario ?? 0,
              'seguro_unitario': d.seguroUnitario ?? 0,
              'aranceles_unitario': d.arancelesUnitario ?? 0,
              'gastos_unitario': d.gastosUnitario ?? 0,
              'descuento_porcentaje': d.descuentoPorcentaje ?? 0,
              'monto_descuento_linea': d.montoDescuentoLinea ?? 0,
              'subtotal_linea': d.subtotalLinea ?? 0,
              'base_imponible_linea': d.baseImponibleLinea ?? 0,
              'itbis_linea': d.itbisLinea ?? 0,
              'total_linea': d.totalLinea ?? 0,
              'costo_adquisicion': d.costoAdquisicion ?? 0,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
        .toList();
    await SupabaseRestClient().upsert(
      table: 'compras_detalle',
      rows: detPayload,
      onConflict: 'negocio_id,id_local',
    );
    debugPrint('CompraSync: OK → ${detPayload.length} detalle(s)');
  }
}
