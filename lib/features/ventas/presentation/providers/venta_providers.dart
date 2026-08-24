import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_dao.dart';
import 'package:fiscogest_rd/features/ventas/domain/services/i_cotizacion_service.dart';
import 'package:fiscogest_rd/features/ventas/data/services/cotizacion_service_impl.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';
import 'package:fiscogest_rd/features/ventas/data/repositories/ventas_repository_impl.dart';
import 'package:fiscogest_rd/features/ventas/domain/usecases/convertir_cotizacion_a_venta.dart';

export 'package:fiscogest_rd/features/ventas/presentation/providers/cotizacion_provider.dart';
export 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_provider.dart';
export 'package:fiscogest_rd/features/ventas/presentation/providers/venta_cargada_desde_historial_provider.dart';
export 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_usecase_provider.dart';
export 'package:fiscogest_rd/features/ventas/presentation/providers/listas_ventas_providers.dart';
export 'package:fiscogest_rd/features/ventas/presentation/providers/descuentos_ofertas_providers.dart';

final cotizacionServiceProvider = Provider<ICotizacionService>((ref) {
  return CotizacionServiceImpl();
});
final ventasDaoProvider = Provider<VentasDao>((ref) {
  final db = ref.read(databaseProvider);
  return VentasDao(db);
});
final ventasRepositoryProvider = Provider<IVentasRepository>((ref) {
  final dao = ref.read(ventasDaoProvider);
  return VentasRepositoryImpl(ventasDao: dao);
});
final convertirCotizacionAVentaUseCaseProvider = Provider<ConvertirCotizacionAVenta>((ref) {
  final repositorio = ref.read(ventasRepositoryProvider);
  return ConvertirCotizacionAVenta(repositorio);
});
