import 'package:fiscogest_rd/features/comercial/domain/entities/recepcion.dart';

abstract class IRecepcionRepository {
  Future<int> crear(Recepcion recepcion);
  Future<void> actualizar(Recepcion recepcion);
  Future<Recepcion?> obtenerPorId(int id);
  Future<List<Recepcion>> listarPorCompra(int compraId);
  Future<List<Recepcion>> listarTodos({DateTime? desde, DateTime? hasta});
}
