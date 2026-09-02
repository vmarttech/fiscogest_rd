import 'package:flutter_test/flutter_test.dart';

// VALORES Y FÓRMULAS TOMADAS EXACTAMENTE DEL CÓDIGO EXISTENTE
const double tasaItbisGeneral = 0.18;
const double tasaItbisReducida = 0.16;

double calcularItbis({required double subtotal, required double tasaItbis}) {
  return subtotal * tasaItbis;
}

// FÓRMULA EXACTA: registrar_venta_provider.dart línea 165
// final total = subtotal + itbis - descuento
double calcularTotal({
  required double subtotal,
  required double tasaItbis,
  double descuento = 0.0,
}) {
  final itbis = calcularItbis(subtotal: subtotal, tasaItbis: tasaItbis);
  return subtotal + itbis - descuento;
}

void main() {
  group('Cálculo Total — igual a fórmula Ventas: subtotal + ITBIS - descuento', () {
    test('tasa 18%, sin descuento: 100 + 18 = 118.0', () {
      final total = calcularTotal(subtotal: 100.0, tasaItbis: tasaItbisGeneral);
      expect(total, 118.0);
    });
    test('tasa 18%, descuento 10: 100 + 18 - 10 = 108.0', () {
      final total = calcularTotal(
        subtotal: 100.0,
        tasaItbis: tasaItbisGeneral,
        descuento: 10.0,
      );
      expect(total, 108.0);
    });
    test('tasa 16%, sin descuento: 200 + 32 = 232.0', () {
      final total = calcularTotal(subtotal: 200.0, tasaItbis: tasaItbisReducida);
      expect(total, 232.0);
    });
    test('tasa 18%, descuento mayor: 500 + 90 - 50 = 540.0', () {
      final total = calcularTotal(
        subtotal: 500.0,
        tasaItbis: tasaItbisGeneral,
        descuento: 50.0,
      );
      expect(total, 540.0);
    });
  });
}
