import 'package:fiscogest_rd/core/contabilidad/domain/config/plantilla_contrapartida.dart';

/// País contable activo de la instalación.
/// Fase 1: DO | MX | PR. Ampliar con JSON en assets/contabilidad/plantillas/.
class ContabilidadPaisConfig {
  ContabilidadPaisConfig._();

  static String _paisCodigo = 'DO';

  /// Plantilla cargada (JSON o catálogo). Null → se resuelve por código.
  static PlantillaContrapartida? _plantilla;

  static String get paisCodigo => _paisCodigo;

  static PlantillaContrapartida get plantilla =>
      _plantilla ?? PlantillasContrapartida.porPais(_paisCodigo);

  /// Llamar en bootstrap según licencia / settings de la empresa.
  static void setPais(String codigo) {
    final c = codigo.trim().toUpperCase();
    if (c.isEmpty) return;
    if (c != _paisCodigo) {
      _paisCodigo = c;
      _plantilla = null; // forzar recarga o fallback por país
    }
  }

  /// Fija plantilla ya resuelta (p. ej. desde JSON).
  static void setPlantilla(PlantillaContrapartida plantilla) {
    _plantilla = plantilla;
    final c = plantilla.paisCodigo.trim().toUpperCase();
    if (c.isNotEmpty) _paisCodigo = c;
  }

  /// Quita override; [plantilla] vuelve al catálogo por [paisCodigo].
  static void clearPlantilla() {
    _plantilla = null;
  }
}
