import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/almacenes/data/dao/almacenes_dao.dart';
import 'package:fiscogest_rd/features/almacenes/data/dao/stock_almacen_dao.dart';
import 'package:fiscogest_rd/features/inventario/data/dao/productos_dao.dart';
import 'package:fiscogest_rd/features/inventario/domain/usecases/registrar_transferencia.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/ikardex_repository.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';
import 'package:fiscogest_rd/features/inventario/domain/enums/tipo_movimiento.dart';
import 'package:fiscogest_rd/features/transferencias/data/dao/transferencias_dao.dart';
import 'package:fiscogest_rd/features/transferencias/domain/entities/transferencia.dart';

class TransferenciaService {
  TransferenciaService(this._db, this._kardexRepo)
    : _almacenes = AlmacenesDao(_db),
        _stock = StockAlmacenDao(_db),
        _productos = ProductosDao(_db),
        _transf = TransferenciasDao(_db),
        _registrarKardex = RegistrarTransferencia(_kardexRepo);

  final AppDatabase _db;
  final IKardexRepository _kardexRepo;
  final AlmacenesDao _almacenes;
  final StockAlmacenDao _stock;
  final ProductosDao _productos;
  final TransferenciasDao _transf;
  final RegistrarTransferencia _registrarKardex;

  Future<void> preparar() async {
    await _almacenes.asegurarPrincipal();
    await _stock.sembrarDesdeProductos();
  }

  Future<double> stockEn(int productoId, int almacenId) =>
      _stock.cantidad(productoId, almacenId);

  Future<List<Transferencia>> historial() => _transf.ultimas();

  Future<Transferencia> registrar({
    required int origenId,
    required int destinoId,
    required int productoId,
    required double cantidad,
    int usuarioId = 1,
    String? nota,
    String? productoCodigo,
    String? productoNombre,
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

    final producto = await _productos.obtenerPorId(productoId);
    final costoUnitario =
        producto?.costoPromedio ?? (producto?.precioCompra ?? 0.0);

    late Transferencia creada;
    await _db.transaction(() async {
      final saldoOrigenAntes = await _stock.cantidad(productoId, origenId);
      if (saldoOrigenAntes + 1e-9 < cantidad) {
        throw Exception(
          'Stock insuficiente en ${origen.nombre}. Disponible: $saldoOrigenAntes',
        );
      }
      final saldoDestinoAntes = await _stock.cantidad(productoId, destinoId);

      await _stock.setCantidad(
        productoId,
        origenId,
        saldoOrigenAntes - cantidad,
      );
      await _stock.setCantidad(
        productoId,
        destinoId,
        saldoDestinoAntes + cantidad,
      );

      final docRef = 'TRF-${DateTime.now().millisecondsSinceEpoch}';
      final observacionSalida =
          'Salida por transferencia hacia ${destino.nombre} — ${nota ?? ''}'
              .trim();
      final observacionEntrada =
          'Entrada por transferencia desde ${origen.nombre} — ${nota ?? ''}'
              .trim();

      await _registrarKardex.ejecutar(
        productoId: productoId,
        cantidad: cantidad,
        saldoAnterior: saldoOrigenAntes,
        saldoNuevo: saldoOrigenAntes - cantidad,
        costoUnitario: costoUnitario,
        usuarioId: usuarioId,
        observacion: observacionSalida,
      );

      await _kardexRepo.registrarMovimiento(
        Kardex(
          id: null,
          productoId: productoId,
          tipoMovimiento: TipoMovimiento.entrada,
          cantidad: cantidad,
          saldoAnterior: saldoDestinoAntes,
          saldoNuevo: saldoDestinoAntes + cantidad,
          costoUnitario: costoUnitario,
          totalMovimiento: cantidad * costoUnitario,
          fechaMovimiento: DateTime.now(),
          documentoReferencia: docRef,
          observacion: observacionEntrada,
          usuarioId: usuarioId,
        ),
      );

      final ahora = DateTime.now();
      final id = await _transf.insertar(
        Transferencia(
          almacenOrigenId: origenId,
          almacenDestinoId: destinoId,
          productoId: productoId,
          cantidad: cantidad,
          nota: nota,
          fecha: ahora,
        ),
      );
      creada = Transferencia(
        id: id,
        almacenOrigenId: origenId,
        almacenDestinoId: destinoId,
        productoId: productoId,
        cantidad: cantidad,
        nota: nota,
        fecha: ahora,
        estado: 'Completa',
        origenNombre: origen.nombre,
        destinoNombre: destino.nombre,
        productoCodigo: productoCodigo,
        productoNombre: productoNombre ?? producto?.nombre,
      );
    });
    return creada;
  }
}
