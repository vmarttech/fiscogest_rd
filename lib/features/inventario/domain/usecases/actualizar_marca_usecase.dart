import 'package:fiscogest_rd/features/inventario/domain/entities/marca.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_marca_repository.dart';

class ActualizarMarcaUseCase {
  ActualizarMarcaUseCase(this._repo);
  final IMarcaRepository _repo;

  Future<void> ejecutar(Marca entidad) async => _repo.actualizar(entidad);
}
