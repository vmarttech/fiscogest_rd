import 'package:fiscogest_rd/core/interfaces/inventario_fisico_repository_interface.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/diferencia_conteo.dart';

class GuardarDiferenciaUsecase {
  GuardarDiferenciaUsecase(this._repo);
  final InventarioFisicoRepositoryInterface _repo;

  Future<void> call(DiferenciaConteo dif) => _repo.guardarDiferencia(dif);
}
