class Producto {

  const Producto({
    this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.precioCompra,
    required this.precioVenta,
    required this.stock,
    required this.stockMinimo,
    this.categoriaId,
    this.marcaId,
    this.unidadId,
    this.activo = true,
  }) : assert(stock >= 0, 'El stock no puede ser negativo'),
       assert(stockMinimo >= 0, 'El stock mínimo no puede ser negativo');

  final int? id;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final double precioCompra;
  final double precioVenta;
  final double stock;
  final double stockMinimo;
  final int? categoriaId;
  final int? marcaId;
  final int? unidadId;
  final bool activo;

  /// Existencia actual en almacén
  double get existenciaActual => stock;

  /// Existencia disponible (puede descontar apartados o reservas futuras si aplica)
  double get existenciaDisponible => stock;

  Producto copyWith({
    int? id,
    String? codigo,
    String? nombre,
    String? descripcion,
    double? precioCompra,
    double? precioVenta,
    double? stock,
    double? stockMinimo,
    int? categoriaId,
    int? marcaId,
    int? unidadId,
    bool? activo,
  }) {
    return Producto(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precioCompra: precioCompra ?? this.precioCompra,
      precioVenta: precioVenta ?? this.precioVenta,
      stock: stock ?? this.stock,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      categoriaId: categoriaId ?? this.categoriaId,
      marcaId: marcaId ?? this.marcaId,
      unidadId: unidadId ?? this.unidadId,
      activo: activo ?? this.activo,
    );
  }
}
