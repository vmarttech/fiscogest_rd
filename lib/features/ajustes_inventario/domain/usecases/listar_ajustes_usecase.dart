import 'package:fiscogest_rd/features/ajustes_inventario/domain/entities/ajuste_inventario.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/data/repositories/ajuste_inventario_repository_impl.dart';

class ListarAjustesUsecase {

  ListarAjustesUsecase(this._repository);
  final AjusteInventarioRepositoryImpl _repository;

  Future<List<AjusteInventario>> call() async {
    return await _repository.listarAjustes();
  }
}
