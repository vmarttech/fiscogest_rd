enum TipoAlmacen { principal, tienda, deposito, transito }

extension TipoAlmacenX on TipoAlmacen {
  String get label {
    return switch (this) {
      TipoAlmacen.principal => 'Principal',
      TipoAlmacen.tienda => 'Tienda',
      TipoAlmacen.deposito => 'Depósito',
      TipoAlmacen.transito => 'Tránsito',
    };
  }

  static TipoAlmacen fromStorage(String raw) {
    return TipoAlmacen.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => TipoAlmacen.tienda,
    );
  }
}

class Almacen {
  const Almacen({
    this.id,
    required this.codigo,
    required this.nombre,
    this.tipo = TipoAlmacen.tienda,
    this.direccion,
    this.telefono,
    this.responsable,
    this.activo = true,
    this.creadoEn,
    this.actualizadoEn,
    this.stockTotal = 0,
    this.skus = 0,
  });

  final int? id;
  final String codigo;
  final String nombre;
  final TipoAlmacen tipo;
  final String? direccion;
  final String? telefono;
  final String? responsable;
  final bool activo;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;
  final double stockTotal;
  final int skus;

  bool get esPrincipal => tipo == TipoAlmacen.principal;

  Almacen copyWith({
    int? id,
    String? codigo,
    String? nombre,
    TipoAlmacen? tipo,
    String? direccion,
    String? telefono,
    String? responsable,
    bool? activo,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
    double? stockTotal,
    int? skus,
  }) {
    return Almacen(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      responsable: responsable ?? this.responsable,
      activo: activo ?? this.activo,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      stockTotal: stockTotal ?? this.stockTotal,
      skus: skus ?? this.skus,
    );
  }
}
