import 'package:fiscogest_rd/features/licencias/domain/licencia_estado.dart';
import 'package:fiscogest_rd/features/licencias/domain/planes_precios.dart';

/// Reglas de producto sobre una licencia ya resuelta.
class LicenciaGates {
  const LicenciaGates(this.lic);

  final LicenciaInfo? lic;

  bool get tieneLicencia => lic != null;

  bool get puedeEscribir => lic?.puedeEscribir ?? false;

  /// Simplificado / ambulantes: sin impuestos ni e-CF ni NCF.
  bool get permiteFiscal {
    final p = lic?.plan ?? 'demo';
    if (esPlanSimplificado(p)) return false;
    if (lic?.esDesarrollador == true) return true;
    return planPermiteModuloFiscal(p) || planIncluyeEcf(p) || p == 'demo';
  }

  bool get esSimplificado => esPlanSimplificado(lic?.plan ?? '');

  bool get esNormalActivo {
    final p = lic?.plan ?? '';
    return esPlanNormal(p) && (lic?.puedeEscribir ?? false);
  }

  /// Texto para UI del beneficio móvil.
  String get textoDispositivos {
    if (lic == null) return '';
    if (lic!.esDesarrollador) {
      return 'Acceso vitalicio MartTech · sin límite práctico de equipos.';
    }
    if (esSimplificado) {
      return 'Simplificado: 1 dispositivo · sin impuestos ni facturación fiscal.';
    }
    final max = lic!.maxDispositivos;
    return 'Modo normal: hasta $max instalaciones '
        '(incluye 1 celular gratis con las mismas funciones de este plan).';
  }
}
