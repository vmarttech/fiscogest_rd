import 'package:flutter/foundation.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/sync/supabase/negocio_local.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_rest_client.dart';

class VentaSync {
  VentaSync(this._db);
  final AppDatabase _db;

  Future<void> pushTodos() async {
    if (!SupabaseConfig.isConfigured) return;
    final negocioId = await NegocioLocal.getId();
    if (negocioId == null || negocioId.isEmpty) {
      debugPrint('VentaSync: sin negocio_id');
      return;
    }

    final ventas = await _db.select(_db.ventasTable).get();
    if (ventas.isEmpty) {
      debugPrint('VentaSync: no hay ventas locales');
    } else {
      final payload = ventas
          .map((v) => <String, dynamic>{
                'negocio_id': negocioId,
                'id_local': v.id,
                'cliente_id_local': v.clienteId,
                'nombre_cliente': v.nombreCliente,
                'cliente_telefono': v.clienteTelefono,
                'cliente_whatsapp': v.clienteWhatsapp,
                'cliente_direccion': v.clienteDireccion,
                'fecha': v.fecha.toUtc().toIso8601String(),
                'monto_subtotal': v.montoSubtotal,
                'descuento_global': v.descuentoGlobal,
                'itbis': v.itbis,
                'monto_total': v.montoTotal,
                'forma_pago': v.formaPago,
                'costo_envio': v.costoEnvio,
                'abono_inicial': v.abonoInicial,
                'numero_cuotas': v.numeroCuotas,
                'plazo_dias': v.plazoDias,
                'tasa_interes': v.tasaInteres,
                'monto_interes': v.montoInteres,
                'vencimiento': v.vencimiento?.toUtc().toIso8601String(),
                'numero_cotizacion': v.numeroCotizacion,
                'numero_factura': v.numeroFactura,
                'estado_documento': v.estadoDocumento,
                'usuario_id_local': v.usuarioId,
                'fecha_registro': v.fechaRegistro.toUtc().toIso8601String(),
                'descuento_id': v.descuentoId,
                'descuento_nombre': v.descuentoNombre,
                'monto_descuento': v.montoDescuento,
                'comprobante_entrega_impreso': v.comprobanteEntregaImpreso,
                'fecha_comprobante_entrega':
                    v.fechaComprobanteEntrega?.toUtc().toIso8601String(),
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              })
          .toList();
      await SupabaseRestClient().upsert(
        table: 'ventas',
        rows: payload,
        onConflict: 'negocio_id,id_local',
      );
      debugPrint('VentaSync: OK → ${payload.length} venta(s)');
    }

    final dets = await _db.select(_db.ventasDetalleTable).get();
    if (dets.isEmpty) {
      debugPrint('VentaSync: no hay detalle local');
      return;
    }
    final detPayload = dets
        .map((d) => <String, dynamic>{
              'negocio_id': negocioId,
              'id_local': d.id,
              'venta_id_local': d.ventaId,
              'producto_id_local': d.productoId,
              'cantidad': d.cantidad,
              'precio_unitario': d.precioUnitario,
              'descuento_linea': d.descuentoLinea,
              'subtotal': d.subtotal,
              'impuesto': d.impuesto,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
        .toList();
    await SupabaseRestClient().upsert(
      table: 'ventas_detalle',
      rows: detPayload,
      onConflict: 'negocio_id,id_local',
    );
    debugPrint('VentaSync: OK → ${detPayload.length} detalle(s)');
  }
}
