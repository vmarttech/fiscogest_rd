import 'package:flutter_test/flutter_test.dart';

class VentaBorradorState {

  const VentaBorradorState({
    this.id,
    this.nombreCliente = '',
    this.subtotal = 0.0,
    this.itbis = 0.0,
    this.total = 0.0,
    this.observaciones,
  });
  final int? id;
  final String nombreCliente;
  final double subtotal;
  final double itbis;
  final double total;
  final String? observaciones;

  VentaBorradorState copyWith({
    int? id,
    String? nombreCliente,
    double? subtotal,
    double? itbis,
    double? total,
    String? observaciones,
  }) {
    return VentaBorradorState(
      id: id ?? this.id,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      subtotal: subtotal ?? this.subtotal,
      itbis: itbis ?? this.itbis,
      total: total ?? this.total,
      observaciones: observaciones ?? this.observaciones,
    );
  }
}

void main() {
  group('VentaBorradorState — Pruebas de Estado', () {
    group('Estado Inicial', () {
      test('valores por defecto son correctos', () {
        const estado = VentaBorradorState();
        expect(estado.id, isNull);
        expect(estado.nombreCliente, '');
        expect(estado.subtotal, 0.0);
        expect(estado.itbis, 0.0);
        expect(estado.total, 0.0);
        expect(estado.observaciones, isNull);
      });
    });

    group('copyWith — Inmutabilidad', () {
      test('asigna ID correctamente', () {
        const estadoOriginal = VentaBorradorState();
        final estadoNuevo = estadoOriginal.copyWith(id: 42);
        expect(estadoNuevo.id, 42);
        expect(estadoOriginal.id, isNull);
      });

      test('actualiza nombre de cliente', () {
        const estadoOriginal = VentaBorradorState();
        final estadoNuevo = estadoOriginal.copyWith(nombreCliente: 'Cliente S.A.');
        expect(estadoNuevo.nombreCliente, 'Cliente S.A.');
      });

      test('actualiza montos de venta', () {
        const estadoOriginal = VentaBorradorState();
        final estadoNuevo = estadoOriginal.copyWith(
          subtotal: 500.0,
          itbis: 90.0,
          total: 590.0,
        );
        expect(estadoNuevo.subtotal, 500.0);
        expect(estadoNuevo.itbis, 90.0);
        expect(estadoNuevo.total, 590.0);
      });

      test('agrega observaciones', () {
        const estadoOriginal = VentaBorradorState();
        final estadoNuevo = estadoOriginal.copyWith(observaciones: 'Entrega urgente');
        expect(estadoNuevo.observaciones, 'Entrega urgente');
      });

      test('estado original permanece intacto', () {
        const estadoOriginal = VentaBorradorState(nombreCliente: 'Original');
        final estadoNuevo = estadoOriginal.copyWith(nombreCliente: 'Modificado');
        expect(estadoOriginal.nombreCliente, 'Original');
        expect(estadoNuevo.nombreCliente, 'Modificado');
      });
    });
  });
}
