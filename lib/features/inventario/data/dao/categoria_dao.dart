import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/categoria.dart';

class CategoriaDao {
  CategoriaDao(this.db);
  final AppDatabase db;

  Future<List<Categoria>> obtenerTodos() async => [];
  Future<void> guardar(Categoria entidad) async {}
  Future<void> actualizar(Categoria entidad) async {}
  Future<void> eliminar(int id) async {}
}
