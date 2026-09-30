import 'package:fiscogest_rd/features/inventario/domain/entities/unidadmedida.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_unidadmedida_repository.dart';

class ObtenerTodosUnidadMedidaUseCase {
  ObtenerTodosUnidadMedidaUseCase(this._repo);
  final IUnidadMedidaRepository _repo;

  Future<List<UnidadMedida>> ejecutar() async => _repo.obtenerTodos();
}
