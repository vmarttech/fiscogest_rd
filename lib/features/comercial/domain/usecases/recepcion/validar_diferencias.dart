import 'package:fiscogest_rd/features/comercial/domain/entities/recepcion.dart';

class ValidarDiferencias {
  List<DetalleRecepcion> ejecutar(List<DetalleRecepcion> detalles) {
    return detalles.map((detalle) {
      final diferencia = (detalle.cantidadRecibida ?? 0) - (detalle.cantidadPedida ?? 0);
      return detalle.copyWith(diferencia: diferencia);
    }).toList();
  }
}
