import 'package:fiscogest_rd/features/inventario/domain/entities/marca.dart';

abstract class MarcaRepository {
  Future<List<Marca>> obtenerTodos();
  Future<Marca?> obtenerPorId(int id);
  Future<void> guardar(Marca marca);
  Future<void> actualizar(Marca marca);
  Future<void> eliminar(int id);
}
