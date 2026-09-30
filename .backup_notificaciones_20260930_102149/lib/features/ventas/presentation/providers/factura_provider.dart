import 'package:riverpod/riverpod.dart';
import 'package:fiscogest_rd/features/ventas/data/services/factura_service_impl.dart';
import 'package:fiscogest_rd/features/ventas/domain/services/i_factura_service.dart';

final facturaServiceProvider = Provider<IFacturaService>((ref) {
  return FacturaServiceImpl();
});
