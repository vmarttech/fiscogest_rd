/// Precios y reglas por plan — FiscoGest móvil.
///
/// Planes self-serve (USD / PayPal, activación automática):
///   gratis · basico · simplificado · pro
///
/// Prueba: 30 días al instalar (sin fricción). Al vencer → límites del plan actual
/// (si no pagó → gratis). Todo el menú visible; al usar sin derecho → aviso de upgrade.
library;

/// Días de prueba al instalar.
const int kDiasPrueba = 30;

/// Días de gracia tras vencer.
const int kDiasGracia = 3;

/// Días de validez de un pedido FG- sin confirmar (legado transferencia).
const int kDiasExpiracionPedido = 7;

/// Precios USD — suscripción móvil (PayPal). Solo mensual por ahora.
const kPreciosLicenciaUsd = <String, Map<String, double>>{
  'basico': {'mensual': 4.99},
  'simplificado': {'mensual': 9.99},
  'pro': {'mensual': 19.99},
};

/// DOP solo referencia admin / legado (no se muestra en compra móvil).
const kPreciosLicenciaDop = <String, Map<String, double>>{
  'basico': {'mensual': 4.99},
  'simplificado': {'mensual': 9.99},
  'pro': {'mensual': 19.99},
  'profesional': {'mensual': 19.99},
  'empresa': {'mensual': 45.00},
};

const kMaxCajasPorPlan = <String, int>{
  'demo': 1,
  'gratis': 1,
  'basico': 1,
  'simplificado': 3,
  'pro': 99,
  'profesional': 3,
  'empresa': 99,
  'desarrollador': 999,
};

const kMaxDispositivosBase = <String, int>{
  'demo': 1,
  'gratis': 1,
  'basico': 1,
  'simplificado': 3,
  'pro': 99,
  'profesional': 3,
  'empresa': 99,
  'desarrollador': 999,
};

class LimitesPlan {
  const LimitesPlan({
    required this.maxProductos,
    required this.maxClientes,
    required this.maxVentasMes,
    required this.maxCuentasFiaoAbiertas,
    required this.permiteFiao,
    required this.permiteCreditoFormal,
    required this.permiteFiscal,
    required this.permiteReportes,
    required this.permiteAlmacenes,
    required this.permiteUsuariosExtra,
    required this.permiteEcf,
  });

  final int? maxProductos;
  final int? maxClientes;
  /// null = sin tope práctico.
  final int? maxVentasMes;
  final int? maxCuentasFiaoAbiertas;
  final bool permiteFiao;
  final bool permiteCreditoFormal;
  final bool permiteFiscal;
  final bool permiteReportes;
  final bool permiteAlmacenes;
  final bool permiteUsuariosExtra;
  final bool permiteEcf;
}

/// Matriz móvil acordada.
const kLimitesPorPlan = <String, LimitesPlan>{
  // Prueba 30 días: acceso amplio.
  'demo': LimitesPlan(
    maxProductos: null,
    maxClientes: null,
    maxVentasMes: null,
    maxCuentasFiaoAbiertas: null,
    permiteFiao: true,
    permiteCreditoFormal: true,
    permiteFiscal: true,
    permiteReportes: true,
    permiteAlmacenes: true,
    permiteUsuariosExtra: true,
    permiteEcf: true,
  ),
  // Gratis: 30 ventas/mes, sin fiao (solo contado), sin reportes.
  'gratis': LimitesPlan(
    maxProductos: 40,
    maxClientes: 20,
    maxVentasMes: 30,
    maxCuentasFiaoAbiertas: 0,
    permiteFiao: false,
    permiteCreditoFormal: false,
    permiteFiscal: false,
    permiteReportes: false,
    permiteAlmacenes: false,
    permiteUsuariosExtra: false,
    permiteEcf: false,
  ),
  // Esencial US$4.99 — 300 facturas/mes, reportes basicos, sync nube, 1 equipo.
  'basico': LimitesPlan(
    maxProductos: null,
    maxClientes: null,
    maxVentasMes: 300,
    maxCuentasFiaoAbiertas: 25,
    permiteFiao: true,
    permiteCreditoFormal: false,
    permiteFiscal: false,
    permiteReportes: true,
    permiteAlmacenes: false,
    permiteUsuariosExtra: false,
    permiteEcf: false,
  ),
  // Avanzado US$9.99 — multi-equipo (3), fiao sin tope, reportes avanzados, sin fiscal.
  'simplificado': LimitesPlan(
    maxProductos: null,
    maxClientes: null,
    maxVentasMes: null,
    maxCuentasFiaoAbiertas: null,
    permiteFiao: true,
    permiteCreditoFormal: false,
    permiteFiscal: false,
    permiteReportes: true,
    permiteAlmacenes: false,
    permiteUsuariosExtra: false,
    permiteEcf: false,
  ),
  // Fiscal Pro US$19.99 — credito formal + fiscal DGII + almacenes + equipos.
  'pro': LimitesPlan(
    maxProductos: null,
    maxClientes: null,
    maxVentasMes: null,
    maxCuentasFiaoAbiertas: null,
    permiteFiao: false,
    permiteCreditoFormal: true,
    permiteFiscal: true,
    permiteReportes: true,
    permiteAlmacenes: true,
    permiteUsuariosExtra: true,
    permiteEcf: true,
  ),
  // Alias legado PC / admin
  'profesional': LimitesPlan(
    maxProductos: null,
    maxClientes: null,
    maxVentasMes: null,
    maxCuentasFiaoAbiertas: null,
    permiteFiao: false,
    permiteCreditoFormal: true,
    permiteFiscal: true,
    permiteReportes: true,
    permiteAlmacenes: true,
    permiteUsuariosExtra: true,
    permiteEcf: true,
  ),
  'empresa': LimitesPlan(
    maxProductos: null,
    maxClientes: null,
    maxVentasMes: null,
    maxCuentasFiaoAbiertas: null,
    permiteFiao: false,
    permiteCreditoFormal: true,
    permiteFiscal: true,
    permiteReportes: true,
    permiteAlmacenes: true,
    permiteUsuariosExtra: true,
    permiteEcf: true,
  ),
  'desarrollador': LimitesPlan(
    maxProductos: null,
    maxClientes: null,
    maxVentasMes: null,
    maxCuentasFiaoAbiertas: null,
    permiteFiao: true,
    permiteCreditoFormal: true,
    permiteFiscal: true,
    permiteReportes: true,
    permiteAlmacenes: true,
    permiteUsuariosExtra: true,
    permiteEcf: true,
  ),
};

LimitesPlan limitesDe(String plan) {
  final p = plan.toLowerCase().trim();
  return kLimitesPorPlan[p] ?? kLimitesPorPlan['gratis']!;
}

bool esPlanNormal(String plan) {
  final p = plan.toLowerCase();
  return p == 'basico' ||
      p == 'pro' ||
      p == 'profesional' ||
      p == 'empresa' ||
      p == 'desarrollador' ||
      p == 'demo';
}

bool esPlanSimplificado(String plan) => plan.toLowerCase() == 'simplificado';
bool esPlanGratis(String plan) => plan.toLowerCase() == 'gratis';
bool esPlanPro(String plan) {
  final p = plan.toLowerCase();
  return p == 'pro' || p == 'profesional' || p == 'empresa' || p == 'desarrollador';
}

bool planIncluyeEcf(String plan) => limitesDe(plan).permiteEcf;

bool planPermiteModuloFiscal(String plan) => limitesDe(plan).permiteFiscal;

bool planPermiteFiao(String plan) => limitesDe(plan).permiteFiao;

bool planPermiteCreditoFormal(String plan) =>
    limitesDe(plan).permiteCreditoFormal;

bool planPermiteReportes(String plan) => limitesDe(plan).permiteReportes;

bool planPermiteAlmacenes(String plan) => limitesDe(plan).permiteAlmacenes;

bool planPermiteUsuariosExtra(String plan) =>
    limitesDe(plan).permiteUsuariosExtra;

int maxInstalacionesPermitidas(String plan) {
  final p = plan.toLowerCase();
  return kMaxDispositivosBase[p] ?? 1;
}

double? precioPlanVigencia(String plan, String vigencia) {
  // Compra móvil: solo USD.
  return precioPlanVigenciaUsd(plan, vigencia);
}

double? precioPlanVigenciaUsd(String plan, String vigencia) {
  final p = plan.toLowerCase();
  return kPreciosLicenciaUsd[p]?[vigencia];
}

double? precioMensualUsd(String plan) =>
    precioPlanVigenciaUsd(plan, 'mensual');

/// Planes de pago automático en móvil (PayPal → activación inmediata).
const kPlanesPagoMovil = <String>['basico', 'simplificado', 'pro'];

bool esPlanPagoMovil(String plan) =>
    kPlanesPagoMovil.contains(plan.toLowerCase());

List<String> vigenciasDisponiblesParaPlan(String plan) {
  final m = kPreciosLicenciaUsd[plan.toLowerCase()];
  if (m == null) return const ['mensual'];
  return m.keys.toList();
}

/// Plan mínimo recomendado para una función (mensaje de upgrade).
String planMinimoPara(String funcion) {
  switch (funcion) {
    case 'reportes':
      return 'basico';
    case 'almacenes':
    case 'transferencias':
    case 'fiscal':
    case 'ecf':
    case 'credito_formal':
      return 'pro';
    case 'sync_nube':
      return 'basico';
    case 'multi_equipo':
    case 'usuarios':
    case 'reportes_avanzados':
    case 'import_export':
    case 'fiao':
      return 'simplificado';
    default:
      return 'pro';
  }
}

String nombrePlanUi(String plan) {
  switch (plan.toLowerCase()) {
    case 'demo':
      return 'Prueba';
    case 'gratis':
      return 'Gratis';
    case 'basico':
      return 'Esencial';
    case 'simplificado':
      return 'Avanzado';
    case 'pro':
    case 'profesional':
      return 'Fiscal Pro';
    case 'empresa':
      return 'Empresa';
    case 'desarrollador':
      return 'Desarrollador';
    default:
      return plan;
  }
}

String descripcionPlanCorta(String plan) {
  switch (plan.toLowerCase()) {
    case 'gratis':
      return 'Prueba el flujo, sin compromiso.';
    case 'basico':
      return 'Esencial: respaldo en la nube y reportes, 1 equipo.';
    case 'simplificado':
      return 'Avanzado: multi-equipo, fío sin tope y reportes avanzados.';
    case 'pro':
    case 'profesional':
      return 'Fiscal DGII (RNC, NCF, e-CF) + almacenes + equipos.';
    default:
      return '';
  }
}

/// Beneficios en lista para tarjetas de compra.
List<String> beneficiosPlanUi(String plan) {
  switch (plan.toLowerCase()) {
    case 'gratis':
      return const [
        'Ventas al contado',
        'Catálogo limitado (40 productos / 20 clientes)',
        '30 facturas al mes',
        '1 equipo · solo local',
        'Sin reportes ni sync en la nube',
      ];
    case 'basico':
      return const [
        'Hasta 300 facturas al mes',
        'Ventas, compras, inventario y caja',
        'Catálogo sin tope',
        'Reportes básicos',
        'Sync en la nube + backup automático',
        'Fiao · 1 equipo',
      ];
    case 'simplificado':
      return const [
        'Todo lo de Esencial',
        'Ventas sin tope',
        'Hasta 3 equipos · 3 usuarios',
        'Fiao sin tope',
        'Reportes avanzados + dashboard económico',
        'Importar / Exportar datos',
        'Sin módulo fiscal ni e-CF',
      ];
    case 'pro':
      return const [
        'Todo lo de Avanzado',
        'Crédito formal (CxC, solicitudes, cuotas)',
        'RNC + secuencias NCF + ITBIS',
        'Facturación electrónica e-CF (DGII)',
        'Declaraciones 606 / 607',
        'Almacenes + transferencias',
        'Usuarios ilimitados por rol',
        'Onboarding personalizado',
      ];
    default:
      return const [];
  }
}
