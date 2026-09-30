import 'package:fiscogest_rd/features/inventario/domain/entities/categoria.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_categoria_repository.dart';

class GuardarCategoriaUseCase {
  GuardarCategoriaUseCase(this._repo);
  final ICategoriaRepository _repo;

  Future<void> ejecutar(Categoria entidad) async => _repo.guardar(entidad);
}
