import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';

abstract class IKardexRepository {
  Future<void> registrarMovimiento(Kardex movimiento);
  Future<List<Kardex>> obtenerHistorialPorProducto(int productoId);
  Future<List<Kardex>> obtenerTodoElHistorial({
    DateTime? desde,
    DateTime? hasta,
  });
  Future<double> obtenerSaldoActual(int productoId);
}
