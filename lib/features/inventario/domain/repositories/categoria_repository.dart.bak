import 'package:fiscogest_rd/features/inventario/domain/entities/categoria.dart';

abstract class CategoriaRepository {
  Future<List<Categoria>> obtenerTodos();
  Future<Categoria?> obtenerPorId(int id);
  Future<void> guardar(Categoria categoria);
  Future<void> actualizar(Categoria categoria);
  Future<void> eliminar(int id);
}
