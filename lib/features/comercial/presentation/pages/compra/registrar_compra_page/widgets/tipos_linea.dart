import 'package:flutter/material.dart';

class DetalleLinea {
  int? productoId;
  String nombreProducto = '';
  double cantidad = 0.0;
  double costoUnitario = 0.0;
  double fleteUnitario = 0.0;
  double seguroUnitario = 0.0;
  double arancelesUnitario = 0.0;

  /// Otros gastos REALES por unidad (flete aparte). NO poner aquí el ITBIS.
  double gastosUnitario = 0.0;
  double descuentoPorcentaje = 0.0;

  /// Tasa ITBIS de la línea (0.0 = plan simplificado).
  double tasaImpuestoLinea = 0.18;

  /// Gastos extra por unidad (sin ITBIS).
  double get gastosAsociadosUnitarios =>
      fleteUnitario + seguroUnitario + arancelesUnitario + gastosUnitario;

  /// Gastos extra de la línea completa.
  double get gastosAsociados => gastosAsociadosUnitarios * cantidad;

  /// Costo de adquisición unitario para inventario (sin ITBIS recuperable).
  double get costoReal => costoUnitario + gastosAsociadosUnitarios;

  double get importeBruto => cantidad * costoUnitario;
  double get montoDescuentoLinea => importeBruto * (descuentoPorcentaje / 100);
  double get subtotalLinea => importeBruto - montoDescuentoLinea;
  double get baseImponibleLinea => subtotalLinea;

  double get itbisLinea => baseImponibleLinea * tasaImpuestoLinea;

  /// Total a pagar de la línea = base + ITBIS + gastos reales (× cantidad).
  double get totalLinea => baseImponibleLinea + itbisLinea + gastosAsociados;
}

class ControladoresLinea {
  final productoId = TextEditingController();
  final nombreProducto = TextEditingController();
  final cantidad = TextEditingController();
  final costoUnitario = TextEditingController();
  final fleteUnitario = TextEditingController();
  final seguroUnitario = TextEditingController();
  final arancelesUnitario = TextEditingController();
  final gastosUnitario = TextEditingController();
  final descuento = TextEditingController();

  void dispose() {
    productoId.dispose();
    nombreProducto.dispose();
    cantidad.dispose();
    costoUnitario.dispose();
    fleteUnitario.dispose();
    seguroUnitario.dispose();
    arancelesUnitario.dispose();
    gastosUnitario.dispose();
    descuento.dispose();
  }

  DetalleLinea haciaLinea({double tasaItbis = 0.18}) => DetalleLinea()
    ..productoId = int.tryParse(productoId.text.trim())
    ..cantidad = double.tryParse(cantidad.text) ?? 0.0
    ..costoUnitario = double.tryParse(costoUnitario.text) ?? 0.0
    ..fleteUnitario = double.tryParse(fleteUnitario.text) ?? 0.0
    ..seguroUnitario = double.tryParse(seguroUnitario.text) ?? 0.0
    ..arancelesUnitario = double.tryParse(arancelesUnitario.text) ?? 0.0
    ..gastosUnitario = double.tryParse(gastosUnitario.text) ?? 0.0
    ..descuentoPorcentaje = double.tryParse(descuento.text) ?? 0.0
    ..tasaImpuestoLinea = tasaItbis;

  void desdeLinea(DetalleLinea linea) {
    cantidad.text = linea.cantidad.toString();
    costoUnitario.text = linea.costoUnitario.toString();
    fleteUnitario.text = linea.fleteUnitario.toString();
    seguroUnitario.text = linea.seguroUnitario.toString();
    arancelesUnitario.text = linea.arancelesUnitario.toString();
    gastosUnitario.text = linea.gastosUnitario.toString();
    descuento.text = linea.descuentoPorcentaje.toString();
  }
}
