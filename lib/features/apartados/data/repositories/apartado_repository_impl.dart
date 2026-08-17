import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/apartados_dao.dart';
import 'package:fiscogest_rd/features/apartados/domain/repositories/i_apartado_repository.dart';

class ApartadoRepositoryImpl implements IApartadoRepository {
  ApartadoRepositoryImpl(this.apartadosDao);

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
    final apartadoCompanion = ApartadosTableCompanion(
      clienteId: Value(clienteId),
      fechaReserva: Value(fecha),
      fechaLimite: Value(validoHasta),
      montoTotal: Value(total),
      montoAbonado: Value(anticipo),
      saldoPendiente: Value(total - anticipo),
      estado: const Value('Reservado'),
    );

    final detallesCompanion = productos
        .map((p) => ApartadosDetalleTableCompanion(
              apartadoId: const Value(0),
              productoId: Value(p['productoId'] as int),
              cantidad: Value((p['cantidad'] as num).toDouble()),
              precioUnitario: Value((p['precioUnitario'] as num).toDouble()),
              subtotal: Value((p['subtotal'] as num).toDouble()),
            ))
        .toList();

    return await apartadosDao.registrarApartadoCompleto(apartadoCompanion, detallesCompanion);
  }

  @override
  Future<void> registrarAbono(int apartadoId, double monto) async {
    final apartado = await apartadosDao.obtenerPorId(apartadoId);
    if (apartado == null) throw Exception('Apartado no encontrado');

    final nuevoAbonado = apartado.montoAbonado + monto;
    final nuevoSaldo = apartado.saldoPendiente - monto;
    final nuevoEstado = nuevoSaldo <= 0 ? 'Pagado' : 'Parcial';

    await apartadosDao.actualizarAbono(apartadoId, nuevoAbonado, nuevoSaldo);
    if (nuevoEstado != apartado.estado) {
      await apartadosDao.actualizarEstado(apartadoId, nuevoEstado);
    }
  }

  @override
  Future<int> convertirEnVenta(int apartadoId) async {
    await apartadosDao.actualizarEstado(apartadoId, 'Convertido');
    return 0;
  }

  @override
  Future<void> cancelarApartado(int apartadoId, String motivo) async {
    await apartadosDao.actualizarEstado(apartadoId, 'Cancelado');
  }

  @override
  Future<List<Map<String, dynamic>>> listarApartados({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? usuarioId,
    String? estado,
  }) async {
    final filas = await apartadosDao.listarPorFiltros(
      desde: desde,
      hasta: hasta,
      clienteId: clienteId,
      estado: estado,
    );
    return filas.map((f) {
      return {
        'id': f.id,
        'clienteId': f.clienteId,
        'fechaReserva': f.fechaReserva.toIso8601String(),
        'fechaLimite': f.fechaLimite.toIso8601String(),
        'montoTotal': f.montoTotal,
        'montoAbonado': f.montoAbonado,
        'saldoPendiente': f.saldoPendiente,
        'estado': f.estado,
        'ventaConvertidaId': f.ventaConvertidaId,
      };
    }).toList();
  }

  @override
  Future<Map<String, dynamic>?> obtenerPorId(int apartadoId) async {
    final fila = await apartadosDao.obtenerPorId(apartadoId);
    if (fila == null) return null;
    return {
      'id': fila.id,
      'clienteId': fila.clienteId,
      'fechaReserva': fila.fechaReserva.toIso8601String(),
      'fechaLimite': fila.fechaLimite.toIso8601String(),
      'montoTotal': fila.montoTotal,
      'montoAbonado': fila.montoAbonado,
      'saldoPendiente': fila.saldoPendiente,
      'estado': fila.estado,
    };
  }
}
