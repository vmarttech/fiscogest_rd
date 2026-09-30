import 'package:fiscogest_rd/features/inventario/domain/entities/unidadmedida.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_unidadmedida_repository.dart';

class ActualizarUnidadMedidaUseCase {
  ActualizarUnidadMedidaUseCase(this._repo);
  final IUnidadMedidaRepository _repo;

  Future<void> ejecutar(UnidadMedida entidad) async =>
      _repo.actualizar(entidad);
}
