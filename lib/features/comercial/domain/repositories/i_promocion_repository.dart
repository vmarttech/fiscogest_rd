import 'package:fiscogest_rd/features/comercial/domain/entities/promocion.dart';

abstract class IPromocionRepository {
  Future<Promocion> crear(Promocion promocion);
  Future<Promocion?> obtenerPorId(int id);
  Future<List<Promocion>> listarTodas();
  Future<List<Promocion>> listarActivas(DateTime fechaReferencia);
  Future<Promocion> actualizar(Promocion promocion);
  Future<void> eliminar(int id);
}
