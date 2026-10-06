import 'dart:typed_data';

import 'package:fiscogest_rd/features/creditos/domain/entities/cuenta_por_cobrar.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/abono_credito.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';

abstract class ICreditoDocumentoService {
  Future<Uint8List> generarPdfSolicitud({
    required Venta venta,
    CuentaPorCobrar? condiciones,
  });

  Future<Uint8List> generarPdfContrato({
    required Venta venta,
    required CuentaPorCobrar condiciones,
  });

  Future<void> imprimirSolicitud({
    required Venta venta,
    CuentaPorCobrar? condiciones,
  });

  Future<void> imprimirContrato({
    required Venta venta,
    required CuentaPorCobrar condiciones,
  });

  Future<String> exportarSolicitudPdf({
    required Venta venta,
    CuentaPorCobrar? condiciones,
  });

  Future<String> exportarContratoPdf({
    required Venta venta,
    required CuentaPorCobrar condiciones,
  });

  Future<void> enviarSolicitudPorCorreo({
    required Venta venta,
    CuentaPorCobrar? condiciones,
    String correoDestinatario = '',
  });

  Future<void> enviarContratoPorCorreo({
    required Venta venta,
    required CuentaPorCobrar condiciones,
    String correoDestinatario = '',
  });

  Future<Uint8List> generarPdfCronograma({required CuentaPorCobrar cuenta});

  Future<void> imprimirCronograma({required CuentaPorCobrar cuenta});

  Future<Uint8List> generarPdfEstadoCuenta({required CuentaPorCobrar cuenta});

  Future<void> imprimirEstadoCuenta({required CuentaPorCobrar cuenta});

  Future<Uint8List> generarPdfAbono({
    required CuentaPorCobrar cuenta,
    required AbonoCredito abono,
    double? saldoAnterior,
    double? saldoActual,
  });

  Future<void> imprimirAbono({
    required CuentaPorCobrar cuenta,
    required AbonoCredito abono,
    double? saldoAnterior,
    double? saldoActual,
  });

  Future<void> compartirAbono({
    required CuentaPorCobrar cuenta,
    required AbonoCredito abono,
    double? saldoAnterior,
    double? saldoActual,
  });

}
