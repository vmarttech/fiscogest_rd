import 'package:fiscogest_rd/features/comercial/domain/entities/promocion.dart';

abstract class PromocionRepository {
  Future<List<Promocion>> obtenerTodas();
  Future<Promocion?> obtenerPorId(String id);
  Future<void> crear(Promocion promocion);
  Future<void> actualizar(Promocion promocion);
  Future<void> eliminar(String id);
  Future<List<Promocion>> obtenerActivas();
}
