/// Precios en DOP y reglas de producto por plan.
///
/// - demo: prueba 15 días
/// - gratis: post-demo, límites duros + fiao ≤ 25
/// - simplificado: sin fiscal, fiao ≤ 50, 300/mes o 2990/año
/// - basico: modo normal + fiao (no crédito formal)
/// - profesional | empresa: crédito formal, sin fiao
/// - desarrollador: sin límites
library;


/// Días de prueba demo al instalar.
const int kDiasPrueba = 15;

/// Días de gracia tras vencer (antes de pasar a gratis o bloquear escritura).
const int kDiasGracia = 3;

/// Días de validez de un pedido FG- sin confirmar pago.
const int kDiasExpiracionPedido = 7;

const kPreciosLicenciaDop = <String, Map<String, double>>{
  'simplificado': {
    'mensual': 300,
    'anual': 2990,
  },
  'basico': {
    'mensual': 1500,
    'trimestral': 4050,
    'anual': 14400,
  },
  'profesional': {
    'mensual': 2500,
    'trimestral': 6750,
    'anual': 24000,
  },
  'empresa': {
    'mensual': 4500,
    'trimestral': 12150,
    'anual': 43200,
  },
};

const kMaxCajasPorPlan = <String, int>{
  'demo': 1,
  'gratis': 1,
  'simplificado': 1,
  'basico': 1,
  'profesional': 3,
  'empresa': 99,
  'desarrollador': 999,
};

const kMaxDispositivosBase = <String, int>{
  'demo': 1,
  'gratis': 1,
  'simplificado': 1,
  'basico': 1,
  'profesional': 3,
  'empresa': 99,
  'desarrollador': 999,
};

/// Topes operativos (null = sin tope práctico en UI).
class LimitesPlan {
  const LimitesPlan({
    required this.maxProductos,
    required this.maxClientes,
    required this.maxVentasMes,
    required this.maxCuentasFiaoAbiertas,
    required this.permiteFiao,
    required this.permiteCreditoFormal,
    required this.permiteFiscal,
  });

  final int? maxProductos;
  final int? maxClientes;
  final int? maxVentasMes;
  final int? maxCuentasFiaoAbiertas;
  final bool permiteFiao;
  final bool permiteCreditoFormal;
  final bool permiteFiscal;
}

const kLimitesPorPlan = <String, LimitesPlan>{
  'demo': LimitesPlan(
    maxProductos: null,
    maxClientes: null,
    maxVentasMes: null,
    maxCuentasFiaoAbiertas: 100,
    permiteFiao: true,
    permiteCreditoFormal: true,
    permiteFiscal: true,
  ),
  'gratis': LimitesPlan(
    maxProductos: 50,
    maxClientes: 30,
    maxVentasMes: 40,
    maxCuentasFiaoAbiertas: 25,
    permiteFiao: true,
    permiteCreditoFormal: false,
    permiteFiscal: false,
  ),
  'simplificado': LimitesPlan(
    maxProductos: 200,
    maxClientes: 150,
    maxVentasMes: 200,
    maxCuentasFiaoAbiertas: 50,
    permiteFiao: true,
    permiteCreditoFormal: false,
    permiteFiscal: false,
  ),
  'basico': LimitesPlan(
    maxProductos: null,
    maxClientes: null,
    maxVentasMes: null,
    maxCuentasFiaoAbiertas: 200,
    permiteFiao: true,
    permiteCreditoFormal: false,
    permiteFiscal: true,
  ),
  'profesional': LimitesPlan(
    maxProductos: null,
    maxClientes: null,
    maxVentasMes: null,
    maxCuentasFiaoAbiertas: 0,
    permiteFiao: false,
    permiteCreditoFormal: true,
    permiteFiscal: true,
  ),
  'empresa': LimitesPlan(
    maxProductos: null,
    maxClientes: null,
    maxVentasMes: null,
    maxCuentasFiaoAbiertas: 0,
    permiteFiao: false,
    permiteCreditoFormal: true,
    permiteFiscal: true,
  ),
  'desarrollador': LimitesPlan(
    maxProductos: null,
    maxClientes: null,
    maxVentasMes: null,
    maxCuentasFiaoAbiertas: null,
    permiteFiao: true,
    permiteCreditoFormal: true,
    permiteFiscal: true,
  ),
};

LimitesPlan limitesDe(String plan) =>
    kLimitesPorPlan[plan] ?? kLimitesPorPlan['gratis']!;

bool esPlanNormal(String plan) {
  return plan == 'basico' ||
      plan == 'profesional' ||
      plan == 'empresa' ||
      plan == 'desarrollador' ||
      plan == 'demo';
}

bool esPlanSimplificado(String plan) => plan == 'simplificado';

bool esPlanGratis(String plan) => plan == 'gratis';

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
  if (esPlanSimplificado(plan) || esPlanGratis(plan)) return false;
  return plan != 'demo'; // demo prueba fiscal; emisión real según config
}

bool planPermiteFiao(String plan) => limitesDe(plan).permiteFiao;

bool planPermiteCreditoFormal(String plan) =>
    limitesDe(plan).permiteCreditoFormal;

/// Cupo instalaciones (PC + 1 móvil gratis en normal de pago).
int maxInstalacionesPermitidas(String plan) {
  final base = kMaxDispositivosBase[plan] ?? 1;
  if (esPlanNormal(plan) && plan != 'demo') {
    return base + 1; // 1 celular gratis
  }
  return base;
}

double? precioPlanVigencia(String plan, String vigencia) {
  return kPreciosLicenciaDop[plan]?[vigencia];
}

List<String> vigenciasDisponiblesParaPlan(String plan) {
  final m = kPreciosLicenciaDop[plan];
  if (m == null) return const [];
  return m.keys.toList();
}

String descripcionPlanCorta(String plan) {
  switch (plan) {
    case 'gratis':
      return 'Post-prueba · límites · fiao hasta 25 cuentas.';
    case 'simplificado':
      return 'Sin impuestos · fiao hasta 50 · 1 dispositivo · RD\$300/mes o 2.990/año.';
    case 'basico':
      return 'Modo normal · fiao · 1 PC + 1 celular gratis.';
    case 'profesional':
      return 'Crédito formal · e-CF · sin fiao · hasta 3 equipos + móvil.';
    case 'empresa':
      return 'Crédito formal · e-CF · sin fiao · equipos según acuerdo.';
    default:
      return '';
  }
}
