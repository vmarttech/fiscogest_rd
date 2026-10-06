import 'dart:convert';
import 'dart:math';
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

  static const _prefix = 's1\$';

  /// Formato nuevo: s1\$saltHex\$sha256hex
  /// Legado: 64 hex (sha256 del password solo).
  static String hashPassword(String plain) {
    final salt = _randomSalt();
    final digest = sha256.convert(utf8.encode('$salt$plain')).toString();
    return '$_prefix$salt\$$digest';
  }

  static String _randomSalt() {
    final r = Random.secure();
    final bytes = List<int>.generate(8, (_) => r.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static bool verifyPassword(String plain, String stored) {
    final s = stored.trim();
    if (s.isEmpty) return false;
    if (s.startsWith(_prefix)) {
      final parts = s.split('\$');
      // s1, salt, digest
      if (parts.length != 3) return false;
      final salt = parts[1];
      final digest = parts[2];
      final check = sha256.convert(utf8.encode('$salt$plain')).toString();
      return check == digest;
    }
    // Legado SHA-256 sin salt
    final legacy = sha256.convert(utf8.encode(plain)).toString();
    return s == legacy;
  }

  static bool needsRehash(String stored) {
    return !stored.trim().startsWith(_prefix);
  }


  Future<AuthResult?> login(String username, String password) async {
    final u = username.trim();
    if (u.isEmpty || password.isEmpty) return null;

    final row = await (_db.select(
      _db.usuariosTable,
    )..where((t) => t.username.equals(u))).getSingleOrNull();
    if (row == null) return null;
    if (row.estado.toLowerCase() != 'activo') return null;
    if (!verifyPassword(password, row.passwordHash)) return null;
    final updates = UsuariosTableCompanion(
      fechaUltimoAcceso: Value(DateTime.now()),
      passwordHash: needsRehash(row.passwordHash)
          ? Value(hashPassword(password))
          : const Value.absent(),
    );
    await (_db.update(
      _db.usuariosTable,
    )..where((t) => t.id.equals(row.id))).write(updates);


    // Contraseña solo se valida como hash; no se acepta texto plano.

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

  /// Crea la cuenta administradora en una instalación sin usuarios.
  Future<AuthResult> crearCuentaInicial({
    required String username,
    required String password,
    required String pregunta,
    required String respuesta,
  }) async {
    final user = username.trim();
    final pass = password;
    final preg = pregunta.trim();
    final resp = respuesta.trim();
    if (user.length < 3) {
      throw const FormatException(
        'El usuario debe tener al menos 3 caracteres',
      );
    }
    if (user.toLowerCase() == 'admin') {
      throw const FormatException('No puede usar "admin" como usuario');
    }
    if (pass.length < 6) {
      throw const FormatException(
        'La contraseña debe tener al menos 6 caracteres',
      );
    }
    if (preg.isEmpty) {
      throw const FormatException('Indique una pregunta de recuperación');
    }
    if (resp.length < 3) {
      throw const FormatException(
        'La respuesta debe tener al menos 3 caracteres',
      );
    }
    final id = await _db.transaction(() async {
      final existentes = await _db.select(_db.usuariosTable).get();
      if (existentes.isNotEmpty) {
        throw const FormatException(
          'La configuración inicial ya está completada',
        );
      }
      if (await buscarPorUsername(user) != null) {
        throw const FormatException('Ese nombre de usuario ya existe');
      }
      return _db
          .into(_db.usuariosTable)
          .insert(
            UsuariosTableCompanion.insert(
              nombre: user,
              username: user,
              passwordHash: hashPassword(pass),
              apellido: const Value(''),
              email: const Value(null),
              rol: const Value('Admin'),
              estado: const Value('Activo'),
              requiereSetupInicial: const Value(false),
              preguntaRecuperacion: Value(preg),
              respuestaHash: Value(hashPassword(resp.toLowerCase())),
            ),
          );
    });
    return AuthResult(
      usuarioId: id,
      username: user,
      nombre: user,
      rol: 'Admin',
      estado: 'Activo',
      requiereSetupInicial: false,
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
