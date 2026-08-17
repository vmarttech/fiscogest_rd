import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
// ... (imports existentes) ...

class PagoMapper {
  // Línea ~11: String → Enum
  static FormaPago formaPagoFromString(String s) =>
      FormaPago.values.firstWhere((v) => v.name == s);

  // Línea ~24 y ~43: Enum → String
  static String formaPagoToString(FormaPago e) => e.name;

  // ... resto del código igual ...
}
