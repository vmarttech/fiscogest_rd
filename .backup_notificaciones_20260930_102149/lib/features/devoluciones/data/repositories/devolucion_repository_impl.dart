import 'package:fiscogest_rd/features/devoluciones/domain/repositories/i_devolucion_repository.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/devoluciones_dao.dart';

class DevolucionRepositoryImpl implements IDevolucionRepository {
  DevolucionRepositoryImpl({required this.devolucionesDao});
  final DevolucionesDao devolucionesDao;

  @override
  Future<int> registrarDevolucion({
    required DateTime fecha,
    required String tipoOrigen,
    required int origenId,
    required int clienteId,
    required int proveedorId,
    required int usuarioId,
    required List<Map<String, dynamic>> productos,
    required double montoDevuelto,
    required String motivo,
    required bool esTotal,
  }) async {
    throw UnimplementedError(
      'registrarDevolucion: Insertar cabecera + líneas → devolver inventario → reintegrar a caja',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> listarDevoluciones({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? proveedorId,
    int? usuarioId,
    String? tipoOrigen,
  }) async {
    throw UnimplementedError(
      'listarDevoluciones: Filtrar por fechas, cliente, proveedor, usuario y tipo',
    );
  }

  @override
  Future<Map<String, dynamic>?> obtenerPorId(int devolucionId) async {
    throw UnimplementedError(
      'obtenerPorId: Consultar devolución y sus líneas por ID',
    );
  }
}
