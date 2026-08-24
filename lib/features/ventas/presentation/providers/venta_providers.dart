import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';
import 'package:fiscogest_rd/features/ventas/data/repositories/ventas_repository_impl.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/descuento.dart';
import 'package:fiscogest_rd/features/ventas/domain/usecases/convertir_cotizacion_a_venta.dart';
export 'registrar_venta_provider.dart';
export 'cotizacion_provider.dart';
export 'ventas_navegacion_provider.dart';
export 'venta_cargada_desde_historial_provider.dart';
export 'listas_ventas_providers.dart';
export 'descuentos_ofertas_providers.dart';
export 'registrar_venta_usecase_provider.dart';
final ventasRepositoryProvider = Provider<IVentasRepository>((ref) {
  return VentasRepositoryImpl();
});
final convertirCotizacionAVentaUseCaseProvider = Provider<ConvertirCotizacionAVenta>((ref) {
  final repositorio = ref.watch(ventasRepositoryProvider);
  return ConvertirCotizacionAVenta(repositorio);
});
final descuentosActivosProvider = FutureProvider<List<Descuento>>((ref) async {
  final repositorio = ref.watch(ventasRepositoryProvider);
  return repositorio.obtenerDescuentosActivos();
});
