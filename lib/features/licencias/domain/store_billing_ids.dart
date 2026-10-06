/// IDs de producto en Google Play Console (y análogos Samsung).
/// Créalos en la consola *antes* de habilitar compras reales.
///
/// Convención sugerida (suscripciones):
///   fg_simplificado_mensual / fg_simplificado_anual
///   fg_basico_mensual / fg_basico_anual
///   fg_profesional_mensual / fg_profesional_anual
///   fg_empresa_mensual / fg_empresa_anual
library;

const kPlaySubscriptionIds = <String>[
  'fg_simplificado_mensual',
  'fg_simplificado_anual',
  'fg_basico_mensual',
  'fg_basico_anual',
  'fg_profesional_mensual',
  'fg_profesional_anual',
  'fg_empresa_mensual',
  'fg_empresa_anual',
];

/// Mapeo productId → (plan, vigencia) para activar LicenciaService.
const kPlayProductToPlan = <String, (String plan, String vigencia)>{
  'fg_simplificado_mensual': ('simplificado', 'mensual'),
  'fg_simplificado_anual': ('simplificado', 'anual'),
  'fg_basico_mensual': ('basico', 'mensual'),
  'fg_basico_anual': ('basico', 'anual'),
  'fg_profesional_mensual': ('profesional', 'mensual'),
  'fg_profesional_anual': ('profesional', 'anual'),
  'fg_empresa_mensual': ('empresa', 'mensual'),
  'fg_empresa_anual': ('empresa', 'anual'),
};
