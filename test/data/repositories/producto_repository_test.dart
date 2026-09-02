import 'package:flutter_test/flutter_test.dart';

// VALIDACIONES TOMADAS DE:
// lib/features/comercial/domain/repositories/i_producto_repository.dart
bool validarDatosProducto({
  required String codigo,
  required String nombre,
  required double precio,
  required int stock,
}) {
  if (codigo.trim().isEmpty) return false;
  if (nombre.trim().isEmpty) return false;
  if (precio < 0) return false;
  if (stock < 0) return false;
  return true;
}

void main() {
  group('Repositorio de Productos — Validaciones antes de guardar', () {
    test('datos completos y válidos → retorna true', () {
      final valido = validarDatosProducto(
        codigo: 'PRD-001',
        nombre: 'Producto Prueba',
        precio: 150.0,
        stock: 25,
      );
      expect(valido, isTrue);
    });

    test('código vacío → inválido', () {
      final valido = validarDatosProducto(
        codigo: '',
        nombre: 'Producto Prueba',
        precio: 150.0,
        stock: 25,
      );
      expect(valido, isFalse);
    });

    test('nombre vacío → inválido', () {
      final valido = validarDatosProducto(
        codigo: 'PRD-001',
        nombre: '',
        precio: 150.0,
        stock: 25,
      );
      expect(valido, isFalse);
    });

    test('precio negativo → inválido', () {
      final valido = validarDatosProducto(
        codigo: 'PRD-001',
        nombre: 'Producto Prueba',
        precio: -10.0,
        stock: 25,
      );
      expect(valido, isFalse);
    });

    test('stock negativo → inválido', () {
      final valido = validarDatosProducto(
        codigo: 'PRD-001',
        nombre: 'Producto Prueba',
        precio: 150.0,
        stock: -5,
      );
      expect(valido, isFalse);
    });
  });
}
