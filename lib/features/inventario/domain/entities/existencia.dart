/// ETAPA 3.1 – EXISTENCIA
/// Propósito: Control de cantidades actual y disponible por producto
/// Relación: Asociada a Producto mediante idProducto
/// Reglas: Valores >= 0; Disponible ≤ Actual
class Existencia {
  const Existencia({
    this.id,
    required this.idProducto,
    required this.existenciaActual,
    required this.existenciaDisponible,
  }) : assert(existenciaActual >= 0, 'La existencia actual NO puede ser negativa'),
       assert(existenciaDisponible >= 0, 'La existencia disponible NO puede ser negativa'),
       assert(existenciaDisponible <= existenciaActual, 'Existencia disponible NO puede superar la existencia total');

  final int? id;
  final int idProducto;
  final double existenciaActual;
  final double existenciaDisponible;

  /// Copia segura para modificar valores manteniendo inmutabilidad
  Existencia copyWith({
    int? id,
    int? idProducto,
    double? existenciaActual,
    double? existenciaDisponible,
  }) {
    return Existencia(
      id: id ?? this.id,
      idProducto: idProducto ?? this.idProducto,
      existenciaActual: existenciaActual ?? this.existenciaActual,
      existenciaDisponible: existenciaDisponible ?? this.existenciaDisponible,
    );
  }
}
