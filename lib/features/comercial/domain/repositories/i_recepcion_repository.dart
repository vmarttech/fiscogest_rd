import 'package:fiscogest_rd/features/comercial/domain/entities/recepcion.dart';

abstract class IRecepcionRepository {
  Future<String> crear(Recepcion recepcion);
  Future<void> actualizar(Recepcion recepcion);
  Future<Recepcion?> obtenerPorId(String id);
  Future<List<Recepcion>> listarPorCompra(String compraId);
  Future<List<Recepcion>> listarTodos({DateTime? desde, DateTime? hasta});
}
