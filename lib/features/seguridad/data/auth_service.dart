import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';

class AuthResult {
  const AuthResult({required this.usuarioId, required this.username});
  final int usuarioId;
  final String username;
}

class AuthService {
  AuthService(this._db);
  final AppDatabase _db;

  Future<AuthResult?> login(String username, String password) async {
    final u = username.trim();
    final p = password;
    if (u.isEmpty || p.isEmpty) return null;

    final row = await (_db.select(_db.usuariosTable)
          ..where((t) => t.username.equals(u)))
        .getSingleOrNull();
    if (row == null) return null;
    if (row.estado.toLowerCase() != 'activo') return null;

    final hash = row.passwordHash;
    final ok = hash == p;
    if (!ok) return null;

    await (_db.update(_db.usuariosTable)..where((t) => t.id.equals(row.id)))
        .write(
      UsuariosTableCompanion(
        fechaUltimoAcceso: Value(DateTime.now()),
      ),
    );

    return AuthResult(usuarioId: row.id, username: row.username);
  }

  /// Crea admin/admin si la tabla está vacía.
  Future<void> ensureAdminSeed() async {
    final existentes = await _db.select(_db.usuariosTable).get();
    if (existentes.isNotEmpty) return;

    await _db.into(_db.usuariosTable).insert(
          UsuariosTableCompanion.insert(
            nombre: 'Administrador',
            username: 'admin',
            passwordHash: 'admin',
            apellido: const Value('Sistema'),
            email: const Value('admin@local'),
            rol: const Value('Admin'),
            estado: const Value('Activo'),
          ),
        );
  }
}
