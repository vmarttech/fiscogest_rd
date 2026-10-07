import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/almacenes/data/dao/almacenes_dao.dart';
import 'package:fiscogest_rd/features/almacenes/data/dao/stock_almacen_dao.dart';
import 'package:fiscogest_rd/features/transferencias/data/dao/transferencias_dao.dart';
import 'package:fiscogest_rd/features/transferencias/domain/entities/transferencia.dart';

class TransferenciaService {
  TransferenciaService(this._db)
      : _almacenes = AlmacenesDao(_db),
        _stock = StockAlmacenDao(_db),
        _transf = TransferenciasDao(_db);

  final AppDatabase _db;
  final AlmacenesDao _almacenes;
  final StockAlmacenDao _stock;
  final TransferenciasDao _transf;

  Future<void> preparar() async {
    await _almacenes.asegurarPrincipal();
    await _stock.sembrarDesdeProductos();
  }

  Future<double> stockEn(int productoId, int almacenId) =>
      _stock.cantidad(productoId, almacenId);

  Future<List<Transferencia>> historial() => _transf.ultimas();

  Future<void> registrar({
    required int origenId,
    required int destinoId,
    required int productoId,
    required double cantidad,
    String? nota,
  }) async {
    if (origenId == destinoId) {
      throw Exception('Origen y destino deben ser distintos.');
    }
    if (cantidad <= 0) {
      throw Exception('La cantidad debe ser mayor que cero.');
    }
    await preparar();
    final origen = await _almacenes.obtenerPorId(origenId);
    final destino = await _almacenes.obtenerPorId(destinoId);
    if (origen == null || !origen.activo) {
      throw Exception('El almacén origen no existe o está inactivo.');
    }
    if (destino == null || !destino.activo) {
      throw Exception('El almacén destino no existe o está inactivo.');
    }
    await _db.transaction(() async {
      final hay = await _stock.cantidad(productoId, origenId);
      if (hay + 1e-9 < cantidad) {
        throw Exception(
          'Stock insuficiente en ${origen.nombre}. Disponible: $hay',
        );
      }
      await _stock.setCantidad(productoId, origenId, hay - cantidad);
      final destCant = await _stock.cantidad(productoId, destinoId);
      await _stock.setCantidad(productoId, destinoId, destCant + cantidad);
      await _transf.insertar(
        Transferencia(
          almacenOrigenId: origenId,
          almacenDestinoId: destinoId,
          productoId: productoId,
          cantidad: cantidad,
          nota: nota,
          fecha: DateTime.now(),
        ),
      );
    });
  }
}
