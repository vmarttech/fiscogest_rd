import 'package:fiscogest_rd/core/interfaces/inventario_fisico_repository_interface.dart';

class AprobarAjustesUsecase {
  AprobarAjustesUsecase(this._repo);
  final InventarioFisicoRepositoryInterface _repo;
  Future<void> call(int conteoId, int usuarioId) =>
      _repo.aprobarAjustes(conteoId, usuarioId);
}
