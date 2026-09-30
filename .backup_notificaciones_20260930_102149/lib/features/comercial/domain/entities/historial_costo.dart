/// Una entrada del historial de costos de un producto.
class HistorialCostoItem {
  const HistorialCostoItem({
    required this.compraId,
    required this.fecha,
    required this.proveedorNombre,
    required this.costoUnitario,
    required this.costoAdquisicion,
    required this.cantidad,
    required this.ncf,
  });

  final int compraId;
  final DateTime fecha;
  final String proveedorNombre;
  final double costoUnitario;
  final double costoAdquisicion;
  final double cantidad;
  final String ncf;
}

/// Resumen del historial de un producto.
class HistorialCostoResumen {
  const HistorialCostoResumen({
    required this.productoId,
    required this.nombreProducto,
    required this.items,
    required this.ultimoCosto,
    required this.costoPromedio,
    required this.variacion,
    required this.variacionPorcentaje,
  });

  final int productoId;
  final String nombreProducto;
  final List<HistorialCostoItem> items;
  final double ultimoCosto;
  final double costoPromedio;
  final double variacion; // último - anterior (0 si solo hay uno)
  final double variacionPorcentaje;
}
