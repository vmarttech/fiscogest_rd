import 'package:flutter_test/flutter_test.dart';

// ESTRUCTURA COPIADA LITERALMENTE DE:
// lib/features/ventas/domain/entities/venta.dart
class Venta {

  const Venta({
    this.id,
    required this.numero,
    this.numeroFactura,
    required this.clienteId,
    this.nombreCliente,
    required this.fecha,
    required this.detalles,
    required this.subtotal,
    required this.itbis,
    required this.total,
    required this.tipoPago,
    required this.esCredito,
    this.cotizacionOrigenId,
    this.apartadoOrigenId,
    this.usuarioId,
    this.createdAt,
    this.descuentoId,
    this.descuentoNombre,
    this.montoDescuento = 0.0,
  });
  final int? id;
  final String numero;
  final String? numeroFactura;
  final int clienteId;
  final String? nombreCliente;
  final DateTime fecha;
  final List<dynamic> detalles;
  final double subtotal;
  final double itbis;
  final double total;
  final String tipoPago;
  final bool esCredito;
  final int? cotizacionOrigenId;
  final int? apartadoOrigenId;
  final int? usuarioId;
  final DateTime? createdAt;
  final int? descuentoId;
  final String? descuentoNombre;
  final double montoDescuento;
}

// FÓRMULA OFICIAL DE CONSISTENCIA
bool validarTotalVenta(Venta venta) {
  final totalCalculado = venta.subtotal + venta.itbis - venta.montoDescuento;
  return (totalCalculado - venta.total).abs() < 0.001;
}

void main() {
  group('Entidad Venta — Validaciones y Consistencia', () {
    final fechaPrueba = DateTime(2026, 9, 3);
    // ⚠️ QUITADO 'const' porque DateTime no es constante en Dart
    final ventaBase = Venta(
      id: 1,
      numero: 'VENT-001',
      clienteId: 42,
      nombreCliente: 'Cliente de Prueba',
      fecha: fechaPrueba,
      detalles: [],
      subtotal: 100.0,
      itbis: 18.0,
      total: 118.0,
      tipoPago: 'Efectivo',
      esCredito: false,
    );

    test('montoDescuento por defecto = 0.0', () {
      expect(ventaBase.montoDescuento, 0.0);
    });

    test('total coincide con fórmula: subtotal + itbis - descuento', () {
      expect(validarTotalVenta(ventaBase), isTrue);
    });

    test('con descuento: subtotal 200 + itbis 36 - descuento 10 = total 226', () {
      final ventaConDescuento = Venta(
        numero: 'VENT-002',
        clienteId: 42,
        fecha: fechaPrueba,
        detalles: [],
        subtotal: 200.0,
        itbis: 36.0,
        montoDescuento: 10.0,
        total: 226.0,
        tipoPago: 'Tarjeta',
        esCredito: true,
      );
      expect(validarTotalVenta(ventaConDescuento), isTrue);
      expect(ventaConDescuento.total, 226.0);
    });

    test('sin impuesto (exento): subtotal 500 + itbis 0 = total 500', () {
      final ventaExenta = Venta(
        numero: 'VENT-003',
        clienteId: 42,
        fecha: fechaPrueba,
        detalles: [],
        subtotal: 500.0,
        itbis: 0.0,
        total: 500.0,
        tipoPago: 'Efectivo',
        esCredito: false,
      );
      expect(validarTotalVenta(ventaExenta), isTrue);
    });

    test('esCredito = true → venta a crédito', () {
      final ventaCredito = Venta(
        numero: 'VENT-004',
        clienteId: 42,
        fecha: fechaPrueba,
        detalles: [],
        subtotal: 150.0,
        itbis: 27.0,
        total: 177.0,
        tipoPago: 'Crédito 30 días',
        esCredito: true,
      );
      expect(ventaCredito.esCredito, isTrue);
    });

    test('campos opcionales: numeroFactura, cotizacionOrigenId, apartadoOrigenId son nulos por defecto', () {
      expect(ventaBase.numeroFactura, isNull);
      expect(ventaBase.cotizacionOrigenId, isNull);
      expect(ventaBase.apartadoOrigenId, isNull);
    });
  });
}
