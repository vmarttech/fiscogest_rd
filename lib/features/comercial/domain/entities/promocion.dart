class Promocion {

  const Promocion({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.tipo,
    required this.valor,
    this.productosAplicables,
    this.categoriasCliente,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estaActiva,
    this.minimoCantidad,
    this.minimoMonto,
  });
  final String id;
  final String nombre;
  final String descripcion;
  final String tipo;
  final double valor;
  final List<String>? productosAplicables;
  final List<String>? categoriasCliente;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final bool estaActiva;
  final int? minimoCantidad;
  final double? minimoMonto;

  bool estaVigente(DateTime hoy) {
    return estaActiva &&
        hoy.isAfter(fechaInicio.subtract(const Duration(seconds: 1))) &&
        hoy.isBefore(fechaFin.add(const Duration(days: 1)));
  }

  bool aplicaAProducto(String productoId) {
    if (productosAplicables == null || productosAplicables!.isEmpty) {
      return true;
    }
    return productosAplicables!.contains(productoId);
  }

  bool aplicaACategoriaCliente(String? categoria) {
    if (categoriasCliente == null || categoriasCliente!.isEmpty) {
      return true;
    }
    if (categoria == null) return false;
    return categoriasCliente!.contains(categoria);
  }

  Promocion copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    String? tipo,
    double? valor,
    List<String>? productosAplicables,
    List<String>? categoriasCliente,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool? estaActiva,
    int? minimoCantidad,
    double? minimoMonto,
  }) {
    return Promocion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      tipo: tipo ?? this.tipo,
      valor: valor ?? this.valor,
      productosAplicables: productosAplicables ?? this.productosAplicables,
      categoriasCliente: categoriasCliente ?? this.categoriasCliente,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      estaActiva: estaActiva ?? this.estaActiva,
      minimoCantidad: minimoCantidad ?? this.minimoCantidad,
      minimoMonto: minimoMonto ?? this.minimoMonto,
    );
  }

  @override
  String toString() {
    return 'Promocion(id: $id, nombre: $nombre, tipo: $tipo, valor: $valor, activa: $estaActiva)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Promocion && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
