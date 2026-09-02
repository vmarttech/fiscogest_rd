import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
// ... (imports existentes) ...

class CotizacionMapper {
  // Línea ~33: Reemplazar cadena por valor del Enum
  static CotizacionEstado estadoFromString(String s) => CotizacionEstado.values
      .firstWhere((v) => v.name == s, orElse: () => CotizacionEstado.pendiente);

  // ... resto del código igual ...
}
