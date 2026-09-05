import 'package:flutter_test/flutter_test.dart';

class Producto {

  Producto({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.stock,
  });
  final int id;
  final String codigo;
  final String nombre;
  final double? stock;

  Producto copyWith({
    int? id,
    String? codigo,
    String? nombre,
    double? stock,
  }) {
    return Producto(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      stock: stock ?? this.stock,
    );
  }
}

// LÓGICA EXACTA TOMADA DE:
// lib/core/servicios_transversales/operaciones_salida_service.dart
bool puedeDescontar(Producto producto, double cantidad) {
  final double stockActual = producto.stock ?? 0.0;
  return stockActual >= cantidad && cantidad > 0;
}

Producto descontarStock(Producto producto, double cantidad) {
  final double stockActual = producto.stock ?? 0.0;
  final double nuevoStock = stockActual - cantidad;
  return producto.copyWith(stock: nuevoStock);
}

void main() {
  group('OperacionesSalidaService', () {
    final productoBase = Producto(
      id: 1,
      codigo: 'PRD-001',
      nombre: 'Producto Prueba',
      stock: 10.0,
    );

    group('puedeDescontar — Validación antes de vender', () {
      test('stock 10, cantidad 5 → puede = true', () {
        expect(puedeDescontar(productoBase, 5.0), isTrue);
      });

      test('stock 10, cantidad 10 → puede = true (igual)', () {
        expect(puedeDescontar(productoBase, 10.0), isTrue);
      });

      test('stock 10, cantidad 11 → puede = false (insuficiente)', () {
        expect(puedeDescontar(productoBase, 11.0), isFalse);
      });

      test('cantidad 0 → puede = false (inválida)', () {
        expect(puedeDescontar(productoBase, 0.0), isFalse);
      });

      test('cantidad negativa → puede = false (inválida)', () {
        expect(puedeDescontar(productoBase, -3.0), isFalse);
      });

      test('stock nulo (constructor) → se trata como 0 → puede = false', () {
        final productoSinStock = Producto(
          id: 2,
          codigo: 'PRD-002',
          nombre: 'Producto Sin Stock',
          stock: null,
        );
        expect(puedeDescontar(productoSinStock, 1.0), isFalse);
      });
    });

    group('descontarStock — Cálculo de nuevo stock', () {
      test('stock 10 - cantidad 3 → nuevo stock = 7.0', () {
        final resultado = descontarStock(productoBase, 3.0);
        expect(resultado.stock, 7.0);
      });

      test('stock 10 - cantidad 10 → nuevo stock = 0.0', () {
        final resultado = descontarStock(productoBase, 10.0);
        expect(resultado.stock, 0.0);
      });

      test('stock nulo (constructor) - cantidad 5 → nuevo stock = -5.0', () {
        final productoSinStock = Producto(
          id: 2,
          codigo: 'PRD-002',
          nombre: 'Producto Sin Stock',
          stock: null,
        );
        final resultado = descontarStock(productoSinStock, 5.0);
        expect(resultado.stock, -5.0);
      });

      test('producto original NO se modifica', () {
        final stockOriginal = productoBase.stock;
        descontarStock(productoBase, 7.0);
        expect(productoBase.stock, stockOriginal);
      });
    });
  });
}
