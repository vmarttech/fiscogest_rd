import 'package:fiscogest_rd/features/inventario/domain/entities/unidad_medida.dart';

abstract class UnidadMedidaRepository {
  Future<List<UnidadMedida>> obtenerTodos();
  Future<UnidadMedida?> obtenerPorId(int id);
  Future<void> guardar(UnidadMedida unidad);
  Future<void> actualizar(UnidadMedida unidad);
  Future<void> eliminar(int id);
}
