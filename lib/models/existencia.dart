class Existencia {
  Existencia({
    this.id,
    required this.productoId,
    required this.codigoProducto,
    required this.nombreProducto,
    required this.cantidadDisponible,
    this.cantidadReservada = 0.0, // ✅ VALOR POR DEFECTO SEGURO
    required this.cantidadMinima,
    required this.cantidadMaxima,
    this.ubicacion = 'Almacén Principal',
    this.ultimaActualizacion,
  });
  final int? id;
  final int productoId;
  final String codigoProducto;
  final String nombreProducto;
  final double cantidadDisponible;
  final double cantidadReservada;
  final double cantidadMinima;
  final double cantidadMaxima;
  final String ubicacion;
  final DateTime? ultimaActualizacion;

  // =====================================================
  // ✅ CONVERSIÓN A MAPA (PARA BASE DE DATOS)
  // ✅ CAMPOS ALINEADOS CON TABLA 'existencias'
  // =====================================================
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
      'ultimaActualizacion': ultimaActualizacion?.toIso8601String(),
    };
  }

  // =====================================================
  // ✅ CONVERSIÓN DESDE MAPA (LECTURA BD)
  // ✅ SEGURO CON INT/DOUBLE Y VALORES NULOS
  // =====================================================
  static Existencia fromMap(Map<String, dynamic> map) {
    return Existencia(
      id: map['id'],
      productoId: map['productoId'],
      codigoProducto: map['codigoProducto'] ?? '',
      nombreProducto: map['nombreProducto'] ?? '',
      cantidadDisponible: _toDoubleSafe(map['cantidadDisponible']),
      cantidadReservada: _toDoubleSafe(map['cantidadReservada']),
      cantidadMinima: _toDoubleSafe(map['cantidadMinima']),
      cantidadMaxima: _toDoubleSafe(
        map['cantidadMaxima'],
        valorDefecto: 1000.0,
      ),
      ubicacion: map['ubicacion'] ?? 'Almacén Principal',
      ultimaActualizacion: map['ultimaActualizacion'] != null
          ? DateTime.parse(map['ultimaActualizacion'])
          : null,
    );
  }

  // =====================================================
  // ✅ FUNCIÓN INTERNA DE SEGURIDAD (INT <-> DOUBLE)
  // =====================================================
  static double _toDoubleSafe(dynamic valor, {double valorDefecto = 0.0}) {
    if (valor == null) return valorDefecto;
    if (valor is double) return valor;
    if (valor is int) return valor.toDouble();
    return valorDefecto;
  }

  // =====================================================
  // ✅ PROPIEDADES CALCULADAS (REGLAS DE NEGOCIO)
  // =====================================================

  // 🔹 Stock Real = Lo que realmente se puede vender o usar
  double get cantidadReal => cantidadDisponible - cantidadReservada;

  // 🔹 Alerta: Stock por debajo del mínimo permitido
  bool get estaBajoMinimo => cantidadReal < cantidadMinima;

  // 🔹 Alerta: Stock superior al máximo recomendado
  bool get tieneExcesoStock => cantidadDisponible > cantidadMaxima;

  // 🔹 Formato de fecha para interfaces de usuario
  String get fechaFormateada {
    if (ultimaActualizacion == null) return 'Sin registro';
    return '${ultimaActualizacion!.day.toString().padLeft(2, '0')}/'
        '${ultimaActualizacion!.month.toString().padLeft(2, '0')}/'
        '${ultimaActualizacion!.year} '
        '${ultimaActualizacion!.hour.toString().padLeft(2, '0')}:'
        '${ultimaActualizacion!.minute.toString().padLeft(2, '0')}';
  }

  // =====================================================
  // ✅ COPY WITH (ESENCIAL PARA ACTUALIZACIONES)
  // =====================================================
  Existencia copyWith({
    int? id,
    int? productoId,
    String? codigoProducto,
    String? nombreProducto,
    double? cantidadDisponible,
    double? cantidadReservada,
    double? cantidadMinima,
    double? cantidadMaxima,
    String? ubicacion,
    DateTime? ultimaActualizacion,
  }) {
    return Existencia(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      codigoProducto: codigoProducto ?? this.codigoProducto,
      nombreProducto: nombreProducto ?? this.nombreProducto,
      cantidadDisponible: cantidadDisponible ?? this.cantidadDisponible,
      cantidadReservada: cantidadReservada ?? this.cantidadReservada,
      cantidadMinima: cantidadMinima ?? this.cantidadMinima,
      cantidadMaxima: cantidadMaxima ?? this.cantidadMaxima,
      ubicacion: ubicacion ?? this.ubicacion,
      ultimaActualizacion: ultimaActualizacion ?? this.ultimaActualizacion,
    );
  }
}
