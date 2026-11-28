import 'package:fiscogest_rd/core/contabilidad/domain/config/cuenta_rol.dart';

/// Plantilla de un país: mapa rol → código + definición de asientos automáticos.
class PlantillaContrapartida {
  const PlantillaContrapartida({
    required this.paisCodigo,
    required this.nombre,
    required this.codigos,
    required this.etiquetaImpuesto,
  });

  /// ISO-ish: DO | MX | PR
  final String paisCodigo;
  final String nombre;

  /// Rol de negocio → código en el plan de cuentas de ese país.
  final Map<CuentaRol, String> codigos;

  /// Etiqueta fiscal local (ITBIS, IVA, IVU…) solo para textos/UI.
  final String etiquetaImpuesto;

  String codigo(CuentaRol rol) {
    final c = codigos[rol];
    if (c == null || c.isEmpty) {
      throw StateError('acct_error_role_unmapped:$paisCodigo:${rol.name}');
    }
    return c;
  }
}

/// Catálogo de plantillas exportables (fase 1: DO, MX, PR).
class PlantillasContrapartida {
  static const doRd = PlantillaContrapartida(
    paisCodigo: 'DO',
    nombre: 'República Dominicana',
    etiquetaImpuesto: 'ITBIS',
    codigos: {
      CuentaRol.caja: '1101',
      CuentaRol.cxc: '1103',
      CuentaRol.impuestoCredito: '1105',
      CuentaRol.inventario: '1201',
      CuentaRol.cxp: '2101',
      CuentaRol.impuestoPorPagar: '2104',
      CuentaRol.ingresosVentas: '4101',
      CuentaRol.costoVentas: '5101',
    },
  );

  static const mx = PlantillaContrapartida(
    paisCodigo: 'MX',
    nombre: 'México',
    etiquetaImpuesto: 'IVA',
    codigos: {
      CuentaRol.caja: '101.01',
      CuentaRol.cxc: '105.01',
      CuentaRol.impuestoCredito: '118.01',
      CuentaRol.inventario: '115.01',
      CuentaRol.cxp: '201.01',
      CuentaRol.impuestoPorPagar: '208.01',
      CuentaRol.ingresosVentas: '401.01',
      CuentaRol.costoVentas: '501.01',
    },
  );

  static const pr = PlantillaContrapartida(
    paisCodigo: 'PR',
    nombre: 'Puerto Rico',
    etiquetaImpuesto: 'IVU',
    codigos: {
      CuentaRol.caja: '1010',
      CuentaRol.cxc: '1100',
      CuentaRol.impuestoCredito: '1150',
      CuentaRol.inventario: '1200',
      CuentaRol.cxp: '2000',
      CuentaRol.impuestoPorPagar: '2100',
      CuentaRol.ingresosVentas: '4000',
      CuentaRol.costoVentas: '5000',
    },
  );

  static const List<PlantillaContrapartida> todas = [doRd, mx, pr];

  static PlantillaContrapartida porPais(String codigo) {
    final c = codigo.trim().toUpperCase();
    return todas.firstWhere(
      (p) => p.paisCodigo == c,
      orElse: () => doRd,
    );
  }
}
