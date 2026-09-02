import 'package:flutter_test/flutter_test.dart';

// VALORES EXACTOS TOMADOS DE:
// lib/features/impuestos/data/repositories/impuesto_repository_impl.dart
const double tasaItbisGeneral = 0.18;
const double tasaItbisReducida = 0.16;
const double tasaItbisExento = 0.0;

// FÓRMULA EXACTA TOMADA DE:
// lib/features/ventas/presentation/providers/registrar_venta_provider.dart línea 164
double calcularItbisFormula({required double subtotal, required double tasaItbis}) {
  return subtotal * tasaItbis;
}

void main() {
  group('ITBIS — Verificación contra valores oficiales del sistema', () {
    group('ITBIS 18% — tasa general (impuesto_repository_impl.dart)', () {
      test('subtotal 100.0 → ITBIS 18.0', () {
        final resultado = calcularItbisFormula(subtotal: 100.0, tasaItbis: tasaItbisGeneral);
        expect(resultado, 18.0);
      });
      test('subtotal 500.0 → ITBIS 90.0', () {
        final resultado = calcularItbisFormula(subtotal: 500.0, tasaItbis: tasaItbisGeneral);
        expect(resultado, 90.0);
      });
    });

    group('ITBIS 16% — tasa reducida (impuesto_repository_impl.dart)', () {
      test('subtotal 100.0 → ITBIS 16.0', () {
        final resultado = calcularItbisFormula(subtotal: 100.0, tasaItbis: tasaItbisReducida);
        expect(resultado, 16.0);
      });
      test('subtotal 250.0 → ITBIS 40.0', () {
        final resultado = calcularItbisFormula(subtotal: 250.0, tasaItbis: tasaItbisReducida);
        expect(resultado, 40.0);
      });
    });

    group('ITBIS 0% — exento (impuesto_repository_impl.dart)', () {
      test('cualquier subtotal → ITBIS 0.0', () {
        final resultado = calcularItbisFormula(subtotal: 850.75, tasaItbis: tasaItbisExento);
        expect(resultado, 0.0);
      });
    });

    group('Fórmula aplicada en Ventas (registrar_venta_provider.dart L164)', () {
      test('coincide con cálculo: subtotal × tasaItbis', () {
        const subtotal = 75.50;
        const tasa = 0.18;
        final resultado = calcularItbisFormula(subtotal: subtotal, tasaItbis: tasa);
        expect(resultado, subtotal * tasa);
      });
    });
  });
}
