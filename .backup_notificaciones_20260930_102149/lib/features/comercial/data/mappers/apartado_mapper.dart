import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
// ... (imports existentes) ...

class ApartadoMapper {
  // Línea ~18: Enum → String
  static String estadoToString(ApartadoEstado e) => e.name;

  // Línea ~31: String → Enum
  static ApartadoEstado estadoFromString(String s) =>
      ApartadoEstado.values.firstWhere((v) => v.name == s);

  // Línea ~61: Enum → String
  static String estadoToDb(ApartadoEstado? e) => e?.name ?? '';

  // ... resto del código igual ...
}
