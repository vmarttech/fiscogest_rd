import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';

class Venta {
  const Venta({
    required this.id,
    required this.numeroCotizacion,
    this.numeroFactura,
    required this.clienteId,
    this.nombreCliente,
    this.clienteTelefono,
    this.clienteWhatsapp,
    this.clienteDireccion,
    required this.fecha,
    required this.detalles,
    required this.montoSubtotal,
    required this.descuentoGlobal,
    required this.itbis,
    required this.montoTotal,
    required this.formaPago,
    required this.costoEnvio,
    required this.abonoInicial,
    this.numeroCuotas = 1,
    this.plazoDias = 30,
    this.tasaInteres = 0.0,
    this.montoInteres = 0.0,
    this.vencimiento,
    required this.estadoDocumento,
    required this.usuarioId,
    required this.fechaRegistro,
    this.descuentoId,
    this.descuentoNombre,
    required this.montoDescuento,
    this.comprobanteEntregaImpreso = false,
    this.fechaComprobanteEntrega,
  });

  final int? id;
  final String numeroCotizacion;
  final String? numeroFactura;
  final int clienteId;
  final String? nombreCliente;
  final String? clienteTelefono;
  final String? clienteWhatsapp;
  final String? clienteDireccion;
  final DateTime fecha;
  final List<DetalleVenta> detalles;
  final double montoSubtotal;
  final double descuentoGlobal;
  final double itbis;
  final double montoTotal;
  final String formaPago;
  final double costoEnvio;
  final double abonoInicial;
  final int numeroCuotas;
  final int plazoDias;
  final double tasaInteres;
  final double montoInteres;
  final DateTime? vencimiento;
  final EstadoDocumento estadoDocumento;
  final int usuarioId;
  final DateTime fechaRegistro;
  final int? descuentoId;
  final String? descuentoNombre;
  final double montoDescuento;
  final bool comprobanteEntregaImpreso;
  final DateTime? fechaComprobanteEntrega;

  // ==============================================
  // ✅ GETTERS DE COMPATIBILIDAD — NOMBRES ANTIGUOS
  // ==============================================
  String get numero => numeroCotizacion;
  String get tipoPago => formaPago;
  bool get esCredito => formaPago == 'credito';
  double get subtotal => montoSubtotal;
  double get total => montoTotal;
  DateTime? get createdAt => fechaRegistro;
  EstadoDocumento get estado => estadoDocumento;

  Venta copyWith({
    int? id,
    String? numeroCotizacion,
    String? numeroFactura,
    int? clienteId,
    String? nombreCliente,
    String? clienteTelefono,
    String? clienteWhatsapp,
    String? clienteDireccion,
    DateTime? fecha,
    List<DetalleVenta>? detalles,
    double? montoSubtotal,
    double? descuentoGlobal,
    double? itbis,
    double? montoTotal,
    String? formaPago,
    double? costoEnvio,
    double? abonoInicial,
    int? numeroCuotas,
    int? plazoDias,
    double? tasaInteres,
    double? montoInteres,
    DateTime? vencimiento,
    EstadoDocumento? estadoDocumento,
    int? usuarioId,
    DateTime? fechaRegistro,
    int? descuentoId,
    String? descuentoNombre,
    double? montoDescuento,
    bool? comprobanteEntregaImpreso,
    DateTime? fechaComprobanteEntrega,
  }) {
    return Venta(
      id: id ?? this.id,
      numeroCotizacion: numeroCotizacion ?? this.numeroCotizacion,
      numeroFactura: numeroFactura ?? this.numeroFactura,
      clienteId: clienteId ?? this.clienteId,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      clienteTelefono: clienteTelefono ?? this.clienteTelefono,
      clienteWhatsapp: clienteWhatsapp ?? this.clienteWhatsapp,
      clienteDireccion: clienteDireccion ?? this.clienteDireccion,
      fecha: fecha ?? this.fecha,
      detalles: detalles ?? this.detalles,
      montoSubtotal: montoSubtotal ?? this.montoSubtotal,
      descuentoGlobal: descuentoGlobal ?? this.descuentoGlobal,
      itbis: itbis ?? this.itbis,
      montoTotal: montoTotal ?? this.montoTotal,
      formaPago: formaPago ?? this.formaPago,
      costoEnvio: costoEnvio ?? this.costoEnvio,
      abonoInicial: abonoInicial ?? this.abonoInicial,
      numeroCuotas: numeroCuotas ?? this.numeroCuotas,
      plazoDias: plazoDias ?? this.plazoDias,
      tasaInteres: tasaInteres ?? this.tasaInteres,
      montoInteres: montoInteres ?? this.montoInteres,
      vencimiento: vencimiento ?? this.vencimiento,
      estadoDocumento: estadoDocumento ?? this.estadoDocumento,
      usuarioId: usuarioId ?? this.usuarioId,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      descuentoId: descuentoId ?? this.descuentoId,
      descuentoNombre: descuentoNombre ?? this.descuentoNombre,
      montoDescuento: montoDescuento ?? this.montoDescuento,
      comprobanteEntregaImpreso:
          comprobanteEntregaImpreso ?? this.comprobanteEntregaImpreso,
      fechaComprobanteEntrega:
          fechaComprobanteEntrega ?? this.fechaComprobanteEntrega,
    );
  }
}
