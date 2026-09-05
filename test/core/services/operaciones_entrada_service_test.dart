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
// lib/core/servicios_transversales/operaciones_entrada_service.dart línea 18-20
Producto aumentarStock(Producto producto, double cantidad) {
  final double stockActual = producto.stock ?? 0.0;
  final double nuevoStock = stockActual + cantidad;
  return producto.copyWith(stock: nuevoStock);
}

void main() {
  group('OperacionesEntradaService — Aumentar Stock', () {
    final productoBase = Producto(
      id: 1,
      codigo: 'PRD-001',
      nombre: 'Producto Prueba',
      stock: 10.0,
    );

    test('stock 10 + cantidad 5 → nuevo stock = 15.0', () {
      final resultado = aumentarStock(productoBase, 5.0);
      expect(resultado.stock, 15.0);
    });

    test('stock 10 + cantidad 0 → stock permanece 10.0', () {
      final resultado = aumentarStock(productoBase, 0.0);
      expect(resultado.stock, 10.0);
    });

    test('stock nulo (constructor) → se trata como 0 + cantidad 7 → stock = 7.0', () {
      final productoSinStock = Producto(
        id: 2,
        codigo: 'PRD-002',
        nombre: 'Producto Sin Stock',
        stock: null,
      );
      final resultado = aumentarStock(productoSinStock, 7.0);
      expect(resultado.stock, 7.0);
    });

    test('stock 25.5 + cantidad 12.5 → stock = 38.0', () {
      final productoDecimal = productoBase.copyWith(stock: 25.5);
      final resultado = aumentarStock(productoDecimal, 12.5);
      expect(resultado.stock, 38.0);
    });

    test('producto original NO se modifica (inmutabilidad)', () {
      final stockOriginal = productoBase.stock;
      aumentarStock(productoBase, 100.0);
      expect(productoBase.stock, stockOriginal);
    });
  });
}
