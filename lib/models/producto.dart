class Producto {
  // ✅ Constructor en el lugar correcto
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

  factory Producto.fromMap(Map<String, dynamic> map) {
    int? readInt(String key) => map[key] as int?;
    String readStr(String key, [String def = '']) => map[key] as String? ?? def;
    double readDbl(String key, [double def = 0.0]) =>
        (map[key] as num?)?.toDouble() ?? def;
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

  // ✅ Métodos auxiliares para copyWith
  static int? _optInt(int? nuevo, int? actual) => nuevo ?? actual;
  static String _optStr(String? nuevo, String actual) => nuevo ?? actual;
  static double _optDouble(double? nuevo, double actual) => nuevo ?? actual;
  static bool _optBool(bool? nuevo, bool actual) => nuevo ?? actual;
  static dynamic _optDin(dynamic nuevo, dynamic actual) => nuevo ?? actual;
  static DateTime _optDate(DateTime? nuevo, DateTime actual) => nuevo ?? actual;

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

  // ─────────────────────────────────────────────────────────────────
  // ✅ CÁLCULOS HOMOLOGADOS SEGÚN NORMATIVA DGII
  // ─────────────────────────────────────────────────────────────────

  /// 📌 Costo base sin impuestos: Precio de compra + transporte + gastos
  double get costoBase => precioCompra + gastosTransporte + gastosVarios;

  /// 📌 Impuesto que viene incluido en la compra (si es acreditable)
  double get impuestoEnCompra {
    if (!aplicaImpuesto || esImpuestoSelectivo) return 0.0;
    return precioCompra * (porcentajeImpuesto / 100);
  }

  /// 📌 Costo REAL para el comerciante:
  /// - Si es régimen general: se resta el ITBIS porque es acreditable
  /// - Si es exento o impuesto selectivo: se suma todo porque NO se puede descontar
  double get costoReal {
    if (!aplicaImpuesto) {
      // Bienes exentos: todo es costo
      return costoBase;
    }
    if (esImpuestoSelectivo) {
      // Impuesto selectivo: no es acreditable, pasa al costo
      return costoBase + valorITBIS;
    }
    // Régimen general: ITBIS es acreditable → se resta del costo
    return costoBase - impuestoEnCompra;
  }

  /// 📌 Base imponible para calcular el precio de venta
  double get baseImponible => costoReal * (1 + (margenGanancia / 100));

  /// 📌 Impuesto que se cobra al vender
  double get impuestoEnVenta {
    if (!aplicaImpuesto) return 0.0;
    return baseImponible * (porcentajeImpuesto / 100);
  }

  /// 📌 Precio final de venta al público
  double get precioVentaFinal => baseImponible + impuestoEnVenta;

  /// 📌 Ganancia neta real por unidad
  double get gananciaNetaReal => precioVentaFinal - costoReal;

  /// 📌 Porcentaje de ganancia real
  double get porcentajeGananciaReal {
    if (costoReal <= 0) return 0.0;
    return ((gananciaNetaReal / costoReal) * 100).clamp(0.0, 999.9);
  }

  /// 📌 Verificación de stock
  bool get estaBajoDeStock {
    final actual = num.tryParse(stockActual.toString()) ?? 0;
    final minimo = num.tryParse(stockMinimo.toString()) ?? 0;
    return actual <= minimo;
  }

  // ─────────────────────────────────────────────────────────────────
  // ✅ LISTAS Y MÉTODOS AUXILIARES
  // ─────────────────────────────────────────────────────────────────

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

  static bool verificarSiPermiteDecimales(String unidad) {
    const unidades = [
      'LITRO',
      'MILILITRO',
      'KILO',
      'LIBRA',
      'GRAMO',
      'GALÓN',
      'METRO',
      'CENTÍMETRO',
    ];
    return unidades.contains(unidad.toUpperCase());
  }

  static const List<Map<String, dynamic>> listaRegimenesRD = [
    {
      'nombre': 'GENERAL (ITBIS 18%)',
      'tasa': 18.0,
      'aplicaImpuesto': true,
      'esSelectivo': false,
      'descripcion': 'Régimen general: el ITBIS pagado en compras es acreditable.',
    },
    {
      'nombre': 'BIENES EXENTOS',
      'tasa': 0.0,
      'aplicaImpuesto': false,
      'esSelectivo': false,
      'descripcion': 'Alimentos, medicinas y bienes básicos: no generan ni permiten descuento de impuesto.',
    },
    {
      'nombre': 'SERVICIOS EXENTOS',
      'tasa': 0.0,
      'aplicaImpuesto': false,
      'esSelectivo': false,
      'descripcion': 'Servicios educativos, salud, transporte: sin impuesto.',
    },
    {
      'nombre': 'ITBIS 16% (REDUCIDO)',
      'tasa': 16.0,
      'aplicaImpuesto': true,
      'esSelectivo': false,
      'descripcion': 'Tasa reducida, el impuesto es acreditable.',
    },
    {
      'nombre': 'ITBIS 8% (REDUCIDO)',
      'tasa': 8.0,
      'aplicaImpuesto': true,
      'esSelectivo': false,
      'descripcion': 'Tasa especial, el impuesto es acreditable.',
    },
    {
      'nombre': 'IMPUESTO SELECTIVO - ALCOHOL',
      'tasa': 20.0,
      'aplicaImpuesto': true,
      'esSelectivo': true,
      'descripcion': 'Impuesto adicional NO acreditable, pasa al costo final.',
    },
    {
      'nombre': 'IMPUESTO SELECTIVO - TABACO',
      'tasa': 30.0,
      'aplicaImpuesto': true,
      'esSelectivo': true,
      'descripcion': 'Impuesto adicional NO acreditable, pasa al costo final.',
    },
    {
      'nombre': 'IMPUESTO SELECTIVO - COMBUSTIBLES',
      'tasa': 15.0,
      'aplicaImpuesto': true,
      'esSelectivo': true,
      'descripcion': 'Impuesto adicional NO acreditable, pasa al costo final.',
    },
  ];
}