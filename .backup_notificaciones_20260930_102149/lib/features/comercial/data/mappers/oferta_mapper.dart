import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
// ... (imports existentes) ...

class OfertaMapper {
  // Línea ~14 y ~29: Enum ↔ String
  static String estadoToString(RegistroEstado e) => e.name;
  static RegistroEstado estadoFromString(String s) =>
      RegistroEstado.values.firstWhere((v) => v.name == s);

  // ... resto del código igual ...
}
