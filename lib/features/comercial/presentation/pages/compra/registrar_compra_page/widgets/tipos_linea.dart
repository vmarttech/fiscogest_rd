import 'package:flutter/material.dart';

class DetalleLinea {
  int? productoId;
  String nombreProducto = '';
  double cantidad = 0.0;
  double costoUnitario = 0.0;
  double fleteUnitario = 0.0;
  double seguroUnitario = 0.0;
  double arancelesUnitario = 0.0;
  double gastosUnitario = 0.0;
  double descuentoPorcentaje = 0.0;

  double get gastosAsociados =>
      fleteUnitario + seguroUnitario + arancelesUnitario + gastosUnitario;

  double get costoReal => costoUnitario + gastosAsociados;

  double get importeBruto => cantidad * costoUnitario;

  double get montoDescuentoLinea => importeBruto * (descuentoPorcentaje / 100);

  double get subtotalLinea => importeBruto - montoDescuentoLinea;

  double get baseImponibleLinea => subtotalLinea;

  double get tasaImpuestoLinea => 0.18;

  double get itbisLinea => baseImponibleLinea * tasaImpuestoLinea;

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

  /// ✅ Leer valores desde controladores y crear línea — CONECTA EL RECÁLCULO
  DetalleLinea haciaLinea() => DetalleLinea()
    ..productoId = int.tryParse(productoId.text.trim())
    ..cantidad = double.tryParse(cantidad.text) ?? 0.0
    ..costoUnitario = double.tryParse(costoUnitario.text) ?? 0.0
    ..fleteUnitario = double.tryParse(fleteUnitario.text) ?? 0.0
    ..seguroUnitario = double.tryParse(seguroUnitario.text) ?? 0.0
    ..arancelesUnitario = double.tryParse(arancelesUnitario.text) ?? 0.0
    ..gastosUnitario = double.tryParse(gastosUnitario.text) ?? 0.0
    ..descuentoPorcentaje = double.tryParse(descuento.text) ?? 0.0;

  /// ✅ Cargar valores desde línea hacia controladores
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
