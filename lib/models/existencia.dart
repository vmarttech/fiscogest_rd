class Existencia {
  final int? id;
  final int productoId;
  final String codigoProducto;
  final String nombreProducto;
  final double cantidadDisponible;
  final double cantidadReservada;
  final double cantidadMinima;
  final double cantidadMaxima;
  final String ubicacion;
  final DateTime ultimaActualizacion;

  Existencia({
    this.id,
    required this.productoId,
    required this.codigoProducto,
    required this.nombreProducto,
    required this.cantidadDisponible,
    this.cantidadReservada = 0.0,
    this.cantidadMinima = 5.0,
    this.cantidadMaxima = 1000.0,
    this.ubicacion = 'Almacén Principal',
    DateTime? ultimaActualizacion,
  }) : ultimaActualizacion = ultimaActualizacion ?? DateTime.now();

  // ✅ Propiedad calculada
  double get cantidadReal => cantidadDisponible - cantidadReservada;
  bool get estaBajoMinimo => cantidadReal < cantidadMinima;

  // ✅ Mapa para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productoId': productoId,
      'codigoProducto': codigoProducto,
      'nombreProducto': nombreProducto,
      'cantidadDisponible': cantidadDisponible,
      'cantidadReservada': cantidadReservada,
      'cantidadMinima': cantidadMinima,
      'cantidadMaxima': cantidadMaxima,
      'ubicacion': ubicacion,
      'ultimaActualizacion': ultimaActualizacion.toIso8601String(),
    };
  }

  // ✅ Constructor desde Mapa
  static Existencia fromMap(Map<String, dynamic> map) {
    return Existencia(
      id: map['id'],
      productoId: map['productoId'],
      codigoProducto: map['codigoProducto'],
      nombreProducto: map['nombreProducto'],
      cantidadDisponible: (map['cantidadDisponible'] ?? 0.0).toDouble(),
      cantidadReservada: (map['cantidadReservada'] ?? 0.0).toDouble(),
      cantidadMinima: (map['cantidadMinima'] ?? 5.0).toDouble(),
      cantidadMaxima: (map['cantidadMaxima'] ?? 1000.0).toDouble(),
      ubicacion: map['ubicacion'] ?? 'Almacén Principal',
      ultimaActualizacion: DateTime.parse(map['ultimaActualizacion']),
    );
  }
}