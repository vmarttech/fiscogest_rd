class Producto {
  // CAMPOS ORIGINALES - MANTENIDOS AL 100%
  final int? id;
  final String codigo;
  final String nombre;
  final String? descripcion;        
  final double precioCompra;        
  final double precioVenta;
  final double margenGanancia;
  final double valorITBIS;          
  final double porcentajeImpuesto;  
  final bool aplicaImpuesto;        
  final int stockActual;
  final int stockMinimo;
  final String unidadMedida;
  final DateTime fechaRegistro;

  // CAMPOS NUEVOS - FISCAL RD (COMPATIBLES, OPCIONALES)
  final double gastosTransporte;
  final double gastosVarios;
  final String categoria;           
  final double impuestoAdicional;   

  Producto({
    this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.precioCompra,
    required this.precioVenta,
    required this.margenGanancia,
    required this.valorITBIS,
    required this.porcentajeImpuesto,
    required this.aplicaImpuesto,
    this.gastosTransporte = 0.0,    
    this.gastosVarios = 0.0,        
    this.categoria = 'GENERAL',     
    this.impuestoAdicional = 0.0,
    required this.stockActual,
    required this.stockMinimo,
    required this.unidadMedida,
    required this.fechaRegistro,
  });

  // COYWITH - COMPLETO Y VERIFICADO
  Producto copyWith({
    int? id,
    String? codigo,
    String? nombre,
    String? descripcion,
    double? precioCompra,
    double? precioVenta,
    double? margenGanancia,
    double? valorITBIS,
    double? porcentajeImpuesto,
    bool? aplicaImpuesto,
    double? gastosTransporte,
    double? gastosVarios,
    String? categoria,
    double? impuestoAdicional,
    int? stockActual,
    int? stockMinimo,
    String? unidadMedida,
    DateTime? fechaRegistro,
  }) {
    return Producto(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precioCompra: precioCompra ?? this.precioCompra,
      precioVenta: precioVenta ?? this.precioVenta,
      margenGanancia: margenGanancia ?? this.margenGanancia,
      valorITBIS: valorITBIS ?? this.valorITBIS,
      porcentajeImpuesto: porcentajeImpuesto ?? this.porcentajeImpuesto,
      aplicaImpuesto: aplicaImpuesto ?? this.aplicaImpuesto,
      gastosTransporte: gastosTransporte ?? this.gastosTransporte,
      gastosVarios: gastosVarios ?? this.gastosVarios,
      categoria: categoria ?? this.categoria,
      impuestoAdicional: impuestoAdicional ?? this.impuestoAdicional,
      stockActual: stockActual ?? this.stockActual,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }

  // MAPEO A BASE DE DATOS - ALINEADO CON TUS NOMBRES DE COLUMNAS
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'precioCosto': precioCompra,
      'gastosTransporte': gastosTransporte,
      'gastosVarios': gastosVarios,
      'margenGanancia': margenGanancia,
      'precioVenta': precioVenta,
      'categoria': categoria,
      'exentoITBIS': aplicaImpuesto ? 0 : 1, // TU LÓGICA: 0=Aplica, 1=Exento
      'itbis': porcentajeImpuesto,
      'impuestoAdicional': impuestoAdicional,
      'stockActual': stockActual,
      'stockMinimo': stockMinimo,
      'unidadMedida': unidadMedida,
      'fechaRegistro': fechaRegistro.toIso8601String(),
    };
  }

  // MAPEO DESDE BASE DE DATOS - TRADUCCIÓN CORRECTA
  static Producto fromMap(Map<String, dynamic> map) {
    final bool exento = (map['exentoITBIS'] ?? 0) == 1;
    
    return Producto(
      id: map['id'],
      codigo: map['codigo'],
      nombre: map['nombre'],
      descripcion: map['descripcion'],
      precioCompra: (map['precioCosto'] ?? 0.0) as double,
      gastosTransporte: (map['gastosTransporte'] ?? 0.0) as double,
      gastosVarios: (map['gastosVarios'] ?? 0.0) as double,
      margenGanancia: (map['margenGanancia'] ?? 0.0) as double,
      precioVenta: (map['precioVenta'] ?? 0.0) as double,
      categoria: map['categoria'] ?? (exento ? 'EXENTO' : 'GENERAL'),
      aplicaImpuesto: !exento,
      porcentajeImpuesto: exento ? 0.0 : (map['itbis'] ?? 18.0) as double,
      impuestoAdicional: (map['impuestoAdicional'] ?? 0.0) as double,
      valorITBIS: _calcularValorITBIS(
        precioVenta: (map['precioVenta'] ?? 0.0) as double,
        porcentaje: exento ? 0.0 : (map['itbis'] ?? 18.0) as double,
      ),
      stockActual: (map['stockActual'] ?? 0) as int,
      stockMinimo: (map['stockMinimo'] ?? 5) as int,
      unidadMedida: map['unidadMedida'] ?? 'UNIDAD',
      fechaRegistro: DateTime.parse(map['fechaRegistro']),
    );
  }

  // FÓRMULA OFICIAL DGII - VERIFICADA
  static double _calcularValorITBIS({
    required double precioVenta,
    required double porcentaje,
  }) {
    if (precioVenta <= 0 || porcentaje <= 0) return 0.0;
    return precioVenta - (precioVenta / (1 + (porcentaje / 100)));
  }
}