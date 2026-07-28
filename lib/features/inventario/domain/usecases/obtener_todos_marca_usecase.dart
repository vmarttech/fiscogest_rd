import 'package:fiscogest_rd/features/inventario/domain/entities/marca.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_marca_repository.dart';

class ObtenerTodosMarcaUseCase {
  ObtenerTodosMarcaUseCase(this._repo);
  final IMarcaRepository _repo;

  Future<List<Marca>> ejecutar() async => _repo.obtenerTodos();
}
