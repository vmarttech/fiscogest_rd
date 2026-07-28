import 'package:fiscogest_rd/features/inventario/domain/entities/unidadmedida.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_unidadmedida_repository.dart';
import 'package:fiscogest_rd/features/inventario/data/dao/unidadmedida_dao.dart';

class UnidadMedidaRepositoryImpl implements IUnidadMedidaRepository {
  UnidadMedidaRepositoryImpl(this._dao);
  final UnidadMedidaDao _dao;

  @override Future<List<UnidadMedida>> obtenerTodos() async => _dao.obtenerTodos();
  @override Future<void> guardar(UnidadMedida entidad) async => _dao.guardar(entidad);
  @override Future<void> actualizar(UnidadMedida entidad) async => _dao.actualizar(entidad);
  @override Future<void> eliminar(int id) async => _dao.eliminar(id);
}
