import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';

abstract class IFacturaService {
  String generarTextoFactura(Venta venta);
  Future<void> imprimirFactura(Venta venta);
}
