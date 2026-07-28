import 'package:fiscogest_rd/features/inventario/domain/entities/salida.dart';

abstract class ISalidaRepository {
  Future<void> registrarSalida(Salida salida);
  Future<List<Salida>> obtenerHistorialSalidas();
  Future<List<Salida>> obtenerSalidasPorProducto(int productoId);
}