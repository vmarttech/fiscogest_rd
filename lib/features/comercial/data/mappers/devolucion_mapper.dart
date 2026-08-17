import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
// ... (imports existentes) ...

class DevolucionMapper {
  // Línea ~17: Enum → String
  static String estadoToString(DevolucionEstado e) => e.name;

  // Línea ~27: String → Enum
  static DevolucionTipo tipoFromString(String s) =>
      DevolucionTipo.values.firstWhere((v) => v.name == s);
  // Línea ~29: String → Enum
  static DevolucionEstado estadoFromString(String s) =>
      DevolucionEstado.values.firstWhere((v) => v.name == s);

  // Línea ~66: Enum → String
  static String estadoToDb(DevolucionEstado? e) => e?.name ?? '';

  // ... resto del código igual ...
}
