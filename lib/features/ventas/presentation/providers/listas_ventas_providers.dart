import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

extension VentaExtension on Venta {
  CotizacionState toCotizacionState() {
    final double descuentoCalc = total - subtotal - itbis;
    return CotizacionState(
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

final listaCotizacionesProvider = FutureProvider<List<CotizacionState>>((ref) async {
  final IVentasRepository repositorio = ref.watch(ventasRepositoryProvider);
  final List<Venta> entidades = await repositorio.listarVentas();
  return entidades.map((Venta e) => e.toCotizacionState()).toList();
});

final listaApartadosProvider = FutureProvider<List<dynamic>>((ref) async {
  final IVentasRepository repositorio = ref.watch(ventasRepositoryProvider);
  await Future.value(repositorio);
  return [];
});

final listaVentasProvider = FutureProvider<List<Venta>>((ref) async {
  final IVentasRepository repositorio = ref.watch(ventasRepositoryProvider);
  return await repositorio.listarVentas();
});
