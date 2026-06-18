class Producto {
  final int? id;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final double precioCompra;
  final double gastosTransporte;
  final double gastosVarios;
  final double precioVenta;
  final double margenGanancia;
  final double valorITBIS;
  final double porcentajeImpuesto;
  final bool aplicaImpuesto;
  final String categoria;
  final String regimenImpuesto;
  final bool esImpuestoSelectivo;

  // ✅ CAMPOS ACTUALIZADOS Y HOMOLOGADOS
  final String unidadMedida;
  final bool permiteDecimales;
  final dynamic stockActual;
  final dynamic stockMinimo;
  final DateTime fechaRegistro;

  Producto({
    this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.precioCompra,
    required this.gastosTransporte,
    required this.gastosVarios,
    required this.precioVenta,
    required this.margenGanancia,
    required this.valorITBIS,
    required this.porcentajeImpuesto,
    required this.aplicaImpuesto,
    required this.categoria,
    required this.regimenImpuesto,
    required this.esImpuestoSelectivo,
    required this.unidadMedida,
    required this.permiteDecimales,
    required this.stockActual,
    required this.stockMinimo,
    required this.fechaRegistro,
  });

  // =====================================================
  // ✅ LISTA DE UNIDADES DE MEDIDA (ESTÁNDAR + OTRA)
  // =====================================================
  static const List<String> listaUnidadesMedida = [
    'UNIDAD',
    'PIEZA',
    'CAJA',
    'PAQUETE',
    'DOCENA',
    'BOTELLA',
    'LATA',
    'FARDO',
    'SACO',
    'ROLLO',
    'LITRO',
    'MILILITRO',
    'KILO',
    'LIBRA',
    'GRAMO',
    'GALÓN',
    'METRO',
    'CENTÍMETRO',
    'OTRA...',
  ];

  // =====================================================
  // ✅ LÓGICA DECIMALES/ENTEROS (ALINEADO CON FORMULARIO)
  // =====================================================
  static bool verificarSiPermiteDecimales(String unidad) {
    const unidadesQuePermitenDecimales = [
      'LITRO',
      'MILILITRO',
      'KILO',
      'LIBRA',
      'GRAMO',
      'GALÓN',
      'METRO',
      'CENTÍMETRO',
    ];
    return unidadesQuePermitenDecimales.contains(unidad.toUpperCase());
  }

  // =====================================================
  // ✅ RÉGIMENES FISCALES DGII (COMPLETOS Y DESCRIPCIÓN)
  // =====================================================
  static const List<Map<String, dynamic>> listaRegimenesRD = [
    {
      'nombre': 'GENERAL (ITBIS 18%)',
      'tasa': 18.0,
      'aplicaImpuesto': true,
      'esSelectivo': false,
      'descripcion': 'Régimen general aplicable a la mayoría de bienes y servicios.'
    },
    {
      'nombre': 'BIENES EXENTOS',
      'tasa': 0.0,
      'aplicaImpuesto': false,
      'esSelectivo': false,
      'descripcion': 'Productos básicos, alimentos, medicinas y bienes exentos por ley.'
    },
    {
      'nombre': 'SERVICIOS EXENTOS',
      'tasa': 0.0,
      'aplicaImpuesto': false,
      'esSelectivo': false,
      'descripcion': 'Servicios educativos, salud, transporte y otros exentos.'
    },
    {
      'nombre': 'ITBIS 16% (REDUCIDO)',
      'tasa': 16.0,
      'aplicaImpuesto': true,
      'esSelectivo': false,
      'descripcion': 'Tasa reducida aplicable a ciertos productos regulados.'
    },
    {
      'nombre': 'ITBIS 8% (REDUCIDO)',
      'tasa': 8.0,
      'aplicaImpuesto': true,
      'esSelectivo': false,
      'descripcion': 'Tasa especial para productos específicos.'
    },
    {
      'nombre': 'IMPUESTO SELECTIVO AL CONSUMO - ALCOHOL',
      'tasa': 20.0,
      'aplicaImpuesto': true,
      'esSelectivo': true,
      'descripcion': 'Aplicable a bebidas alcohólicas según normativa DGII.'
    },
    {
      'nombre': 'IMPUESTO SELECTIVO AL CONSUMO - TABACO',
      'tasa': 30.0,
      'aplicaImpuesto': true,
      'esSelectivo': true,
      'descripcion': 'Aplicable a productos de tabaco.'
    },
    {
      'nombre': 'IMPUESTO SELECTIVO AL CONSUMO - GASOLINA',
      'tasa': 15.0,
      'aplicaImpuesto': true,
      'esSelectivo': true,
      'descripcion': 'Combustibles y derivados del petróleo.'
    },
  ];

  // =====================================================
  // ✅ CONVERSIÓN DESDE MAPA (LECTURA BD)
  // ✅ VALIDACIONES Y VALORES POR DEFECTO SEGUROS
  // =====================================================
  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'],
      codigo: map['codigo'] ?? '',
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'],
      precioCompra: (map['precioCompra'] ?? 0.0).toDouble(),
      gastosTransporte: (map['gastosTransporte'] ?? 0.0).toDouble(),
      gastosVarios: (map['gastosVarios'] ?? 0.0).toDouble(),
      precioVenta: (map['precioVenta'] ?? 0.0).toDouble(),
      margenGanancia: (map['margenGanancia'] ?? 0.0).toDouble(),
      valorITBIS: (map['valorITBIS'] ?? 0.0).toDouble(),
      porcentajeImpuesto: (map['porcentajeImpuesto'] ?? 0.0).toDouble(),
      // 👇 AJUSTE CLAVE: Convierte entero 1/0 a booleano
      aplicaImpuesto: (map['aplicaImpuesto'] is int) 
          ? map['aplicaImpuesto'] == 1 
          : (map['aplicaImpuesto'] ?? false),
      categoria: map['categoria'] ?? '',
      regimenImpuesto: map['regimenImpuesto'] ?? '',
      // 👇 AJUSTE CLAVE: Convierte entero 1/0 a booleano
      esImpuestoSelectivo: (map['esImpuestoSelectivo'] is int) 
          ? map['esImpuestoSelectivo'] == 1 
          : (map['esImpuestoSelectivo'] ?? false),
      unidadMedida: map['unidadMedida'] ?? 'UNIDAD',
      // 👇 AJUSTE CLAVE: Convierte entero 1/0 a booleano
      permiteDecimales: (map['permiteDecimales'] is int) 
          ? map['permiteDecimales'] == 1 
          : (map['permiteDecimales'] ?? false),
      stockActual: map['stockActual'] ?? 0,
      stockMinimo: map['stockMinimo'] ?? 0,
      fechaRegistro: map['fechaRegistro'] != null
          ? DateTime.parse(map['fechaRegistro'])
          : DateTime.now(),
    );
  }

  // =====================================================
  // ✅ CONVERSIÓN A MAPA (ESCRITURA BD)
  // ✅ CAMPOS ALINEADOS CON ESTRUCTURA DE TABLA
  // =====================================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'precioCompra': precioCompra,
      'gastosTransporte': gastosTransporte,
      'gastosVarios': gastosVarios,
      'precioVenta': precioVenta,
      'margenGanancia': margenGanancia,
      'valorITBIS': valorITBIS,
      'porcentajeImpuesto': porcentajeImpuesto,
      // 👇 AJUSTE CLAVE: Guarda booleano como entero 1 o 0 para SQLite
      'aplicaImpuesto': aplicaImpuesto ? 1 : 0,
      'categoria': categoria,
      'regimenImpuesto': regimenImpuesto,
      // 👇 AJUSTE CLAVE: Guarda booleano como entero 1 o 0 para SQLite
      'esImpuestoSelectivo': esImpuestoSelectivo ? 1 : 0,
      'unidadMedida': unidadMedida,
      // 👇 AJUSTE CLAVE: Guarda booleano como entero 1 o 0 para SQLite
      'permiteDecimales': permiteDecimales ? 1 : 0,
      'stockActual': stockActual,
      'stockMinimo': stockMinimo,
      'fechaRegistro': fechaRegistro.toIso8601String(),
    };
  }

  // =====================================================
  // ✅ COPY WITH (ESENCIAL PARA ACTUALIZACIONES)
  // ✅ COMPLETO Y SIN ERRORES
  // =====================================================
  Producto copyWith({
    int? id,
    String? codigo,
    String? nombre,
    String? descripcion,
    double? precioCompra,
    double? gastosTransporte,
    double? gastosVarios,
    double? precioVenta,
    double? margenGanancia,
    double? valorITBIS,
    double? porcentajeImpuesto,
    bool? aplicaImpuesto,
    String? categoria,
    String? regimenImpuesto,
    bool? esImpuestoSelectivo,
    String? unidadMedida,
    bool? permiteDecimales,
    dynamic stockActual,
    dynamic stockMinimo,
    DateTime? fechaRegistro,
  }) {
    return Producto(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precioCompra: precioCompra ?? this.precioCompra,
      gastosTransporte: gastosTransporte ?? this.gastosTransporte,
      gastosVarios: gastosVarios ?? this.gastosVarios,
      precioVenta: precioVenta ?? this.precioVenta,
      margenGanancia: margenGanancia ?? this.margenGanancia,
      valorITBIS: valorITBIS ?? this.valorITBIS,
      porcentajeImpuesto: porcentajeImpuesto ?? this.porcentajeImpuesto,
      aplicaImpuesto: aplicaImpuesto ?? this.aplicaImpuesto,
      categoria: categoria ?? this.categoria,
      regimenImpuesto: regimenImpuesto ?? this.regimenImpuesto,
      esImpuestoSelectivo: esImpuestoSelectivo ?? this.esImpuestoSelectivo,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      permiteDecimales: permiteDecimales ?? this.permiteDecimales,
      stockActual: stockActual ?? this.stockActual,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }
}