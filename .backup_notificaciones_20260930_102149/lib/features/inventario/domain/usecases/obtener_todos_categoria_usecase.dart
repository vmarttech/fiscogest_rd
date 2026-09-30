import 'package:fiscogest_rd/features/inventario/domain/entities/categoria.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_categoria_repository.dart';

class ObtenerTodosCategoriaUseCase {
  ObtenerTodosCategoriaUseCase(this._repo);
  final ICategoriaRepository _repo;

  Future<List<Categoria>> ejecutar() async => _repo.obtenerTodos();
}
