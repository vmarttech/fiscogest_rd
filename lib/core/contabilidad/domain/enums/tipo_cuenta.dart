/// Tipo de cuenta contable según su naturaleza
enum TipoCuenta {
  activo,
  pasivo,
  patrimonio,
  ingreso,
  gasto,
  costo,
  resultado,
}

extension TipoCuentaOps on TipoCuenta {
  /// Naturaleza normal del saldo: débitos aumentan, créditos disminuyen
  bool get esDeudora => switch (this) {
        TipoCuenta.activo || TipoCuenta.gasto || TipoCuenta.costo => true,
        _ => false,
      };

  /// Naturaleza acreedora: los creditos aumentan y los debitos disminuyen.
  /// Pasivo, patrimonio, ingreso y resultado son acreedoras por defecto;
  /// un resultado con saldo deudor representa una perdida del ejercicio.
  bool get esAcreedora => !esDeudora;

  /// Clave de traducción para i18n
  String get claveI18n => switch (this) {
        TipoCuenta.activo => 'acct_type_asset',
        TipoCuenta.pasivo => 'acct_type_liability',
        TipoCuenta.patrimonio => 'acct_type_equity',
        TipoCuenta.ingreso => 'acct_type_income',
        TipoCuenta.gasto => 'acct_type_expense',
        TipoCuenta.costo => 'acct_type_cost',
        TipoCuenta.resultado => 'acct_type_result',
      };
}
