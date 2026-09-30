import 'package:fiscogest_rd/features/apartados/domain/repositories/i_apartado_repository.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/apartados_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

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
    final id = await apartadosDao.registrarApartadoCompleto(
      clienteId: clienteId,
      fechaReserva: fecha,
      fechaLimite: validoHasta,
      montoTotal: total,
      montoAbonado: anticipo,
      saldoPendiente: total - anticipo,
      estado: ApartadoEstado.reservado,
    );
    for (final producto in productos) {
      await apartadosDao.insertarDetalle(
        apartadoId: id,
        productoId: producto['productoId'] as int,
        cantidad: (producto['cantidad'] as num).toDouble(),
        precioUnitario: (producto['precioUnitario'] as num).toDouble(),
        subtotal: (producto['subtotal'] as num).toDouble(),
      );
    }
    return id;
  }

  @override
  Future<void> registrarAbono(int apartadoId, double monto) async {
    final registro = await apartadosDao.buscarPorId(apartadoId);
    if (registro == null) return;
    final nuevoAbonado = registro.montoAbonado + monto;
    final nuevoSaldo = registro.montoTotal - nuevoAbonado;
    await apartadosDao.actualizarSaldo(apartadoId, nuevoAbonado, nuevoSaldo);
  }

  @override
  Future<int> convertirEnVenta(int apartadoId) async {
    final registro = await apartadosDao.buscarPorId(apartadoId);
    if (registro == null) throw Exception('Apartado no encontrado');
    await apartadosDao.cambiarEstado(apartadoId, ApartadoEstado.convertido);
    return apartadoId;
  }

  @override
  Future<void> cancelarApartado(int apartadoId, String motivo) async {
    await apartadosDao.cambiarEstado(apartadoId, ApartadoEstado.cancelado);
  }

  @override
  Future<List<Map<String, dynamic>>> listarApartados({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? usuarioId,
    String? estado,
  }) async {
    final resultados = await apartadosDao.listarApartados();
    return resultados.where((map) {
      bool ok = true;
      if (desde != null && map['fechaReserva'] != null) {
        ok &=
            (map['fechaReserva'] as DateTime).isAfter(desde) ||
            (map['fechaReserva'] as DateTime).isAtSameMomentAs(desde);
      }
      if (hasta != null && map['fechaReserva'] != null) {
        ok &=
            (map['fechaReserva'] as DateTime).isBefore(hasta) ||
            (map['fechaReserva'] as DateTime).isAtSameMomentAs(hasta);
      }
      if (clienteId != null) ok &= map['clienteId'] == clienteId;
      if (estado != null) ok &= map['estado'] == estado;
      return ok;
    }).toList();
  }

  @override
  Future<Map<String, dynamic>?> obtenerPorId(int apartadoId) async {
    final registro = await apartadosDao.buscarPorId(apartadoId);
    if (registro == null) return null;
    final detalles = await apartadosDao.listarDetalles(apartadoId);
    return {
      ...registro.toJson(),
      'productos': detalles.map((d) => (d as dynamic).toJson()).toList(),
    };
  }
}
