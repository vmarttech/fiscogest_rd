import 'package:fiscogest_rd/features/licencias/domain/licencia_estado.dart';
import 'package:fiscogest_rd/features/licencias/domain/planes_precios.dart';

class LicenciaGates {
  const LicenciaGates(this.lic);

  final LicenciaInfo? lic;

  String get plan => lic?.plan ?? 'demo';

  LimitesPlan get limites => limitesDe(plan);

  bool get tieneLicencia => lic != null;

  bool get puedeEscribir => lic?.puedeEscribir ?? false;

  bool get permiteFiscal {
    if (lic?.esDesarrollador == true) return true;
    return limites.permiteFiscal || plan == 'demo';
  }

  bool get permiteFiao {
    if (lic?.esDesarrollador == true) return true;
    return limites.permiteFiao;
  }

  bool get permiteCreditoFormal {
    if (lic?.esDesarrollador == true) return true;
    return limites.permiteCreditoFormal;
  }

  bool get esSimplificado => esPlanSimplificado(plan);

  bool get esGratis => esPlanGratis(plan);

  int? get maxCuentasFiao => limites.maxCuentasFiaoAbiertas;

  int? get maxProductos => limites.maxProductos;

  int? get maxClientes => limites.maxClientes;

  int? get maxVentasMes => limites.maxVentasMes;

  String get textoDispositivos {
    if (lic == null) return '';
    if (lic!.esDesarrollador) {
      return 'Licencia de plataforma · desarrollador autorizado.';
    }
    if (esGratis) {
      return 'Plan gratis · 1 dispositivo · límites activos · fiao hasta ${maxCuentasFiao ?? 25} cuentas.';
    }
    if (esSimplificado) {
      return 'Simplificado · 1 dispositivo · sin impuestos · fiao hasta ${maxCuentasFiao ?? 50}.';
    }
    final max = lic!.maxDispositivos;
    if (permiteFiao) {
      return 'Hasta $max instalaciones · fiao disponible · 1 celular gratis en planes de pago.';
    }
    return 'Hasta $max instalaciones · crédito formal (sin fiao) · 1 celular gratis.';
  }

  String mensajeTope(String recurso) =>
      'Límite del plan ($plan) en $recurso. '
      'Actualice en Configuración → Sistema → Licencia y pagos.';

  /// Catálogo de almacenes + transferencias: Profesional y Empresa.
  bool get permiteAlmacenes {
    final p = (lic?.plan ?? '').toLowerCase().trim();
    return p == 'profesional' || p == 'empresa' || p == 'desarrollador';
  }
}
