/// Tasas en basis points (1800 = 18.00%). Multi-país DO / MX / PR.
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
  static const doRd = <TasaImpuestoSeed>[
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

  static const mx = <TasaImpuestoSeed>[
    TasaImpuestoSeed(
      codigo: 'IVA_GEN',
      paisCodigo: 'MX',
      tasaBps: 1600,
      descripcion: 'IVA general 16%',
    ),
    TasaImpuestoSeed(
      codigo: 'IVA_EXE',
      paisCodigo: 'MX',
      tasaBps: 0,
      descripcion: 'IVA exento / 0%',
    ),
  ];

  static const pr = <TasaImpuestoSeed>[
    TasaImpuestoSeed(
      codigo: 'IVU_GEN',
      paisCodigo: 'PR',
      tasaBps: 1150,
      descripcion: 'IVU general 11.5%',
    ),
    TasaImpuestoSeed(
      codigo: 'IVU_EXE',
      paisCodigo: 'PR',
      tasaBps: 0,
      descripcion: 'IVU exento',
    ),
  ];

  static List<TasaImpuestoSeed> porPais(String pais) {
    switch (pais.toUpperCase()) {
      case 'MX':
        return mx;
      case 'PR':
        return pr;
      case 'DO':
      default:
        return doRd;
    }
  }

  /// Redondeo al centavo: (base * bps + 5000) ~/ 10000
  static int montoCents(int baseCents, int tasaBps) =>
      (baseCents * tasaBps + 5000) ~/ 10000;
}
