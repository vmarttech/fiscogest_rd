import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/config/cuenta_rol.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/config/plantilla_contrapartida.dart';

/// Carga plantillas desde assets/contabilidad/plantillas/{pais}.json.
/// Fallback: catálogo en código (DO/MX/PR) si el asset falta.
class PlantillaJsonLoader {
  PlantillaJsonLoader._();

  static const _base = 'assets/contabilidad/plantillas';

  static Future<PlantillaContrapartida> cargar(String paisCodigo) async {
    final code = paisCodigo.trim().toUpperCase();
    final path = '$_base/${code.toLowerCase()}.json';
    try {
      final raw = await rootBundle.loadString(path);
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return fromMap(map);
    } catch (_) {
      return PlantillasContrapartida.porPais(code);
    }
  }

  static PlantillaContrapartida fromMap(Map<String, dynamic> map) {
    final rolesRaw = Map<String, dynamic>.from(map['roles'] as Map? ?? {});
    final codigos = <CuentaRol, String>{};
    for (final e in rolesRaw.entries) {
      final rol = _rolFromKey(e.key);
      if (rol != null) {
        codigos[rol] = e.value.toString();
      }
    }
    final etiqueta = (map['etiquetaImpuesto'] as String?) ??
        (map['impuestoCodigo'] as String?) ??
        '';
    return PlantillaContrapartida(
      paisCodigo: (map['paisCodigo'] as String? ?? 'DO').toUpperCase(),
      nombre: map['nombre'] as String? ?? map['paisCodigo'] as String? ?? '',
      codigos: codigos,
      etiquetaImpuesto: etiqueta,
    );
  }

  static CuentaRol? _rolFromKey(String key) {
    switch (key) {
      case 'caja':
        return CuentaRol.caja;
      case 'cxc':
        return CuentaRol.cxc;
      case 'impuestoCredito':
        return CuentaRol.impuestoCredito;
      case 'inventario':
        return CuentaRol.inventario;
      case 'cxp':
        return CuentaRol.cxp;
      case 'impuestoPorPagar':
        return CuentaRol.impuestoPorPagar;
      case 'ingresosVentas':
        return CuentaRol.ingresosVentas;
      case 'costoVentas':
        return CuentaRol.costoVentas;
      default:
        return null;
    }
  }
}
