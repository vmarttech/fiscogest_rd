import 'package:fiscogest_rd/features/e_cf/domain/enums/tipo_ecf.dart';

/// Factura de Consumo Electrónica resumible (RFCE) según tope DGII.
class RfceRules {
  /// Tope en DOP para resumen RFCE (factura de consumo).
  static const double topeDop = 250000;

  static bool esCandidatoRfce({
    required TipoEcf tipo,
    required double total,
  }) {
    if (tipo != TipoEcf.facturaConsumo) return false;
    return total < topeDop;
  }

  static String etiqueta({
    required TipoEcf tipo,
    required double total,
  }) {
    if (esCandidatoRfce(tipo: tipo, total: total)) {
      return 'RFCE (consumo < RD\$250,000)';
    }
    return tipo.descripcion;
  }
}
