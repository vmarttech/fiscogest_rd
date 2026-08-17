import 'package:fiscogest_rd/features/cotizaciones/domain/repositories/i_cotizacion_repository.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cotizaciones_dao.dart';

class CotizacionRepositoryImpl implements ICotizacionRepository {

  CotizacionRepositoryImpl({required this.cotizacionesDao});
  final CotizacionesDao cotizacionesDao;

  @override
  Future<int> registrarCotizacion({
    required DateTime fecha,
    required int clienteId,
    required int usuarioId,
    required List<Map<String, dynamic>> productos,
    required double subtotal,
    required double descuento,
    required double impuestos,
    required double total,
    required DateTime validoHasta,
  }) async {
    throw UnimplementedError('registrarCotizacion: Insertar cabecera + líneas → estado Pendiente');
  }

  @override
  Future<int> convertirEnVenta(int cotizacionId) async {
    throw UnimplementedError('convertirEnVenta: Validar vigencia → generar venta → marcar convertida');
  }

  @override
  Future<void> editarCotizacion({
    required int cotizacionId,
    List<Map<String, dynamic>>? productos,
    double? descuento,
    DateTime? validoHasta,
  }) async {
    throw UnimplementedError('editarCotizacion: Actualizar cabecera y líneas opcionales');
  }

  @override
  Future<List<Map<String, dynamic>>> listarCotizaciones({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? usuarioId,
  }) async {
    throw UnimplementedError('listarCotizaciones: Filtrar por fechas, cliente y usuario');
  }

  @override
  Future<Map<String, dynamic>?> obtenerPorId(int cotizacionId) async {
    throw UnimplementedError('obtenerPorId: Consultar cotización y sus líneas por ID');
  }
}
