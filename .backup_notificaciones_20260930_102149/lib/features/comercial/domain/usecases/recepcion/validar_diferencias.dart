import 'package:fiscogest_rd/features/comercial/domain/entities/recepcion_elemento.dart';

class ValidarDiferencias {
  List<DetalleRecepcion> ejecutar(List<DetalleRecepcion> detalles) {
    return detalles.map((detalle) {
      final cantidadRecibida = detalle.cantidadRecibida ?? 0;
      final cantidadPedida = detalle.cantidadPedida ?? 0;
      final diferencia = cantidadRecibida - cantidadPedida;
      return detalle.copyWith(diferencia: diferencia);
    }).toList();
  }
}
