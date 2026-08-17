import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
// ... (imports existentes) ...

class DescuentoMapper {
  // Línea ~9: Enum → String
  static String tipoToString(DescuentoTipo e) => e.name;
  // Línea ~11: Enum → String
  static String aplicaAToString(AplicaA e) => e.name;
  // Línea ~15: Enum → String
  static String estadoToString(RegistroEstado e) => e.name;

  // Línea ~25: String → Enum
  static DescuentoTipo tipoFromString(String s) =>
      DescuentoTipo.values.firstWhere((v) => v.name == s);
  // Línea ~27: String → Enum
  static AplicaA aplicaAFromString(String s) =>
      AplicaA.values.firstWhere((v) => v.name == s);
  // Línea ~31: String → Enum
  static RegistroEstado estadoFromString(String s) =>
      RegistroEstado.values.firstWhere((v) => v.name == s);

  // ... resto del código igual ...
}
