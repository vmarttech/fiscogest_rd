import 'package:flutter_test/flutter_test.dart';

bool validarRnc(String rnc) {
  final limpio = rnc.trim();
  if (limpio.isEmpty) return false;
  if (!RegExp(r'^\d+$').hasMatch(limpio)) return false;
  return limpio.length == 9 || limpio.length == 11;
}

void main() {
  group('Validación de RNC y Cédula (República Dominicana)', () {
    test('RNC de 9 dígitos → válido = true', () {
      expect(validarRnc('123456789'), isTrue);
    });

    test('Cédula de 11 dígitos → válido = true', () {
      expect(validarRnc('00112345678'), isTrue);
    });

    test('8 dígitos → inválido = false', () {
      expect(validarRnc('12345678'), isFalse);
    });

    test('10 dígitos → inválido = false', () {
      expect(validarRnc('1234567890'), isFalse);
    });

    test('12 dígitos → inválido = false', () {
      expect(validarRnc('123456789012'), isFalse);
    });

    test('contiene letras → inválido = false', () {
      expect(validarRnc('12A456789'), isFalse);
    });

    test('cadena vacía → inválido = false', () {
      expect(validarRnc(''), isFalse);
    });

    test('espacios alrededor → se limpia y valida', () {
      expect(validarRnc(' 123456789 '), isTrue);
    });
  });
}
