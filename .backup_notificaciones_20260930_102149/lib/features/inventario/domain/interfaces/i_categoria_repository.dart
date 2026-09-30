import 'package:fiscogest_rd/features/inventario/domain/entities/categoria.dart';

abstract class ICategoriaRepository {
  Future<List<Categoria>> obtenerTodos();
  Future<void> guardar(Categoria entidad);
  Future<void> actualizar(Categoria entidad);
  Future<void> eliminar(int id);
}
