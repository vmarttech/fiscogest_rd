import 'package:fiscogest_rd/features/ajustes_inventario/domain/entities/ajuste_inventario.dart';

abstract class IAjusteInventarioRepositoryImpl {
  Future<AjusteInventario?> obtenerAjustePorCodigo(String codigoBusqueda);
  Future<List<AjusteInventario>> listarTodos();
  Future<bool> guardarAjuste(AjusteInventario ajuste);
  Future<bool> eliminarAjuste(int id);
}
