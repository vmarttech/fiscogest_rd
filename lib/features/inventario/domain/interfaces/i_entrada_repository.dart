import '../entities/entrada.dart';

abstract class IEntradaRepository {
  Future<void> registrarEntrada(Entrada entrada);
  Future<List<Entrada>> obtenerHistorialEntradas();
  Future<List<Entrada>> obtenerEntradasPorProducto(int productoId);
}
