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
      return 'Gratis · 15 ventas/mes · 1 equipo · sin reportes.';
    }
    if (plan == 'basico') {
      return 'Básico · 50 facturas/mes · reportes · 1 equipo.';
    }
    if (esSimplificado) {
      return 'Simplificado · 150 facturas/mes · 1 equipo.';
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
