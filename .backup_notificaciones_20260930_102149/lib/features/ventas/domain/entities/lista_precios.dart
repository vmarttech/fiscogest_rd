class ListaPrecios {
  const ListaPrecios({
    required this.productoId,
    required this.precioVenta,
    this.margenGanancia,
    this.precioMinimo,
    this.precioMayorista,
    this.precioEspecial,
  });

  final int productoId;
  final double precioVenta;
  final double? margenGanancia;
  final double? precioMinimo;
  final double? precioMayorista;
  final double? precioEspecial;

  static double calcularPrecioDesdeMargen(double costo, double margen) {
    return costo * (1 + margen / 100);
  }

  static double calcularMargen(double precioVenta, double costo) {
    if (costo <= 0) return 0.0;
    return ((precioVenta - costo) / costo) * 100;
  }

  bool precioVentaEsValido() {
    if (precioMinimo == null) return true;
    return precioVenta >= precioMinimo!;
  }

  ListaPrecios copyWith({
    int? productoId,
    double? precioVenta,
    double? margenGanancia,
    double? precioMinimo,
    double? precioMayorista,
    double? precioEspecial,
  }) {
    return ListaPrecios(
      productoId: productoId ?? this.productoId,
      precioVenta: precioVenta ?? this.precioVenta,
      margenGanancia: margenGanancia ?? this.margenGanancia,
      precioMinimo: precioMinimo ?? this.precioMinimo,
      precioMayorista: precioMayorista ?? this.precioMayorista,
      precioEspecial: precioEspecial ?? this.precioEspecial,
    );
  }

  @override
  String toString() {
    return 'ListaPrecios(productoId: $productoId, precioVenta: $precioVenta, margenGanancia: $margenGanancia, precioMinimo: $precioMinimo, precioMayorista: $precioMayorista, precioEspecial: $precioEspecial)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ListaPrecios &&
        other.productoId == productoId &&
        other.precioVenta == precioVenta &&
        other.margenGanancia == margenGanancia &&
        other.precioMinimo == precioMinimo &&
        other.precioMayorista == precioMayorista &&
        other.precioEspecial == precioEspecial;
  }

  @override
  int get hashCode {
    return productoId.hashCode ^
        precioVenta.hashCode ^
        margenGanancia.hashCode ^
        precioMinimo.hashCode ^
        precioMayorista.hashCode ^
        precioEspecial.hashCode;
  }
}
