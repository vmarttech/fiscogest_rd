import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/diferencia_conteo.dart';
import 'package:fiscogest_rd/core/interfaces/inventario_fisico_repository_interface.dart';

class ListarDiferenciasUsecase {

  ListarDiferenciasUsecase(this._repo);
  final InventarioFisicoRepositoryInterface _repo;

  Future<List<DiferenciaConteo>> call(int conteoId) async {
    return _repo.listarDiferencias(conteoId);
  }
}
