/// Precios v1 en DOP.
///
/// - simplificado: un solo pago ANUAL (vendedores ambulantes, sin fiscal).
/// - basico | profesional | empresa: modo NORMAL (tras prueba 15 días).
const kPreciosLicenciaDop = <String, Map<String, double>>{
  /// Solo anual. Mensual/trimestral/semestral no se ofrecen en UI.
  'simplificado': {
    'anual': 2990,
  },
  'basico': {
    'mensual': 1500,
    'trimestral': 4050,
    'semestral': 7650,
    'anual': 13500,
  },
  'profesional': {
    'mensual': 2500,
    'trimestral': 6750,
    'semestral': 12750,
    'anual': 22500,
  },
  'empresa': {
    'mensual': 4500,
    'trimestral': 12150,
    'semestral': 22950,
    'anual': 40500,
  },
};

const kMaxCajasPorPlan = <String, int>{
  'demo': 1,
  'simplificado': 1,
  'basico': 1,
  'profesional': 3,
  'empresa': 99,
  'desarrollador': 999,
};

/// Dispositivos de pago del plan (PC/caja).
/// El móvil gratuito del modo Normal NO suma aquí: va en [kMovilGratisModoNormal].
const kMaxDispositivosPorPlan = <String, int>{
  'demo': 1,
  'simplificado': 1,
  'basico': 1,
  'profesional': 3,
  'empresa': 99,
  'desarrollador': 999,
};

/// 1 celular adicional sin costo si el negocio ya tiene modo NORMAL activo.
const kMovilGratisModoNormal = 1;

const kDiasPrueba = 15;
const kDiasGracia = 3;
const kDiasExpiracionPedido = 7;

bool esPlanNormal(String plan) {
  return plan == 'basico' ||
      plan == 'profesional' ||
      plan == 'empresa' ||
      plan == 'desarrollador' ||
      plan == 'demo';
}

bool esPlanSimplificado(String plan) => plan == 'simplificado';

/// Simplificado: sin impuestos ni e-CF ni NCF.
bool planIncluyeEcf(String plan) {
  switch (plan) {
    case 'profesional':
    case 'empresa':
    case 'desarrollador':
      return true;
    default:
      return false;
  }
}

bool planPermiteModuloFiscal(String plan) {
  if (esPlanSimplificado(plan)) return false;
  return plan != 'demo'; // demo puede mostrar fiscal limitado; emisión real según config
}

/// Cupo total de instalaciones (PC + móvil gratis si Normal).
int maxInstalacionesPermitidas(String plan) {
  final base = kMaxDispositivosPorPlan[plan] ?? 1;
  if (esPlanNormal(plan) && plan != 'demo') {
    return base + kMovilGratisModoNormal;
  }
  return base;
}

double? precioPlanVigencia(String plan, String vigencia) {
  return kPreciosLicenciaDop[plan]?[vigencia];
}

List<String> vigenciasDisponiblesParaPlan(String plan) {
  if (esPlanSimplificado(plan)) return const ['anual'];
  return const ['mensual', 'trimestral', 'semestral', 'anual'];
}

String descripcionPlanCorta(String plan) {
  switch (plan) {
    case 'simplificado':
      return 'Sin impuestos ni facturación fiscal. Ideal vendedores ambulantes. '
          '1 dispositivo. Pago único anual RD\$2,990.';
    case 'basico':
      return 'Modo normal · 1 PC + 1 celular gratis con las mismas funciones.';
    case 'profesional':
      return 'Modo normal · hasta 3 equipos + 1 celular gratis · e-CF.';
    case 'empresa':
      return 'Modo normal · equipos según acuerdo + 1 celular gratis · e-CF.';
    default:
      return '';
  }
}
