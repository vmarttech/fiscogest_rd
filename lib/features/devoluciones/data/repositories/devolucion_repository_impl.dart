import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/devoluciones_dao.dart';
import 'package:fiscogest_rd/features/devoluciones/domain/repositories/i_devolucion_repository.dart';

class DevolucionRepositoryImpl implements IDevolucionRepository {
  DevolucionRepositoryImpl(this.devolucionesDao);

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
    final devolucionCompanion = DevolucionesTableCompanion(
      ventaId: Value(origenId),
      fecha: Value(fecha),
      motivo: Value(motivo),
      tipo: Value(esTotal ? 'Total' : 'Parcial'),
      montoDevuelto: Value(montoDevuelto),
      estado: const Value('Registrada'),
      afectaInventario: const Value(true),
      afectaCaja: const Value(true),
    );

    final detallesCompanion = productos
        .map((p) => DevolucionesDetalleTableCompanion(
              devolucionId: const Value(0),
              productoId: Value(p['productoId'] as int),
              cantidad: Value((p['cantidad'] as num).toDouble()),
              precioUnitario: Value((p['precioUnitario'] as num).toDouble()),
              subtotal: Value((p['subtotal'] as num).toDouble()),
              motivoLinea: Value(motivo),
            ))
        .toList();

    return await devolucionesDao.registrarDevolucionCompleta(devolucionCompanion, detallesCompanion);
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
    final filas = await devolucionesDao.listarPorFiltros(
      desde: desde,
      hasta: hasta,
    );
    return filas.map((f) => {
      'id': f.id,
      'ventaId': f.ventaId,
      'fecha': f.fecha.toIso8601String(),
      'motivo': f.motivo,
      'tipo': f.tipo,
      'montoDevuelto': f.montoDevuelto,
      'estado': f.estado,
      'afectaInventario': f.afectaInventario,
      'afectaCaja': f.afectaCaja,
    }).toList();
  }

  @override
  Future<Map<String, dynamic>?> obtenerPorId(int devolucionId) async {
    final fila = await devolucionesDao.obtenerPorId(devolucionId);
    if (fila == null) return null;
    return {
      'id': fila.id,
      'ventaId': fila.ventaId,
      'fecha': fila.fecha.toIso8601String(),
      'motivo': fila.motivo,
      'tipo': fila.tipo,
      'montoDevuelto': fila.montoDevuelto,
      'estado': fila.estado,
    };
  }
}
