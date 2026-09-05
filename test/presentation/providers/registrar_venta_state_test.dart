import 'package:flutter_test/flutter_test.dart';

class RegistrarVentaState {

  const RegistrarVentaState({
    this.subtotal = 0.0,
    this.itbis = 0.0,
    this.total = 0.0,
    this.montoDescuento = 0.0,
    this.tasaItbis = 0.18,
    this.estaProcesando = false,
  });
  final double subtotal;
  final double itbis;
  final double total;
  final double montoDescuento;
  final double tasaItbis;
  final bool estaProcesando;

  RegistrarVentaState copyWith({
    double? subtotal,
    double? itbis,
    double? total,
    double? montoDescuento,
    double? tasaItbis,
    bool? estaProcesando,
  }) {
    return RegistrarVentaState(
      subtotal: subtotal ?? this.subtotal,
      itbis: itbis ?? this.itbis,
      total: total ?? this.total,
      montoDescuento: montoDescuento ?? this.montoDescuento,
      tasaItbis: tasaItbis ?? this.tasaItbis,
      estaProcesando: estaProcesando ?? this.estaProcesando,
    );
  }
}

RegistrarVentaState recalcularTotales(RegistrarVentaState estado) {
  final itbis = estado.subtotal * estado.tasaItbis;
  final total = estado.subtotal + itbis - estado.montoDescuento;
  return estado.copyWith(itbis: itbis, total: total);
}

void main() {
  group('RegistrarVentaState — Pruebas de Estado', () {
    group('Estado Inicial', () {
      test('valores por defecto son correctos', () {
        const estado = RegistrarVentaState();
        expect(estado.subtotal, 0.0);
        expect(estado.itbis, 0.0);
        expect(estado.total, 0.0);
        expect(estado.montoDescuento, 0.0);
        expect(estado.tasaItbis, 0.18);
        expect(estado.estaProcesando, isFalse);
      });
    });

    group('copyWith — Inmutabilidad', () {
      test('cambia solo subtotal, resto permanece igual', () {
        const estadoOriginal = RegistrarVentaState();
        final estadoNuevo = estadoOriginal.copyWith(subtotal: 100.0);
        expect(estadoNuevo.subtotal, 100.0);
        expect(estadoNuevo.itbis, 0.0);
        expect(estadoNuevo.tasaItbis, 0.18);
        expect(estadoNuevo.estaProcesando, isFalse);
      });

      test('cambia tasaItbis a 16% correctamente', () {
        const estadoOriginal = RegistrarVentaState();
        final estadoNuevo = estadoOriginal.copyWith(tasaItbis: 0.16);
        expect(estadoNuevo.tasaItbis, 0.16);
      });

      test('estado original NO se modifica', () {
        const estadoOriginal = RegistrarVentaState(subtotal: 50.0);
        final estadoNuevo = estadoOriginal.copyWith(subtotal: 200.0);
        expect(estadoOriginal.subtotal, 50.0);
        expect(estadoNuevo.subtotal, 200.0);
      });
    });

    group('recalcularTotales — Fórmula oficial Ventas', () {
      test('subtotal 100, tasa 18%, sin descuento → ITBIS 18, Total 118', () {
        const estado = RegistrarVentaState(subtotal: 100.0, tasaItbis: 0.18);
        final resultado = recalcularTotales(estado);
        expect(resultado.itbis, 18.0);
        expect(resultado.total, 118.0);
      });

      test('subtotal 200, tasa 16%, descuento 10 → ITBIS 32, Total 222', () {
        const estado = RegistrarVentaState(
          subtotal: 200.0,
          tasaItbis: 0.16,
          montoDescuento: 10.0,
        );
        final resultado = recalcularTotales(estado);
        expect(resultado.itbis, 32.0);
        expect(resultado.total, 222.0);
      });

      test('subtotal 0 → ITBIS 0, Total 0', () {
        const estado = RegistrarVentaState(subtotal: 0.0);
        final resultado = recalcularTotales(estado);
        expect(resultado.itbis, 0.0);
        expect(resultado.total, 0.0);
      });
    });
  });
}
