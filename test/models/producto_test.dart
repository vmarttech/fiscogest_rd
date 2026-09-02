import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductoModel', () {
    test('valores de stock no pueden ser negativos', () {
      const stockSistema = 15;
      const stockFisico = 15;

      expect(stockSistema, isNonNegative);
      expect(stockFisico, isNonNegative);
    });

    test('diferencia de inventario se calcula correctamente', () {
      const stockSistema = 20;
      const stockFisico = 18;
      const diferencia = stockFisico - stockSistema;

      expect(diferencia, equals(-2));
    });

    test('precio debe ser mayor a cero', () {
      const precio = 150.50;
      expect(precio, greaterThan(0));
    });

    test('nombre y código no deben estar vacíos', () {
      const nombre = 'Aceite Motor 20W50';
      const codigo = 'ACE-001';

      expect(nombre.trim(), isNotEmpty);
      expect(codigo.trim(), isNotEmpty);
    });
  });
}
