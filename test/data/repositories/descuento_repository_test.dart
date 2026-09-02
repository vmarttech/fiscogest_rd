import 'package:flutter_test/flutter_test.dart';

// LÍMITES DE DESCUENTO APLICADOS EN EL SISTEMA
// Porcentaje: 0% a 100%
const double descuentoMaximo = 1.0;
const double descuentoMinimo = 0.0;

bool validarPorcentajeDescuento(double porcentaje) {
  return porcentaje >= descuentoMinimo && porcentaje <= descuentoMaximo;
}

double aplicarDescuento({required double monto, required double porcentaje}) {
  if (!validarPorcentajeDescuento(porcentaje)) {
    throw ArgumentError.value(porcentaje, 'porcentaje', 'Descuento fuera de rango 0.0 a 1.0');
  }
  return monto * (1 - porcentaje);
}

void main() {
  group('Repositorio de Descuentos — Validación y aplicación', () {
    group('Validación de rango', () {
      test('0% → válido', () {
        expect(validarPorcentajeDescuento(0.0), isTrue);
      });

      test('10% → válido', () {
        expect(validarPorcentajeDescuento(0.10), isTrue);
      });

      test('50% → válido', () {
        expect(validarPorcentajeDescuento(0.50), isTrue);
      });

      test('100% → válido', () {
        expect(validarPorcentajeDescuento(1.0), isTrue);
      });

      test('porcentaje negativo → inválido', () {
        expect(validarPorcentajeDescuento(-0.05), isFalse);
      });

      test('mayor a 100% → inválido', () {
        expect(validarPorcentajeDescuento(1.01), isFalse);
      });
    });

    group('Aplicación de descuento', () {
      test('monto 100, descuento 10% → queda 90.0', () {
        final resultado = aplicarDescuento(monto: 100.0, porcentaje: 0.10);
        expect(resultado, 90.0);
      });

      test('monto 500, descuento 0% → queda 500.0', () {
        final resultado = aplicarDescuento(monto: 500.0, porcentaje: 0.0);
        expect(resultado, 500.0);
      });

      test('monto 200, descuento 50% → queda 100.0', () {
        final resultado = aplicarDescuento(monto: 200.0, porcentaje: 0.50);
        expect(resultado, 100.0);
      });

      test('descuento inválido → lanza error', () {
        expect(() => aplicarDescuento(monto: 100.0, porcentaje: 1.5), throwsArgumentError);
      });
    });
  });
}
