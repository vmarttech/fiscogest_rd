import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/domain/services/i_cotizacion_service.dart';
import 'package:fiscogest_rd/features/ventas/data/services/cotizacion_service_impl.dart';

final cotizacionServiceProvider = Provider<ICotizacionService>((ref) {
  return CotizacionServiceImpl();
});
