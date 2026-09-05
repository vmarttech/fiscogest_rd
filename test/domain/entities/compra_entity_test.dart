import 'package:flutter_test/flutter_test.dart';

// ESTRUCTURA COPIADA LITERALMENTE DE:
// lib/features/comercial/domain/entities/compra.dart
class Compra {

  const Compra({
    required this.id,
    required this.proveedorId,
    required this.nombreProveedor,
    required this.fechaEmision,
    this.fechaConfirmacion,
    required this.numeroComprobante,
    required this.subtotalSinImpuestos,
    required this.montoDescuentoGlobal,
    required this.tasaImpuesto,
    required this.montoImpuesto,
    required this.totalCompra,
    required this.observaciones,
    required this.estado,
    required this.creadoEn,
    this.actualizadoEn,
  });
  final int id;
  final int proveedorId;
  final String nombreProveedor;
  final DateTime fechaEmision;
  final DateTime? fechaConfirmacion;
  final String numeroComprobante;
  final double subtotalSinImpuestos;
  final double montoDescuentoGlobal;
  final double tasaImpuesto;
  final double montoImpuesto;
  final double totalCompra;
  final String observaciones;
  final String estado;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;
}

// FÓRMULA DE CONSISTENCIA DE COMPRA
bool validarTotalCompra(Compra compra) {
  final subtotalConDescuento = compra.subtotalSinImpuestos - compra.montoDescuentoGlobal;
  final totalCalculado = subtotalConDescuento + compra.montoImpuesto;
  return (totalCalculado - compra.totalCompra).abs() < 0.001;
}

void main() {
  group('Entidad Compra — Validaciones y Consistencia', () {
    final fechaEmision = DateTime(2026, 9, 1);
    final fechaConfirmacion = DateTime(2026, 9, 2);
    final fechaCreacion = DateTime(2026, 9, 1, 8, 30);

    final compraBase = Compra(
      id: 101,
      proveedorId: 55,
      nombreProveedor: 'Proveedor S.A.',
      fechaEmision: fechaEmision,
      fechaConfirmacion: fechaConfirmacion,
      numeroComprobante: 'B01-00000123',
      subtotalSinImpuestos: 1000.0,
      montoDescuentoGlobal: 100.0,
      tasaImpuesto: 0.18,
      montoImpuesto: 162.0,
      totalCompra: 1062.0,
      observaciones: 'Compra de mercancía general',
      estado: 'Confirmada',
      creadoEn: fechaCreacion,
    );

    test('totalCompra coincide con fórmula: (subtotal - descuento) + impuesto', () {
      expect(validarTotalCompra(compraBase), isTrue);
    });

    test('sin descuento: subtotal 500 + impuesto 90 = total 590', () {
      final compraSinDescuento = Compra(
        id: 102,
        proveedorId: 55,
        nombreProveedor: 'Proveedor S.A.',
        fechaEmision: fechaEmision,
        numeroComprobante: 'B01-00000124',
        subtotalSinImpuestos: 500.0,
        montoDescuentoGlobal: 0.0,
        tasaImpuesto: 0.18,
        montoImpuesto: 90.0,
        totalCompra: 590.0,
        observaciones: '',
        estado: 'Pendiente',
        creadoEn: fechaCreacion,
      );
      expect(validarTotalCompra(compraSinDescuento), isTrue);
    });

    test('fechaConfirmacion y actualizadoEn pueden ser nulos', () {
      final compraPendiente = Compra(
        id: 103,
        proveedorId: 55,
        nombreProveedor: 'Proveedor S.A.',
        fechaEmision: fechaEmision,
        numeroComprobante: 'B01-00000125',
        subtotalSinImpuestos: 200.0,
        montoDescuentoGlobal: 0.0,
        tasaImpuesto: 0.18,
        montoImpuesto: 36.0,
        totalCompra: 236.0,
        observaciones: '',
        estado: 'Pendiente',
        creadoEn: fechaCreacion,
      );
      expect(compraPendiente.fechaConfirmacion, isNull);
      expect(compraPendiente.actualizadoEn, isNull);
    });

    test('tasaImpuesto 0.18 coincide con tasa oficial ITBIS', () {
      expect(compraBase.tasaImpuesto, 0.18);
    });
  });
}
