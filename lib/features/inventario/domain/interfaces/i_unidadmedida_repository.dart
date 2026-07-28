import 'package:fiscogest_rd/features/inventario/domain/entities/unidadmedida.dart';

abstract class IUnidadMedidaRepository {
  Future<List<UnidadMedida>> obtenerTodos();
  Future<void> guardar(UnidadMedida entidad);
  Future<void> actualizar(UnidadMedida entidad);
  Future<void> eliminar(int id);
}
