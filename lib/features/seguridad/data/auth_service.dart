import 'dart:convert';
import 'package:crypto/crypto.dart';
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

  static String hashPassword(String plain) {
    return sha256.convert(utf8.encode(plain)).toString();
  }

  Future<AuthResult?> login(String username, String password) async {
    final u = username.trim();
    if (u.isEmpty || password.isEmpty) return null;

    final row = await (_db.select(_db.usuariosTable)
          ..where((t) => t.username.equals(u)))
        .getSingleOrNull();
    if (row == null) return null;
    if (row.estado.toLowerCase() != 'activo') return null;

    final hashed = hashPassword(password);
    // Compat: hash nuevo o texto plano antiguo
    final ok = row.passwordHash == hashed || row.passwordHash == password;
    if (!ok) return null;

    if (row.passwordHash == password) {
      await (_db.update(_db.usuariosTable)..where((t) => t.id.equals(row.id)))
          .write(UsuariosTableCompanion(passwordHash: Value(hashed)));
    }

    await (_db.update(_db.usuariosTable)..where((t) => t.id.equals(row.id)))
        .write(
      UsuariosTableCompanion(fechaUltimoAcceso: Value(DateTime.now())),
    );

    return AuthResult(usuarioId: row.id, username: row.username);
  }

  Future<void> ensureAdminSeed() async {
    final existentes = await _db.select(_db.usuariosTable).get();
    if (existentes.isNotEmpty) return;

    await _db.into(_db.usuariosTable).insert(
          UsuariosTableCompanion.insert(
            nombre: 'Administrador',
            username: 'admin',
            passwordHash: hashPassword('admin'),
            apellido: const Value('Sistema'),
            email: const Value('admin@local'),
            rol: const Value('Admin'),
            estado: const Value('Activo'),
          ),
        );
  }
}
