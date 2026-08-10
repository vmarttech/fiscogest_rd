import 'package:equatable/equatable.dart';

class Producto extends Equatable {

  const Producto({
    this.id,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.precioCompra,
    required this.precioVenta,
    required this.stock,
    required this.stockMinimo,
    required this.categoriaId,
    required this.marcaId,
    required this.unidadId,
    required this.activo,
  });
  final int? id;
  final String codigo;
  final String nombre;
  final String descripcion;
  final double precioCompra;
  final double precioVenta;
  final double stock;
  final double stockMinimo;
  final int categoriaId;
  final int marcaId;
  final int unidadId;
  final bool activo;

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

  @override
  List<Object?> get props => [
        id,
        codigo,
        nombre,
        descripcion,
        precioCompra,
        precioVenta,
        stock,
        stockMinimo,
        categoriaId,
        marcaId,
        unidadId,
        activo,
      ];
}
