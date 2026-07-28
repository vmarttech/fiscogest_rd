import 'package:fiscogest_rd/features/ajustes_inventario/domain/entities/ajuste_inventario.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/domain/repositories/ajuste_inventario_repository.dart';

class ListarAjustesUsecase {

  ListarAjustesUsecase(this._repository);
  final AjusteInventarioRepository _repository;

  Future<List<AjusteInventario>> call() async {
    return await _repository.listarAjustes();
  }
}
