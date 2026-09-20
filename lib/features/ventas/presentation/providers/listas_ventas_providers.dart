import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_dao.dart';
import 'package:fiscogest_rd/features/ventas/data/repositories/ventas_repository_impl.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/apartado.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_borrador_provider.dart';
import 'package:riverpod/riverpod.dart';

final ventasRepositoryProvider = Provider<VentasRepositoryImpl>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return VentasRepositoryImpl(
    VentasDao(db),
    CuentasCobrarDao(db),
  );
});

final listaVentasProvider = FutureProvider<List<Venta>>((ref) async {
  final repo = ref.watch(ventasRepositoryProvider);
  return await repo.listarVentas();
});

final listaCotizacionesProvider = FutureProvider<List<Venta>>((ref) async {
  final repo = ref.watch(ventasRepositoryProvider);
  return await repo.listarCotizaciones();
});

VentaBorradorState _ventaABorradorState(Venta v) {
  return VentaBorradorState(
    id: v.id,
    numero: v.numero,
    fecha: v.fecha,
    vencimiento: v.vencimiento,
    clienteId: v.clienteId,
    clienteNombre: v.nombreCliente,
    subtotal: v.subtotal,
    itbis: v.itbis,
    costoEnvio: 0.0,
    descuento: v.montoDescuento > 0 ? v.montoDescuento : null,
    descuentoId: v.descuentoId,
    descuentoNombre: v.descuentoNombre,
    montoDescuento: v.montoDescuento,
    montoTotal: v.total,
    tipoPago: v.tipoPago,
    esCredito: v.esCredito,
    detalles: v.detalles.map((det) => <String, dynamic>{
      'productoId': det.productoId,
      'productoNombre': det.nombreProducto,
      'cantidad': det.cantidad,
      'precioUnitario': det.precioUnitario,
      'subtotal': det.subtotal,
    }).toList(),
    estadoDocumento: v.estadoDocumento,
  );
}

final listaVentasBorradorProvider = FutureProvider<List<VentaBorradorState>>((ref) async {
  final lista = await ref.watch(listaCotizacionesProvider.future);
  return lista.map((v) => _ventaABorradorState(v)).toList();
});

final listaApartadosProvider = FutureProvider<List<Apartado>>((ref) async {
  return [];
});
