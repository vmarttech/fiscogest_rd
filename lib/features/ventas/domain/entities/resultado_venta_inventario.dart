import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';

/// Resultado de registrar venta + salida de inventario.
/// [costoCents] = suma (costo unitario × cantidad) en centavos enteros.
class ResultadoVentaInventario {
  const ResultadoVentaInventario({
    required this.venta,
    required this.costoCents,
  });

  final Venta venta;
  final int costoCents;
}
