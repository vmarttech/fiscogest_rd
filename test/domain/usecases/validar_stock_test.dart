import 'package:flutter_test/flutter_test.dart';

bool validarStock({
  required int stockDisponible,
  required int cantidadSolicitada,
}) {
  if (stockDisponible < 0) return false;
  if (cantidadSolicitada <= 0) return false;
  return stockDisponible >= cantidadSolicitada;
}

void main() {
  group('Validación de Stock antes de transacción', () {
    test('stock 10, solicita 5 → disponible = true', () {
      final resultado = validarStock(stockDisponible: 10, cantidadSolicitada: 5);
      expect(resultado, isTrue);
    });

    test('stock 5, solicita 10 → insuficiente = false', () {
      final resultado = validarStock(stockDisponible: 5, cantidadSolicitada: 10);
      expect(resultado, isFalse);
    });

    test('stock igual a cantidad → disponible = true', () {
      final resultado = validarStock(stockDisponible: 7, cantidadSolicitada: 7);
      expect(resultado, isTrue);
    });

    test('stock negativo → inválido = false', () {
      final resultado = validarStock(stockDisponible: -3, cantidadSolicitada: 1);
      expect(resultado, isFalse);
    });

    test('cantidad solicitada cero → inválido = false', () {
      final resultado = validarStock(stockDisponible: 10, cantidadSolicitada: 0);
      expect(resultado, isFalse);
    });

    test('cantidad solicitada negativa → inválido = false', () {
      final resultado = validarStock(stockDisponible: 10, cantidadSolicitada: -2);
      expect(resultado, isFalse);
    });
  });
}
