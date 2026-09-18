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
}
