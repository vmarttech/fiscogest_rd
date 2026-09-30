class ActualizarCostos {
  const ActualizarCostos();

  Future<double?> call({
    required int idProducto,
    required int cantidadAnterior,
    required double costoUnitarioAnterior,
    required int cantidadNueva,
    required double costoUnitarioNuevo,
  }) async {
    final int totalCantidad = cantidadAnterior + cantidadNueva;
    if (totalCantidad <= 0) return null;

    final double nuevoCostoPromedio =
        ((cantidadAnterior * costoUnitarioAnterior) +
            (cantidadNueva * costoUnitarioNuevo)) /
        totalCantidad;

    return nuevoCostoPromedio;
  }
}
