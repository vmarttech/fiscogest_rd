import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cotizaciones_dao.dart';
import 'package:fiscogest_rd/features/cotizaciones/domain/repositories/i_cotizacion_repository.dart';

class CotizacionRepositoryImpl implements ICotizacionRepository {
  CotizacionRepositoryImpl(this.cotizacionesDao);

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
    final cotizacionCompanion = CotizacionesTableCompanion(
      clienteId: Value(clienteId),
      fechaEmision: Value(fecha),
      fechaVigencia: Value(validoHasta),
      montoSubtotal: Value(subtotal),
      descuentoGlobal: Value(descuento),
      itbis: Value(impuestos),
      montoTotal: Value(total),
      estado: const Value('Pendiente'),
    );

    final detallesCompanion = productos
        .map((p) => CotizacionesDetalleTableCompanion(
              cotizacionId: const Value(0),
              productoId: Value(p['productoId'] as int),
              cantidad: Value((p['cantidad'] as num).toDouble()),
              precioUnitario: Value((p['precioUnitario'] as num).toDouble()),
              descuentoLinea: Value((p['descuento'] as num?)?.toDouble() ?? 0.0),
              subtotal: Value((p['subtotal'] as num).toDouble()),
            ))
        .toList();

    return await cotizacionesDao.registrarCotizacionCompleta(cotizacionCompanion, detallesCompanion);
  }

  @override
  Future<int> convertirEnVenta(int cotizacionId) async {
    await cotizacionesDao.actualizarEstado(cotizacionId, 'Convertida');
    return 0;
  }

  @override
  Future<void> editarCotizacion({
    required int cotizacionId,
    List<Map<String, dynamic>>? productos,
    double? descuento,
    DateTime? validoHasta,
  }) async {
    if (validoHasta != null || descuento != null) {
      final cotizacion = await cotizacionesDao.obtenerPorId(cotizacionId);
      if (cotizacion != null) {
        await cotizacionesDao.insertarOActualizar(
          CotizacionesTableCompanion(
            id: Value(cotizacionId),
            fechaVigencia: validoHasta != null ? Value(validoHasta) : Value(cotizacion.fechaVigencia),
            clienteId: Value(cotizacion.clienteId),
            fechaEmision: Value(cotizacion.fechaEmision),
            montoSubtotal: Value(cotizacion.montoSubtotal),
            descuentoGlobal: descuento != null ? Value(descuento) : Value(cotizacion.descuentoGlobal),
            itbis: Value(cotizacion.itbis),
            montoTotal: Value(cotizacion.montoTotal),
            estado: Value(cotizacion.estado),
          ),
        );
      }
    }
  }

  @override
  Future<List<Map<String, dynamic>>> listarCotizaciones({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? usuarioId,
  }) async {
    final filas = await cotizacionesDao.listarPorFiltros(
      desde: desde,
      hasta: hasta,
      clienteId: clienteId,
    );
    return filas.map((f) => {
      'id': f.id,
      'clienteId': f.clienteId,
      'fechaEmision': f.fechaEmision.toIso8601String(),
      'fechaVigencia': f.fechaVigencia.toIso8601String(),
      'subtotal': f.montoSubtotal,
      'descuentoGlobal': f.descuentoGlobal,
      'itbis': f.itbis,
      'total': f.montoTotal,
      'estado': f.estado,
      'ventaConvertidaId': f.ventaConvertidaId,
    }).toList();
  }

  @override
  Future<Map<String, dynamic>?> obtenerPorId(int cotizacionId) async {
    final fila = await cotizacionesDao.obtenerPorId(cotizacionId);
    if (fila == null) return null;
    return {
      'id': fila.id,
      'clienteId': fila.clienteId,
      'fechaEmision': fila.fechaEmision.toIso8601String(),
      'fechaVigencia': fila.fechaVigencia.toIso8601String(),
      'subtotal': fila.montoSubtotal,
      'total': fila.montoTotal,
      'estado': fila.estado,
    };
  }
}
