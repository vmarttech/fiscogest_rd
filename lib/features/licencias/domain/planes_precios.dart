/// Precios y reglas por plan.
/// Móvil pago automático USD: simplificado 8.99 · basico 15.99.
/// Profesional/empresa: contacto FiscoGest (no self-serve móvil).
///
/// - demo: prueba 15 días, sin Fiao
/// - gratis: post-demo, límites duros + fiao ≤ 25
/// - simplificado: sin fiscal, fiao ≤ 50, 300/mes o 2990/año
/// - basico: modo normal sin Fiao ni crédito formal
/// - profesional | empresa: crédito formal, sin fiao
/// - desarrollador: sin límites
library;

/// Días de prueba demo al instalar.
const int kDiasPrueba = 15;

/// Días de gracia tras vencer (antes de pasar a gratis o bloquear escritura).
const int kDiasGracia = 3;

/// Días de validez de un pedido FG- sin confirmar pago.
const int kDiasExpiracionPedido = 7;

/// Precios USD — suscripción automática (PayPal). Solo móvil de pago.
const kPreciosLicenciaUsd = <String, Map<String, double>>{
  'simplificado': {'mensual': 8.99},
  'basico': {'mensual': 15.99},
};

/// DOP legacy (admin / referencia). El cobro móvil usa USD.
const kPreciosLicenciaDop = <String, Map<String, double>>{
  'simplificado': {'mensual': 300, 'anual': 2990},
  'basico': {'mensual': 1500, 'trimestral': 4050, 'anual': 14400},
  'profesional': {'mensual': 2500, 'trimestral': 6750, 'anual': 24000},
  'empresa': {'mensual': 4500, 'trimestral': 12150, 'anual': 43200},
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
    maxCuentasFiaoAbiertas: 0,
    permiteFiao: false,
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
    maxCuentasFiaoAbiertas: 0,
    permiteFiao: false,
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
    maxCuentasFiaoAbiertas: 0,
    permiteFiao: false,
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

double? precioPlanVigenciaUsd(String plan, String vigencia) {
  return kPreciosLicenciaUsd[plan]?[vigencia];
}

/// Monto USD mensual (simplificado 8.99 · basico 15.99).
double? precioMensualUsd(String plan) =>
    precioPlanVigenciaUsd(plan, 'mensual');

/// Planes de pago automático en móvil.
const kPlanesPagoMovil = <String>['simplificado', 'basico'];

bool esPlanPagoMovil(String plan) => kPlanesPagoMovil.contains(plan);


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
      return 'Sin impuestos · fiao hasta 50 · 1 dispositivo · US\$8.99/mes. Cancela cuando quieras.';
    case 'basico':
      return 'Modo normal · sin Fiao · 1 PC + 1 celular · US\$15.99/mes. Cancela cuando quieras.';
    case 'profesional':
      return 'Versión PC avanzada · crédito formal · e-CF. Contacte a FiscoGest.';
    case 'empresa':
      return 'Multi-equipo y acuerdo comercial. Contacte a FiscoGest.';
    default:
      return '';
  }
}
