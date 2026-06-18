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
  // ✅ FUNCIONES AUXILIARES → BAJAN LA COMPLEJIDAD
  // =====================================================
  static int? _optInt(int? nuevo, int? actual) => nuevo ?? actual;
  static String _optStr(String? nuevo, String actual) => nuevo ?? actual;
  static double _optDouble(double? nuevo, double actual) => nuevo ?? actual;
  static bool _optBool(bool? nuevo, bool actual) => nuevo ?? actual;
  static dynamic _optDin(dynamic nuevo, dynamic actual) => nuevo ?? actual;
  static DateTime _optDate(DateTime? nuevo, DateTime actual) => nuevo ?? actual;

  // =====================================================
  // ✅ fromMap → Complejidad baja
  // =====================================================
  factory Producto.fromMap(Map<String, dynamic> map) {
    int? readInt(String key) => map[key] as int?;
    String readStr(String key, [String def = '']) => map[key] as String? ?? def;
    double readDbl(String key, [double def = 0.0]) => (map[key] as num?)?.toDouble() ?? def;
    bool readBool(String key, [bool def = false]) {
      final v = map[key];
      return v is int ? v == 1 : (v as bool? ?? def);
    }
    dynamic readStock(String key) => map[key] ?? 0;
    DateTime readDate(String key) {
      final s = map[key] as String?;
      return s != null ? DateTime.parse(s) : DateTime.now();
    }

    return Producto(
      id: readInt('id'),
      codigo: readStr('codigo'),
      nombre: readStr('nombre'),
      descripcion: map['descripcion'] as String?,
      precioCompra: readDbl('precioCompra'),
      gastosTransporte: readDbl('gastosTransporte'),
      gastosVarios: readDbl('gastosVarios'),
      precioVenta: readDbl('precioVenta'),
      margenGanancia: readDbl('margenGanancia'),
      valorITBIS: readDbl('valorITBIS'),
      porcentajeImpuesto: readDbl('porcentajeImpuesto'),
      aplicaImpuesto: readBool('aplicaImpuesto'),
      categoria: readStr('categoria'),
      regimenImpuesto: readStr('regimenImpuesto'),
      esImpuestoSelectivo: readBool('esImpuestoSelectivo'),
      unidadMedida: readStr('unidadMedida', 'UNIDAD'),
      permiteDecimales: readBool('permiteDecimales'),
      stockActual: readStock('stockActual'),
      stockMinimo: readStock('stockMinimo'),
      fechaRegistro: readDate('fechaRegistro'),
    );
  }

  // =====================================================
  // ✅ toMap
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
      'aplicaImpuesto': aplicaImpuesto ? 1 : 0,
      'categoria': categoria,
      'regimenImpuesto': regimenImpuesto,
      'esImpuestoSelectivo': esImpuestoSelectivo ? 1 : 0,
      'unidadMedida': unidadMedida,
      'permiteDecimales': permiteDecimales ? 1 : 0,
      'stockActual': stockActual,
      'stockMinimo': stockMinimo,
      'fechaRegistro': fechaRegistro.toIso8601String(),
    };
  }

  // =====================================================
  // ✅ copyWith → AHORA COMPLEJIDAD < 20
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
      id: _optInt(id, this.id),
      codigo: _optStr(codigo, this.codigo),
      nombre: _optStr(nombre, this.nombre),
      descripcion: descripcion ?? this.descripcion,
      precioCompra: _optDouble(precioCompra, this.precioCompra),
      gastosTransporte: _optDouble(gastosTransporte, this.gastosTransporte),
      gastosVarios: _optDouble(gastosVarios, this.gastosVarios),
      precioVenta: _optDouble(precioVenta, this.precioVenta),
      margenGanancia: _optDouble(margenGanancia, this.margenGanancia),
      valorITBIS: _optDouble(valorITBIS, this.valorITBIS),
      porcentajeImpuesto: _optDouble(porcentajeImpuesto, this.porcentajeImpuesto),
      aplicaImpuesto: _optBool(aplicaImpuesto, this.aplicaImpuesto),
      categoria: _optStr(categoria, this.categoria),
      regimenImpuesto: _optStr(regimenImpuesto, this.regimenImpuesto),
      esImpuestoSelectivo: _optBool(esImpuestoSelectivo, this.esImpuestoSelectivo),
      unidadMedida: _optStr(unidadMedida, this.unidadMedida),
      permiteDecimales: _optBool(permiteDecimales, this.permiteDecimales),
      stockActual: _optDin(stockActual, this.stockActual),
      stockMinimo: _optDin(stockMinimo, this.stockMinimo),
      fechaRegistro: _optDate(fechaRegistro, this.fechaRegistro),
    );
  }

  // =====================================================
  // ✅ CÁLCULOS Y DATOS ESTÁTICOS (SIN CAMBIOS)
  // =====================================================
  double get costoRealSinImpuesto => precioCompra + gastosTransporte + gastosVarios;

  double get totalImpuestos {
    if (!aplicaImpuesto) return 0.0;
    return costoRealSinImpuesto * (porcentajeImpuesto / 100);
  }

  double get costoRealConImpuesto => costoRealSinImpuesto + totalImpuestos;

  double get precioVentaSugerido {
    if (costoRealConImpuesto <= 0) return 0.0;
    return costoRealConImpuesto * (1 + (margenGanancia / 100));
  }

  double get gananciaNeta => precioVenta - costoRealConImpuesto;

  double get porcentajeGananciaReal {
    if (precioVenta <= 0) return 0.0;
    return ((gananciaNeta / precioVenta) * 100).clamp(0.0, 100.0);
  }

  static const List<String> listaUnidadesMedida = [
    'UNIDAD', 'PIEZA', 'CAJA', 'PAQUETE', 'DOCENA', 'BOTELLA', 'LATA',
    'FARDO', 'SACO', 'ROLLO', 'LITRO', 'MILILITRO', 'KILO', 'LIBRA',
    'GRAMO', 'GALÓN', 'METRO', 'CENTÍMETRO', 'OTRA...',
  ];

  static bool verificarSiPermiteDecimales(String unidad) {
    const unidades = ['LITRO', 'MILILITRO', 'KILO', 'LIBRA', 'GRAMO', 'GALÓN', 'METRO', 'CENTÍMETRO'];
    return unidades.contains(unidad.toUpperCase());
  }

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
}