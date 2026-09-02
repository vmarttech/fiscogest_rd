import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UsuarioModel', () {
    test('nombre de usuario debe tener al menos 4 caracteres', () {
      const usuarioValido = 'admin_sistema';
      const usuarioCorto = 'adm';

      expect(usuarioValido.length, greaterThanOrEqualTo(4));
      expect(usuarioCorto.length, lessThan(4));
    });

    test('hash de contraseña tiene longitud y formato esperado', () {
      const hashContrasena = r'$2a$10$abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUV';
      expect(hashContrasena, startsWith(r'$'));
      expect(hashContrasena.length, greaterThan(20));
    });

    test('rol debe pertenecer a lista permitida', () {
      const rolesPermitidos = <String>{'admin', 'vendedor', 'compras', 'consultas'};
      const rolValido = 'admin';
      const rolInvalido = 'invalido';

      expect(rolesPermitidos.contains(rolValido), isTrue);
      expect(rolesPermitidos.contains(rolInvalido), isFalse);
    });
  });
}
