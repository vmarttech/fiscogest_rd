class Producto {

  Producto({
    this.id,
    required this.codigo,
    this.codigoBarras,
    required this.nombre,
    this.descripcion,
    required this.precioCompra,
    required this.precioVenta,
    this.stock,
    this.stockMinimo,
    this.stockMaximo,
    required this.categoriaId,
    required this.marcaId,
    required this.unidadMedidaId,
    required this.activo,
  });
  final int? id;
  final String codigo;
  final String? codigoBarras;
  final String nombre;
  final String? descripcion;
  final double precioCompra;
  final double precioVenta;
  final double? stock;
  final double? stockMinimo;
  final double? stockMaximo;
  final int categoriaId;
  final int marcaId;
  final int unidadMedidaId;
  final bool activo;

  // ✅ Método que faltaba, causa error servicios entrada/salida
  Producto copyWith({
    int? id,
    String? codigo,
    String? codigoBarras,
    String? nombre,
    String? descripcion,
    double? precioCompra,
    double? precioVenta,
    double? stock,
    double? stockMinimo,
    double? stockMaximo,
    int? categoriaId,
    int? marcaId,
    int? unidadMedidaId,
    bool? activo,
  }) {
    return Producto(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precioCompra: precioCompra ?? this.precioCompra,
      precioVenta: precioVenta ?? this.precioVenta,
      stock: stock ?? this.stock,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      stockMaximo: stockMaximo ?? this.stockMaximo,
      categoriaId: categoriaId ?? this.categoriaId,
      marcaId: marcaId ?? this.marcaId,
      unidadMedidaId: unidadMedidaId ?? this.unidadMedidaId,
      activo: activo ?? this.activo,
    );
  }
}
