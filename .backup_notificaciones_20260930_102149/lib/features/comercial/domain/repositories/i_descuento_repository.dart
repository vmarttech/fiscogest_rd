import 'package:fiscogest_rd/features/comercial/domain/entities/descuento.dart';

abstract class IDescuentoRepository {
  Future<Descuento> guardarDescuento(Descuento descuento);
  Future<Descuento?> obtenerPorId(int id);
  Future<List<Descuento>> listarDescuentosActivos();
  Future<bool> validarDescuento(Descuento descuento);
  Future<double> aplicarDescuento({
    required Descuento descuento,
    required double montoOriginal,
  });
  Future<Descuento> autorizarDescuento({
    required int descuentoId,
    required int usuarioAutorizadorId,
  });
}
