import 'package:fiscogest_rd/features/inventario/domain/entities/marca.dart';

abstract class IMarcaRepository {
  Future<List<Marca>> obtenerTodos();
  Future<void> guardar(Marca entidad);
  Future<void> actualizar(Marca entidad);
  Future<void> eliminar(int id);
}
