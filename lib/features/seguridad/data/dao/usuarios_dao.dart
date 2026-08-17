import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/seguridad/data/dao/usuarios_table.dart';

part 'usuarios_dao.g.dart';

@DriftAccessor(tables: [UsuariosTable])
class UsuariosDao extends DatabaseAccessor<AppDatabase> with _$UsuariosDaoMixin {
  UsuariosDao(super.db);

  Future<List<UsuarioData>> obtenerTodos() => select(usuariosTable).get();

  Future<UsuarioData?> obtenerPorId(int id) =>
      (select(usuariosTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<UsuarioData?> obtenerPorUsuario(String usuario) =>
      (select(usuariosTable)..where((t) => t.username.equals(usuario))).getSingleOrNull();

  Future<int> insertar(UsuariosTableCompanion usuario) =>
      into(usuariosTable).insert(usuario);

  Future<bool> actualizar(UsuarioData usuario) async {
    final bool exito = await update(usuariosTable).replace(usuario);
    return exito;
  }

  Future<bool> cambiarEstado(int id, String nuevoEstado) async {
    final int filas = await (update(usuariosTable)..where((t) => t.id.equals(id)))
        .write(UsuariosTableCompanion(estado: Value(nuevoEstado)));
    return filas > 0;
  }
}
