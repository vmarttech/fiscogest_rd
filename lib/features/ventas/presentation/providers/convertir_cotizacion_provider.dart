import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';
import 'package:fiscogest_rd/features/ventas/domain/usecases/convertir_cotizacion_a_venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final convertirCotizacionAVentaProvider = Provider<ConvertirCotizacionAVenta>((ref) {
  final IVentasRepository repositorio = ref.watch(ventasRepositoryProvider);
  return ConvertirCotizacionAVenta(repositorio);
});
