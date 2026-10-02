class Gasto {
  Gasto({
    this.id,
    required this.fecha,
    required this.categoria,
    required this.descripcion,
    required this.monto,
    this.formaPago = 'efectivo',
    this.notas,
    required this.creadoEn,
    this.actualizadoEn,
  });

  final int? id;
  final DateTime fecha;
  final String categoria;
  final String descripcion;
  final double monto;
  final String formaPago;
  final String? notas;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;

  Gasto copyWith({
    int? id,
    DateTime? fecha,
    String? categoria,
    String? descripcion,
    double? monto,
    String? formaPago,
    String? notas,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  }) {
    return Gasto(
      id: id ?? this.id,
      fecha: fecha ?? this.fecha,
      categoria: categoria ?? this.categoria,
      descripcion: descripcion ?? this.descripcion,
      monto: monto ?? this.monto,
      formaPago: formaPago ?? this.formaPago,
      notas: notas ?? this.notas,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }
}
