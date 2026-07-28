import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_categoria_repository.dart';

class EliminarCategoriaUseCase {
  EliminarCategoriaUseCase(this._repo);
  final ICategoriaRepository _repo;

  Future<void> ejecutar(int id) async => _repo.eliminar(id);
}
