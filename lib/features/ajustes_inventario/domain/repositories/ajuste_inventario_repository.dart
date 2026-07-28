import 'package:fiscogest_rd/features/ajustes_inventario/domain/entities/ajuste_inventario.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/domain/entities/movimiento_kardex.dart';

abstract class AjusteInventarioRepository {
  Future<void> registrarAjuste(AjusteInventario ajuste);
  Future<List<AjusteInventario>> listarAjustes();
  Future<void> actualizarExistencias(int idProducto, double cantidad, String tipo);
  Future<void> registrarEnKardex(MovimientoKardex movimiento);
}
