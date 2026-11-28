/// Diccionario F0/F1 del módulo contable (prefijo acct_ / claves estables).
/// Migración a app_es.arb / app_en.arb cuando el paquete de idioma esté listo.
/// El dominio NUNCA importa este archivo.
class AcctStrings {
  AcctStrings._();

  // —— Home / navegación ——
  static const title = 'Contabilidad';
  static const homeSubtitle = 'Partida doble · plan de cuentas · asientos';
  static const openModule = 'Abrir contabilidad';
  static const refresh = 'Actualizar';
  static const countryLabel = 'País contable';
  static const periodLabel = 'Periodo fiscal';
  static const lockedByLicense = 'Contabilidad disponible solo en el plan Full';
  static const lockedByLicenseHint =
      'Actualiza tu plan para activar asientos, plan de cuentas y libros.';

  // —— Plan de cuentas ——
  static const accountsTitle = 'Plan de cuentas';
  static const accountCode = 'Código';
  static const accountName = 'Nombre';
  static const accountType = 'Tipo de cuenta';
  static const accountLeaf = 'Cuenta de movimiento';
  static const accountGroup = 'Cuenta de agrupación';
  static const accountActive = 'Activa';
  static const accountInactive = 'Inactiva';
  static const accountAddLeaf = 'Nueva cuenta hoja';
  static const accountDeactivate = 'Desactivar';
  static const accountActivate = 'Activar';
  static const accountSave = 'Guardar';
  static const accountsEmpty = 'No hay cuentas en el plan';
  static const natureDebit = 'Deudora';
  static const natureCredit = 'Acreedora';

  // —— Asientos ——
  static const entriesTitle = 'Asientos';
  static const entryNew = 'Nuevo asiento';
  static const entryDate = 'Fecha';
  static const entryConcept = 'Concepto';
  static const entryDebit = 'Debe';
  static const entryCredit = 'Haber';
  static const entryPost = 'Contabilizar';
  static const entryVoid = 'Anular con reversa';
  static const entryVoidReason = 'Motivo de anulación';
  static const entryDetail = 'Detalle del asiento';
  static const entryLines = 'Líneas';
  static const entryAddLine = 'Agregar línea';
  static const entryRemoveLine = 'Quitar línea';
  static const entryNumber = 'Número';
  static const entryStatus = 'Estado';
  static const emptyEntries = 'No hay asientos registrados';
  static const entrySaved = 'Asiento contabilizado';
  static const entryVoided = 'Asiento anulado (reversa generada)';
  static const entryAmountHint = '0.00';

  // —— Libros ——
  static const journalTitle = 'Libro diario';
  static const ledgerTitle = 'Libro mayor';
  static const trialBalanceTitle = 'Balance de comprobación';
  static const booksFrom = 'Desde';
  static const booksTo = 'Hasta';

  // —— Periodo / errores (códigos del motor → texto UI) ——
  static const periodClosed = 'Periodo cerrado';
  static const errorUnbalanced =
      'El asiento no cuadra (debe distinto a haber)';
  static const errorLeafOnly =
      'Solo se puede movilizar una cuenta de último nivel';
  static const errorPeriodClosed =
      'El periodo está cerrado y no admite asientos';
  static const errorMissingLine =
      'La línea no tiene cuenta o monto válido';
  static const errorAccountInactive = 'La cuenta está inactiva';
  static const errorLicenseInactive =
      'Licencia inactiva o plan sin módulo contable';
  static const errorGeneric = 'No se pudo completar la operación contable';

  /// Traduce códigos acct_error_* del motor a texto de UI.

  static const booksTitle = 'Libros';
  static const filterFrom = 'Desde';
  static const filterTo = 'Hasta';
  static const filterApply = 'Aplicar';
  static const colAccount = 'Cuenta';
  static const colDebit = 'Debe';
  static const colCredit = 'Haber';
  static const colBalance = 'Saldo';
  static const booksEmpty = 'Sin movimientos en el rango';
  static const selectAccount = 'Elegir cuenta';


  // —— Alta de cuenta ——
  static const accountNew = 'Nueva cuenta hoja';
  static const accountParent = 'Cuenta padre';
  static const accountCreated = 'Cuenta creada';
  static const accountCodeExists = 'Ya existe ese código';
  static const accountParentRequired = 'Elige una cuenta padre (grupo)';

  static String fromErrorCode(String code) {
    final c = code.split(':').first;
    switch (c) {
      case 'acct_error_unbalanced':
        return errorUnbalanced;
      case 'acct_error_account_not_leaf':
      case 'acct_error_leaf_only':
        return errorLeafOnly;
      case 'acct_error_period_closed':
      case 'acct_error_period_closed_or_missing':
        return errorPeriodClosed;
      case 'acct_error_invalid_line':
      case 'acct_error_missing_line':
      case 'acct_error_min_lines':
      case 'acct_error_no_lines':
        return errorMissingLine;
      case 'acct_error_account_inactive':
        return errorAccountInactive;
      case 'acct_error_license_inactive':
        return errorLicenseInactive;
      default:
        return errorGeneric;
    }
  }
}
