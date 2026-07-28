import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/conteo_fisico.dart';
import 'package:fiscogest_rd/core/interfaces/inventario_fisico_repository_interface.dart';

class RegistrarConteoUsecase {

  RegistrarConteoUsecase(this._repo);
  final InventarioFisicoRepositoryInterface _repo;

  Future<void> call(ConteoFisico conteo) async {
    await _repo.registrarConteo(conteo);
  }
}
