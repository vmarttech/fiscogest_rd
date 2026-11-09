import 'package:fiscogest_rd/features/licencias/domain/licencia_estado.dart';
import 'package:fiscogest_rd/features/licencias/domain/planes_precios.dart';

class LicenciaGates {
  const LicenciaGates(this.lic);

  final LicenciaInfo? lic;

  String get plan => (lic?.plan ?? 'demo').toLowerCase();

  LimitesPlan get limites => limitesDe(plan);

  bool get tieneLicencia => lic != null;

  bool get puedeEscribir => lic?.puedeEscribir ?? false;

  bool get esDemo => plan == 'demo';

  bool get esDesarrollador => lic?.esDesarrollador == true;

  bool get permiteFiscal {
    if (esDesarrollador || esDemo) return true;
    return limites.permiteFiscal;
  }

  bool get permiteFiao {
    if (esDesarrollador || esDemo) return true;
    return limites.permiteFiao;
  }

  bool get permiteCreditoFormal {
    if (esDesarrollador || esDemo) return true;
    return limites.permiteCreditoFormal;
  }

  bool get permiteReportes {
    if (esDesarrollador || esDemo) return true;
    return limites.permiteReportes;
  }

  bool get permiteAlmacenes {
    if (esDesarrollador || esDemo) return true;
    return limites.permiteAlmacenes;
  }

  bool get permiteUsuariosExtra {
    if (esDesarrollador || esDemo) return true;
    return limites.permiteUsuariosExtra;
  }

  bool get permiteEcf {
    if (esDesarrollador || esDemo) return true;
    return limites.permiteEcf;
  }

  bool get esSimplificado => esPlanSimplificado(plan);

  bool get esGratis => esPlanGratis(plan);

  bool get esPro => esPlanPro(plan);

  int? get maxCuentasFiao => limites.maxCuentasFiaoAbiertas;

  /// true si [abiertas] ya alcanzó el tope de cuentas fiao del plan (null = sin tope).
  bool fiaoEnTope(int abiertas) {
    final max = maxCuentasFiao;
    if (max == null) return false;
    return abiertas >= max;
  }

  String mensajeTopeFiao(int abiertas) {
    final max = maxCuentasFiao ?? 0;
    return 'Llevas $abiertas cuentas de fiao abiertas (tope de tu plan: $max). '
        'Actualiza tu plan en Licencia y pagos para liberar más.';
  }


  int? get maxProductos => limites.maxProductos;

  int? get maxClientes => limites.maxClientes;

  int? get maxVentasMes => limites.maxVentasMes;

  String get textoDispositivos {
    if (lic == null) return '';
    if (esDesarrollador) {
      return 'Licencia de plataforma · desarrollador autorizado.';
    }
    if (esDemo) {
      return 'Prueba 30 días · acceso completo · 1 equipo.';
    }
    if (esGratis) {
      return 'Gratis · 30 ventas/mes · 40 productos · 1 equipo · sin reportes.';
    }
    if (plan == 'basico') {
      return 'Esencial · 300 facturas/mes · reportes · fiao c/WhatsApp · 1 equipo.';
    }
    if (esSimplificado) {
      return 'Simplificado · ventas ilimitadas · hasta 3 equipos · fiao ilimitado.';
    }
    if (esPro) {
      return 'Pro · todo incluido · usuarios por departamento.';
    }
    final max = lic!.maxDispositivos;
    return 'Hasta $max instalaciones.';
  }

  String mensajeTope(String recurso) =>
      'Límite del plan ${nombrePlanUi(plan)} en $recurso. '
      'Actualiza tu plan en Licencia y pagos.';

  /// Mensaje al tocar una función no incluida en el plan actual.
  String mensajeUpgrade(String funcion) {
    final min = planMinimoPara(funcion);
    return 'Tu plan ${nombrePlanUi(plan)} no incluye esta función. '
        'Actualiza a ${nombrePlanUi(min)} para usarla.';
  }
}
