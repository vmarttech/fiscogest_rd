import 'package:fiscogestrd/models/producto.dart';

/// Registro de una Compra
class Compra {
  // 1. Constructor principal
  Compra({
    this.id,
    required this.numeroComprobante,
    required this.fecha,
    required this.proveedor,
    this.rncProveedor,
    required this.detalles,
    required this.subTotal,
    required this.itbisAcreditable,
    required this.impuestoSelectivo,
    required this.total,
    this.observacion,
  });

  // 2. Constructores FACTORY antes de cualquier método
  factory Compra.fromMap(Map<String, dynamic> map, List<DetalleOperacion> detalles) {
    return Compra(
      id: map['id'] as int?,
      numeroComprobante: map['numeroComprobante'] as String,
      fecha: DateTime.parse(map['fecha'] as String),
      proveedor: map['proveedor'] as String,
      rncProveedor: map['rncProveedor'] as String?,
      detalles: detalles,
      subTotal: (map['subTotal'] as num).toDouble(),
      itbisAcreditable: (map['itbisAcreditable'] as num).toDouble(),
      impuestoSelectivo: (map['impuestoSelectivo'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      observacion: map['observacion'] as String?,
    );
  }

  // 3. Campos
  final int? id;
  final String numeroComprobante;
  final DateTime fecha;
  final String proveedor;
  final String? rncProveedor;
  final List<DetalleOperacion> detalles;
  final double subTotal;
  final double itbisAcreditable;
  final double impuestoSelectivo;
  final double total;
  final String? observacion;

  // 4. Métodos
  Compra copyWith({
    int? id,
    String? numeroComprobante,
    DateTime? fecha,
    String? proveedor,
    String? rncProveedor,
    List<DetalleOperacion>? detalles,
    double? subTotal,
    double? itbisAcreditable,
    double? impuestoSelectivo,
    double? total,
    String? observacion,
  }) {
    return Compra(
      id: id ?? this.id,
      numeroComprobante: numeroComprobante ?? this.numeroComprobante,
      fecha: fecha ?? this.fecha,
      proveedor: proveedor ?? this.proveedor,
      rncProveedor: rncProveedor ?? this.rncProveedor,
      detalles: detalles ?? this.detalles,
      subTotal: subTotal ?? this.subTotal,
      itbisAcreditable: itbisAcreditable ?? this.itbisAcreditable,
      impuestoSelectivo: impuestoSelectivo ?? this.impuestoSelectivo,
      total: total ?? this.total,
      observacion: observacion ?? this.observacion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numeroComprobante': numeroComprobante,
      'fecha': fecha.toIso8601String(),
      'proveedor': proveedor,
      'rncProveedor': rncProveedor,
      'subTotal': subTotal,
      'itbisAcreditable': itbisAcreditable,
      'impuestoSelectivo': impuestoSelectivo,
      'total': total,
      'observacion': observacion,
    };
  }
}

/// Registro de una Venta
class Venta {
  // 1. Constructor principal
  Venta({
    this.id,
    required this.numeroComprobante,
    required this.fecha,
    required this.cliente,
    this.rncCliente,
    required this.detalles,
    required this.subTotal,
    required this.itbisGenerado,
    required this.impuestoSelectivo,
    required this.total,
    this.observacion,
  });

  // 2. Constructor FACTORY
  factory Venta.fromMap(Map<String, dynamic> map, List<DetalleOperacion> detalles) {
    return Venta(
      id: map['id'] as int?,
      numeroComprobante: map['numeroComprobante'] as String,
      fecha: DateTime.parse(map['fecha'] as String),
      cliente: map['cliente'] as String,
      rncCliente: map['rncCliente'] as String?,
      detalles: detalles,
      subTotal: (map['subTotal'] as num).toDouble(),
      itbisGenerado: (map['itbisGenerado'] as num).toDouble(),
      impuestoSelectivo: (map['impuestoSelectivo'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      observacion: map['observacion'] as String?,
    );
  }

  // 3. Campos
  final int? id;
  final String numeroComprobante;
  final DateTime fecha;
  final String cliente;
  final String? rncCliente;
  final List<DetalleOperacion> detalles;
  final double subTotal;
  final double itbisGenerado;
  final double impuestoSelectivo;
  final double total;
  final String? observacion;

  // 4. Métodos
  Venta copyWith({
    int? id,
    String? numeroComprobante,
    DateTime? fecha,
    String? cliente,
    String? rncCliente,
    List<DetalleOperacion>? detalles,
    double? subTotal,
    double? itbisGenerado,
    double? impuestoSelectivo,
    double? total,
    String? observacion,
  }) {
    return Venta(
      id: id ?? this.id,
      numeroComprobante: numeroComprobante ?? this.numeroComprobante,
      fecha: fecha ?? this.fecha,
      cliente: cliente ?? this.cliente,
      rncCliente: rncCliente ?? this.rncCliente,
      detalles: detalles ?? this.detalles,
      subTotal: subTotal ?? this.subTotal,
      itbisGenerado: itbisGenerado ?? this.itbisGenerado,
      impuestoSelectivo: impuestoSelectivo ?? this.impuestoSelectivo,
      total: total ?? this.total,
      observacion: observacion ?? this.observacion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numeroComprobante': numeroComprobante,
      'fecha': fecha.toIso8601String(),
      'cliente': cliente,
      'rncCliente': rncCliente,
      'subTotal': subTotal,
      'itbisGenerado': itbisGenerado,
      'impuestoSelectivo': impuestoSelectivo,
      'total': total,
      'observacion': observacion,
    };
  }
}

/// Línea de detalle para compras o ventas
class DetalleOperacion {
  // 1. Constructor principal
  DetalleOperacion({
    this.id,
    required this.productoId,
    required this.codigoProducto,
    required this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.aplicaImpuesto,
    required this.porcentajeImpuesto,
    required this.esImpuestoSelectivo,
    required this.subTotal,
    required this.valorImpuesto,
    required this.totalLinea,
  });

  // 2. Constructores FACTORY
  factory DetalleOperacion.desdeProducto(Producto prod, dynamic cantidad) {
    final cant = num.tryParse(cantidad.toString()) ?? 0.0;
    final subtotal = prod.precioCompra * cant;
    double impuesto = 0.0;

    if (prod.aplicaImpuesto) {
      impuesto = subtotal * (prod.porcentajeImpuesto / 100);
    }

    return DetalleOperacion(
      productoId: prod.id!,
      codigoProducto: prod.codigo,
      nombreProducto: prod.nombre,
      cantidad: cant,
      precioUnitario: prod.precioCompra,
      aplicaImpuesto: prod.aplicaImpuesto,
      porcentajeImpuesto: prod.porcentajeImpuesto,
      esImpuestoSelectivo: prod.esImpuestoSelectivo,
      subTotal: subtotal,
      valorImpuesto: impuesto,
      totalLinea: subtotal + impuesto,
    );
  }

  factory DetalleOperacion.fromMap(Map<String, dynamic> map) {
    return DetalleOperacion(
      id: map['id'] as int?,
      productoId: map['productoId'] as int,
      codigoProducto: map['codigoProducto'] as String,
      nombreProducto: map['nombreProducto'] as String,
      cantidad: map['cantidad'],
      precioUnitario: (map['precioUnitario'] as num).toDouble(),
      aplicaImpuesto: (map['aplicaImpuesto'] as int) == 1,
      porcentajeImpuesto: (map['porcentajeImpuesto'] as num).toDouble(),
      esImpuestoSelectivo: (map['esImpuestoSelectivo'] as int) == 1,
      subTotal: (map['subTotal'] as num).toDouble(),
      valorImpuesto: (map['valorImpuesto'] as num).toDouble(),
      totalLinea: (map['totalLinea'] as num).toDouble(),
    );
  }

  // 3. Campos
  final int? id;
  final int productoId;
  final String codigoProducto;
  final String nombreProducto;
  final dynamic cantidad;
  final double precioUnitario;
  final bool aplicaImpuesto;
  final double porcentajeImpuesto;
  final bool esImpuestoSelectivo;
  final double subTotal;
  final double valorImpuesto;
  final double totalLinea;

  // 4. Métodos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productoId': productoId,
      'codigoProducto': codigoProducto,
      'nombreProducto': nombreProducto,
      'cantidad': cantidad,
      'precioUnitario': precioUnitario,
      'aplicaImpuesto': aplicaImpuesto ? 1 : 0,
      'porcentajeImpuesto': porcentajeImpuesto,
      'esImpuestoSelectivo': esImpuestoSelectivo ? 1 : 0,
      'subTotal': subTotal,
      'valorImpuesto': valorImpuesto,
      'totalLinea': totalLinea,
    };
  }
}