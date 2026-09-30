import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

class CotizacionMapper {
  static CotizacionEstado estadoFromString(String s) =>
      CotizacionEstado.values.firstWhere(
        (v) => v.name.toLowerCase() == s.toLowerCase(),
        orElse: () => CotizacionEstado.pendiente,
      );
}
