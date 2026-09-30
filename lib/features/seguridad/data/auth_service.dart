import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';

class AuthResult {
  const AuthResult({
    required this.usuarioId,
    required this.username,
    required this.nombre,
    required this.rol,
    required this.estado,
    required this.requiereSetupInicial,
  });

  final int usuarioId;
  final String username;
  final String nombre;
  final String rol;
  final String estado;
  final bool requiereSetupInicial;
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

    final row = await (_db.select(
      _db.usuariosTable,
    )..where((t) => t.username.equals(u))).getSingleOrNull();
    if (row == null) return null;
    if (row.estado.toLowerCase() != 'activo') return null;

    final hashed = hashPassword(password);
    final ok = row.passwordHash == hashed || row.passwordHash == password;
    if (!ok) return null;

    if (row.passwordHash == password) {
      await (_db.update(_db.usuariosTable)..where((t) => t.id.equals(row.id)))
          .write(UsuariosTableCompanion(passwordHash: Value(hashed)));
    }

    await (_db.update(
      _db.usuariosTable,
    )..where((t) => t.id.equals(row.id))).write(
      UsuariosTableCompanion(fechaUltimoAcceso: Value(DateTime.now())),
    );

    // Credenciales de fábrica siguen siendo provisionales
    final provisional =
        row.requiereSetupInicial || row.username.toLowerCase() == 'admin';

    return AuthResult(
      usuarioId: row.id,
      username: row.username,
      nombre: row.nombre,
      rol: row.rol,
      estado: row.estado,
      requiereSetupInicial: provisional,
    );
  }

  Future<void> ensureAdminSeed() async {
    final existentes = await _db.select(_db.usuariosTable).get();
    if (existentes.isNotEmpty) return;

    await _db
        .into(_db.usuariosTable)
        .insert(
          UsuariosTableCompanion.insert(
            nombre: 'Administrador',
            username: 'admin',
            passwordHash: hashPassword('admin'),
            apellido: const Value('Sistema'),
            email: const Value('admin@local'),
            rol: const Value('Admin'),
            estado: const Value('Activo'),
            requiereSetupInicial: const Value(true),
          ),
        );
  }

  /// Setup obligatorio: nuevo usuario, clave y pregunta de recuperación.
  Future<String?> completarSetupInicial({
    required int usuarioId,
    required String nuevoUsername,
    required String nuevaPassword,
    required String pregunta,
    required String respuesta,
  }) async {
    final user = nuevoUsername.trim();
    final pass = nuevaPassword;
    final preg = pregunta.trim();
    final resp = respuesta.trim();

    if (user.length < 3) return 'El usuario debe tener al menos 3 caracteres';
    if (user.toLowerCase() == 'admin') {
      return 'No puede usar "admin" como usuario';
    }
    if (pass.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    if (preg.isEmpty) return 'Indique una pregunta de recuperación';
    if (resp.length < 3) return 'La respuesta debe tener al menos 3 caracteres';

    final existe =
        await (_db.select(_db.usuariosTable)..where(
              (t) => t.username.equals(user) & t.id.isNotValue(usuarioId),
            ))
            .getSingleOrNull();
    if (existe != null) return 'Ese nombre de usuario ya existe';

    await (_db.update(
      _db.usuariosTable,
    )..where((t) => t.id.equals(usuarioId))).write(
      UsuariosTableCompanion(
        username: Value(user),
        passwordHash: Value(hashPassword(pass)),
        preguntaRecuperacion: Value(preg),
        respuestaHash: Value(hashPassword(resp.toLowerCase())),
        requiereSetupInicial: const Value(false),
      ),
    );
    return null;
  }

  Future<UsuarioData?> buscarPorUsername(String username) async {
    return (_db.select(
      _db.usuariosTable,
    )..where((t) => t.username.equals(username.trim()))).getSingleOrNull();
  }

  Future<String?> recuperarClave({
    required String username,
    required String respuesta,
    required String nuevaPassword,
  }) async {
    final row = await buscarPorUsername(username);
    if (row == null) return 'Usuario no encontrado';
    if (row.respuestaHash == null || (row.preguntaRecuperacion ?? '').isEmpty) {
      return 'Este usuario no tiene recuperación configurada';
    }
    final hash = hashPassword(respuesta.trim().toLowerCase());
    if (hash != row.respuestaHash) return 'Respuesta incorrecta';
    if (nuevaPassword.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }

    await (_db.update(
      _db.usuariosTable,
    )..where((t) => t.id.equals(row.id))).write(
      UsuariosTableCompanion(passwordHash: Value(hashPassword(nuevaPassword))),
    );
    return null;
  }
}
