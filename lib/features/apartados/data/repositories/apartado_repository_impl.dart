import 'package:fiscogest_rd/features/apartados/domain/repositories/i_apartado_repository.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/apartados_dao.dart';

class ApartadoRepositoryImpl implements IApartadoRepository {
  ApartadoRepositoryImpl({required this.apartadosDao});
  final ApartadosDao apartadosDao;

  @override
  Future<int> registrarApartado({
    required DateTime fecha,
    required int clienteId,
    required int usuarioId,
    required List<Map<String, dynamic>> productos,
    required double total,
    required double anticipo,
    required DateTime validoHasta,
  }) async {
    throw UnimplementedError(
      'registrarApartado: Reservar productos → calcular saldo pendiente',
    );
  }

  @override
  Future<void> registrarAbono(int apartadoId, double monto) async {
    throw UnimplementedError(
      'registrarAbono: Sumar abonado → recalcula saldo pendiente',
    );
  }

  @override
  Future<int> convertirEnVenta(int apartadoId) async {
    throw UnimplementedError(
      'convertirEnVenta: Usar productos reservados → generar venta',
    );
  }

  @override
  Future<void> cancelarApartado(int apartadoId, String motivo) async {
    throw UnimplementedError(
      'cancelarApartado: Liberar inventario → estado Cancelado → registrar motivo',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> listarApartados({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? usuarioId,
    String? estado,
  }) async {
    throw UnimplementedError(
      'listarApartados: Filtrar por fechas, cliente, usuario y estado',
    );
  }

  @override
  Future<Map<String, dynamic>?> obtenerPorId(int apartadoId) async {
    throw UnimplementedError(
      'obtenerPorId: Consultar apartado, líneas y pagos por ID',
    );
  }
}
