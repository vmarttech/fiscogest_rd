/// ETAPA 3.1 – EXISTENCIA
/// Propósito: Control de cantidades actual y disponible por producto
/// Relación: Asociada a Producto mediante productoId
/// Reglas: Valores >= 0; Disponible ≤ Actual
class Existencia {
  const Existencia({
    this.id,
    required this.productoId,
    required this.existenciaActual,
    required this.existenciaDisponible,
  }) : assert(existenciaActual >= 0, 'La existencia actual NO puede ser negativa'),
       assert(existenciaDisponible >= 0, 'La existencia disponible NO puede ser negativa'),
       assert(existenciaDisponible <= existenciaActual, 'Existencia disponible NO puede superar la existencia total');

  final int? id;
  final int productoId;
  final double existenciaActual;
  final double existenciaDisponible;

  /// Copia segura para modificar valores manteniendo inmutabilidad
  Existencia copyWith({
    int? id,
    int? productoId,
    double? existenciaActual,
    double? existenciaDisponible,
  }) {
    return Existencia(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      existenciaActual: existenciaActual ?? this.existenciaActual,
      existenciaDisponible: existenciaDisponible ?? this.existenciaDisponible,
    );
  }
}
