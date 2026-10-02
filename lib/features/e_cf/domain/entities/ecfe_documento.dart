import 'package:fiscogest_rd/features/e_cf/domain/enums/estado_ecf_interno.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/tipo_ecf.dart';

/// Comprobante electrónico en pipeline. No modifica la venta comercial.
class EcfeDocumento {
  const EcfeDocumento({
    this.id,
    this.ventaId,
    required this.tipoEcf,
    this.encf,
    required this.estado,
    this.trackId,
    this.codigoRespuesta,
    this.mensajeDgii,
    this.ultimoError,
    required this.creadoEn,
    this.actualizadoEn,
  });

  final int? id;
  /// Referencia opcional a ventas_table.id — solo lectura lateral.
  final int? ventaId;
  final TipoEcf tipoEcf;
  final String? encf;
  final EstadoEcfInterno estado;
  final String? trackId;
  final String? codigoRespuesta;
  final String? mensajeDgii;
  final String? ultimoError;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;
}
