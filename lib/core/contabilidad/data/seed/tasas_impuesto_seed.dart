/// Tasas de referencia F0 (bps). No van en el motor: solo semilla/datos.
/// 1800 = 18.00% ITBIS general RD. MX/PR se amplían en F2.
class TasaImpuestoSeed {
  const TasaImpuestoSeed({
    required this.codigo,
    required this.paisCodigo,
    required this.tasaBps,
    required this.descripcion,
  });

  final String codigo;
  final String paisCodigo;
  final int tasaBps;
  final String descripcion;
}

class TasasImpuestoSeedCatalogo {
  static const List<TasaImpuestoSeed> doRd = [
    TasaImpuestoSeed(
      codigo: 'ITBIS_GEN',
      paisCodigo: 'DO',
      tasaBps: 1800,
      descripcion: 'ITBIS general 18%',
    ),
    TasaImpuestoSeed(
      codigo: 'ITBIS_RED',
      paisCodigo: 'DO',
      tasaBps: 1100,
      descripcion: 'ITBIS reducido 11%',
    ),
    TasaImpuestoSeed(
      codigo: 'ITBIS_EXE',
      paisCodigo: 'DO',
      tasaBps: 0,
      descripcion: 'ITBIS exento',
    ),
  ];

  static List<TasaImpuestoSeed> porPais(String pais) {
    switch (pais.toUpperCase()) {
      case 'DO':
        return doRd;
      default:
        return doRd; // F0: fallback; F2 semillas MX/PR
    }
  }

  /// Redondeo al centavo (plano §8): (base * bps + 5000) ~/ 10000
  static int montoCents(int baseCents, int tasaBps) =>
      (baseCents * tasaBps + 5000) ~/ 10000;
}
