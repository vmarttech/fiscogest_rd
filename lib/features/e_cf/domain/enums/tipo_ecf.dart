/// Tipos de e-CF según nomenclatura DGII (RD).
enum TipoEcf {
  facturaCreditoFiscal(31, 'Factura de Crédito Fiscal Electrónica'),
  facturaConsumo(32, 'Factura de Consumo Electrónica'),
  notaDebito(33, 'Nota de Débito Electrónica'),
  notaCredito(34, 'Nota de Crédito Electrónica'),
  compras(41, 'Compras Electrónico'),
  gastosMenores(43, 'Gastos Menores Electrónico'),
  regimenesEspeciales(44, 'Regímenes Especiales Electrónico'),
  gubernamental(45, 'Gubernamental Electrónico'),
  exportacion(46, 'Exportación Electrónico'),
  pagosExterior(47, 'Pagos al Exterior Electrónico');

  const TipoEcf(this.codigo, this.descripcion);
  final int codigo;
  final String descripcion;

  static TipoEcf? fromCodigo(int c) {
    for (final t in values) {
      if (t.codigo == c) return t;
    }
    return null;
  }

  /// Mapeo orientativo desde NCF serie B local (no envía nada a DGII).
  static TipoEcf? desdeTipoNcfLocal(String tipoNcf) {
    switch (tipoNcf.toUpperCase()) {
      case 'B01':
        return TipoEcf.facturaCreditoFiscal;
      case 'B02':
        return TipoEcf.facturaConsumo;
      case 'B03':
        return TipoEcf.notaDebito;
      case 'B04':
        return TipoEcf.notaCredito;
      case 'B11':
        return TipoEcf.compras;
      case 'B13':
        return TipoEcf.gastosMenores;
      case 'B14':
        return TipoEcf.regimenesEspeciales;
      default:
        return null;
    }
  }
}
