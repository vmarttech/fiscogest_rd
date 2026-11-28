import 'package:fiscogest_rd/core/contabilidad/domain/config/plantilla_contrapartida.dart';

/// País contable activo de la instalación.
/// Fase 1: DO | MX | PR. Ampliar plantillas al expandir a otras pantallas.
class ContabilidadPaisConfig {
  ContabilidadPaisConfig._();

  static String _paisCodigo = 'DO';

  static String get paisCodigo => _paisCodigo;

  static PlantillaContrapartida get plantilla =>
      PlantillasContrapartida.porPais(_paisCodigo);

  /// Llamar en bootstrap según licencia / settings de la empresa.
  static void setPais(String codigo) {
    final c = codigo.trim().toUpperCase();
    if (c.isEmpty) return;
    _paisCodigo = c;
  }
}
