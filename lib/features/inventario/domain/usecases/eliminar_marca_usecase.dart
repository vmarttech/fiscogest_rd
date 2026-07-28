import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_marca_repository.dart';

class EliminarMarcaUseCase {
  EliminarMarcaUseCase(this._repo);
  final IMarcaRepository _repo;

  Future<void> ejecutar(int id) async => _repo.eliminar(id);
}
