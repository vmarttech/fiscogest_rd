import 'package:fiscogest_rd/core/contabilidad/domain/entities/asiento_contable.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/linea_asiento.dart';

abstract class IAsientoRepository {
  Future<AsientoContable> registrar(
    AsientoContable asiento,
    List<LineaAsiento> lineas,
  );
  Future<AsientoContable?> obtenerPorId(int asientoId);
  Future<List<LineaAsiento>> obtenerLineas(int asientoId);
  Future<List<AsientoContable>> listar({
    DateTime? desde,
    DateTime? hasta,
    int? cuentaId,
    int limite = 50,
    int offset = 0,
  });
  Future<bool> anular(int asientoId, String motivo);
  Future<String> obtenerSiguienteNumero();
}
