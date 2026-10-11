class EcfePayload {
  const EcfePayload({
    required this.tipoEcfCodigo,
    required this.encf,
    this.encfReferencia,
    required this.fechaVencimientoSecuencia,
    required this.fechaEmision,
    required this.tipoIngresos,
    required this.tipoPago,
    required this.rncEmisor,
    required this.razonSocialEmisor,
    required this.direccionEmisor,
    this.telefonoEmisor,
    this.correoEmisor,
    this.rncComprador,
    this.razonSocialComprador,
    this.direccionComprador,
    required this.montoGravadoTotal,
    required this.totalItbis,
    required this.montoTotal,
    required this.tasaItbis,
    required this.items,
    this.formaPagoCodigo = '1',
    this.montoPago,
    this.montoGravadoI1 = 0,
    this.totalItbis1 = 0,
    this.montoGravadoI2 = 0,
    this.totalItbis2 = 0,
    this.montoGravadoI3 = 0,
    this.totalItbis3 = 0,
    this.esRfce = false,
    this.montoExento = 0,
    this.bandasItbis = false,
  });

  final int tipoEcfCodigo;
  final String encf;

  /// e-NCF modificado (obligatorio en NC 34 / ND 33).
  final String? encfReferencia;
  final String fechaVencimientoSecuencia;
  final String fechaEmision;
  final String tipoIngresos;
  final String tipoPago;
  final String rncEmisor;
  final String razonSocialEmisor;
  final String direccionEmisor;
  final String? telefonoEmisor;
  final String? correoEmisor;
  final String? rncComprador;
  final String? razonSocialComprador;
  final String? direccionComprador;
  final double montoGravadoTotal;
  final double totalItbis;
  final double montoTotal;
  final double tasaItbis;
  final List<EcfePayloadItem> items;
  final String formaPagoCodigo;
  final double? montoPago;
  final double montoGravadoI1;
  final double totalItbis1;
  final double montoGravadoI2;
  final double totalItbis2;
  final double montoGravadoI3;
  final double totalItbis3;
  final bool esRfce;
  final double montoExento;

  /// true = totales partidos (18 / 16 / exento). false = todo en ITBIS 1.
  final bool bandasItbis;
}

class EcfePayloadItem {
  const EcfePayloadItem({
    required this.numeroLinea,
    required this.nombreItem,
    required this.cantidad,
    required this.precioUnitario,
    required this.montoItem,
    required this.indicadorFacturacion,
    this.indicadorBienoServicio = '1',
    this.unidadMedida = 'UND',
  });

  final int numeroLinea;
  final String nombreItem;
  final double cantidad;
  final double precioUnitario;
  final double montoItem;
  final String indicadorFacturacion;
  final String indicadorBienoServicio;
  final String unidadMedida;
}
