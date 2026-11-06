import 'package:flutter_test/flutter_test.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/promocion.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/promocion/aplicar_promocion.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/promocion/validar_promocion.dart';

void main() {
  const aplicador = AplicarPromocion();

  const promocion = Promocion(
    id: 1,
    nombre: 'Lleve 2 y pague 1',
    descripcion: 'Promoción 2x1',
    tipo: 'lleve2Pague1',
    valor: 0,
  );

  group('AplicarPromocion - Lleve 2 y pague 1', () {
    test('calcula cada línea con su propio precio', () {
      final resultado = aplicador.ejecutar(
        promocion: promocion,
        lineas: const [
          LineaVenta(productoId: 1, cantidad: 4, precioUnitario: 100),
          LineaVenta(productoId: 2, cantidad: 2, precioUnitario: 250),
        ],
      );

      // Dos unidades gratis a RD$100 y una a RD$250.
      expect(resultado.montoDescuento, 450);
      expect(resultado.tipoPromocionAplicada, 'lleve2Pague1');
    });

    test('con tres unidades solamente regala una', () {
      final resultado = aplicador.ejecutar(
        promocion: promocion,
        lineas: const [
          LineaVenta(productoId: 1, cantidad: 3, precioUnitario: 100),
        ],
      );

      expect(resultado.montoDescuento, 100);
    });

    test('no combina unidades de líneas diferentes', () {
      final resultado = aplicador.ejecutar(
        promocion: promocion,
        lineas: const [
          LineaVenta(productoId: 1, cantidad: 1, precioUnitario: 100),
          LineaVenta(productoId: 2, cantidad: 1, precioUnitario: 250),
        ],
      );

      expect(resultado.montoDescuento, 0);
    });

    test('maneja cantidades fraccionarias sin regalar unidades parciales', () {
      final resultado = aplicador.ejecutar(
        promocion: promocion,
        lineas: const [
          LineaVenta(productoId: 1, cantidad: 2.5, precioUnitario: 100),
        ],
      );

      expect(resultado.montoDescuento, 100);
    });

    test('no calcula descuentos sobre cantidades o precios no positivos', () {
      final resultado = aplicador.ejecutar(
        promocion: promocion,
        lineas: const [
          LineaVenta(productoId: 1, cantidad: -2, precioUnitario: 100),
          LineaVenta(productoId: 2, cantidad: 2, precioUnitario: 0),
        ],
      );

      expect(resultado.montoDescuento, 0);
    });
  });

  group('AplicarPromocion - segmentación', () {
    const porcentaje = 10.0;

    Promocion crearPromocion({
      List<int> productoIds = const [],
      List<int> categoriaIds = const [],
    }) {
      return Promocion(
        id: 10,
        nombre: 'Descuento segmentado',
        descripcion: 'Prueba de segmentación',
        tipo: 'porcentaje',
        valor: porcentaje,
        productoIds: productoIds,
        categoriaIds: categoriaIds,
      );
    }

    test('sin filtros aplica a todos los productos', () {
      final resultado = aplicador.ejecutar(
        promocion: crearPromocion(),
        lineas: const [
          LineaVenta(productoId: 1, cantidad: 1, precioUnitario: 100),
          LineaVenta(productoId: 2, cantidad: 1, precioUnitario: 200),
        ],
      );

      expect(resultado.montoDescuento, 30);
    });

    test('con filtro de productos solo descuenta esos productos', () {
      final resultado = aplicador.ejecutar(
        promocion: crearPromocion(productoIds: [1]),
        lineas: const [
          LineaVenta(productoId: 1, cantidad: 1, precioUnitario: 100),
          LineaVenta(productoId: 2, cantidad: 1, precioUnitario: 200),
        ],
      );

      expect(resultado.montoDescuento, 10);
    });

    test('con filtro de categorías solo descuenta esa categoría', () {
      final resultado = aplicador.ejecutar(
        promocion: crearPromocion(categoriaIds: [7]),
        lineas: const [
          LineaVenta(
            productoId: 1,
            categoriaId: 7,
            cantidad: 1,
            precioUnitario: 100,
          ),
          LineaVenta(
            productoId: 2,
            categoriaId: 8,
            cantidad: 1,
            precioUnitario: 200,
          ),
        ],
      );

      expect(resultado.montoDescuento, 10);
    });

    test('con ambos filtros acepta coincidencia por producto o categoría', () {
      final resultado = aplicador.ejecutar(
        promocion: crearPromocion(productoIds: [1], categoriaIds: [7]),
        lineas: const [
          LineaVenta(
            productoId: 1,
            categoriaId: 8,
            cantidad: 1,
            precioUnitario: 100,
          ),
          LineaVenta(
            productoId: 2,
            categoriaId: 7,
            cantidad: 1,
            precioUnitario: 200,
          ),
          LineaVenta(
            productoId: 3,
            categoriaId: 8,
            cantidad: 1,
            precioUnitario: 300,
          ),
        ],
      );

      // Participan las dos primeras líneas, no la tercera.
      expect(resultado.montoDescuento, 30);
    });

    test('no aplica si ningún producto coincide con los filtros', () {
      final resultado = aplicador.ejecutar(
        promocion: crearPromocion(productoIds: [99], categoriaIds: [99]),
        lineas: const [
          LineaVenta(
            productoId: 1,
            categoriaId: 7,
            cantidad: 1,
            precioUnitario: 100,
          ),
        ],
      );

      expect(resultado.montoDescuento, 0);
      expect(resultado.tipoPromocionAplicada, 'ninguna');
    });

    test('los mínimos se calculan solo con las líneas elegibles', () {
      const promocion = Promocion(
        id: 11,
        nombre: 'Mínimo segmentado',
        descripcion: 'Prueba de mínimos',
        tipo: 'porcentaje',
        valor: 10,
        productoIds: [1],
        minimoCantidad: 2,
        minimoMonto: 200,
      );

      final resultado = aplicador.ejecutar(
        promocion: promocion,
        lineas: const [
          LineaVenta(productoId: 1, cantidad: 1, precioUnitario: 100),
          LineaVenta(productoId: 2, cantidad: 10, precioUnitario: 500),
        ],
      );

      // El producto 2 no puede completar los mínimos del producto 1.
      expect(resultado.montoDescuento, 0);
      expect(resultado.tipoPromocionAplicada, 'ninguna');
    });
  });
}
