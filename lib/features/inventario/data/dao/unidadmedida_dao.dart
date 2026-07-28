import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/unidadmedida.dart';

class UnidadMedidaDao {
  UnidadMedidaDao(this.db);
  final AppDatabase db;

  Future<List<UnidadMedida>> obtenerTodos() async => [];
  Future<void> guardar(UnidadMedida entidad) async {}
  Future<void> actualizar(UnidadMedida entidad) async {}
  Future<void> eliminar(int id) async {}
}
