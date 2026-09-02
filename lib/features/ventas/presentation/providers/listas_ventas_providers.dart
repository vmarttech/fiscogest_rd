import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_dao.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_borrador_provider.dart';

Venta _convertirVentaDeDao(VentaConCliente origen) {
  return Venta(
    id: origen.venta.id,
    numero: origen.venta.id.toString(),
    clienteId: origen.venta.clienteId,
    nombreCliente: origen.nombreCliente,
    fecha: origen.venta.fecha,
    detalles: [],
    subtotal: origen.venta.montoSubtotal,
    itbis: origen.venta.itbis,
    total: origen.venta.montoTotal,
    tipoPago: origen.venta.formaPago.name,
    esCredito: false,
    cotizacionOrigenId: null,
    apartadoOrigenId: null,
    usuarioId: origen.venta.usuarioId,
    createdAt: origen.venta.fechaRegistro,
    descuentoId: null,
    descuentoNombre: null,
    montoDescuento: origen.venta.descuentoGlobal,
  );
}

extension VentaExtension on Venta {
  VentaBorradorState toVentaBorradorState() {
    final double descuentoCalc = total - subtotal - itbis;
    return VentaBorradorState(
      numero: numero,
      fecha: fecha,
      vencimiento: null,
      clienteId: clienteId,
      clienteNombre: nombreCliente,
      subtotal: subtotal,
      itbis: itbis,
      descuento: descuentoCalc,
      montoDescuento: descuentoCalc,
      montoTotal: total,
    );
  }
}

final listaVentasProvider = FutureProvider<List<Venta>>((ref) async {
  final AppDatabase db = ref.watch(databaseProvider);
  final dao = VentasDao(db);
  final resultado = await dao.listarVentas();
  return resultado.map((e) => _convertirVentaDeDao(e)).toList();
});

final listaVentasBorradorProvider = FutureProvider<List<VentaBorradorState>>((
  ref,
) async {
  final ventas = await ref.watch(listaVentasProvider.future);
  return ventas.map((e) => e.toVentaBorradorState()).toList();
});

final listaApartadosProvider = FutureProvider<List<dynamic>>((ref) async {
  return [];
});
