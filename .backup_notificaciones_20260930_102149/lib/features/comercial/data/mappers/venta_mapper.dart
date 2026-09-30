import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
// ... (imports existentes) ...

class VentaMapper {
  // Línea ~16 y ~82: Enum → String
  static String formaPagoToString(FormaPago e) => e.name;

  // Línea ~33: String → Enum
  static FormaPago formaPagoFromString(String s) =>
      FormaPago.values.firstWhere((v) => v.name == s);

  // Línea ~34: String → Enum
  static VentaEstado estadoFromString(String s) => VentaEstado.values
      .firstWhere((v) => v.name == s, orElse: () => VentaEstado.borrador);

  // ... resto del código igual ...
}
