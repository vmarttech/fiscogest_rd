import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_unidadmedida_repository.dart';

class EliminarUnidadMedidaUseCase {
  EliminarUnidadMedidaUseCase(this._repo);
  final IUnidadMedidaRepository _repo;

  Future<void> ejecutar(int id) async => _repo.eliminar(id);
}
