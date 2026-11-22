import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/almacenes/presentation/providers/almacen_activo_provider.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/inventario/domain/services/i_inventario_service.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/inventario_providers.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';
import 'package:fiscogest_rd/features/ventas/domain/services/i_venta_inventario_service.dart';
import 'package:fiscogest_rd/features/ventas/data/services/venta_inventario_service_impl.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/inventario/data/services/inventario_service_impl.dart';
import 'package:fiscogest_rd/features/inventario/data/dao/productos_dao.dart';
import 'package:fiscogest_rd/features/almacenes/data/dao/stock_almacen_dao.dart';
import 'package:fiscogest_rd/features/ventas/domain/usecases/registrar_venta.dart';

final inventarioServiceProvider = Provider<IInventarioService>((ref) {
  final db = ref.watch(databaseProvider);
  return InventarioServiceImpl(db);
});

final productosDaoProvider = Provider<ProductosDao>((ref) {
  final db = ref.watch(databaseProvider);
  return ProductosDao(db);
});

final stockAlmacenDaoProvider = Provider<StockAlmacenDao>((ref) {
  final db = ref.watch(databaseProvider);
  return StockAlmacenDao(db);
});

class RegistrarVentaUseCase {
  RegistrarVentaUseCase(this._ref, this._servicioInventario);
  final Ref _ref;
  final IVentaInventarioService _servicioInventario;

  Future<Venta> ejecutar(RegistrarVentaState estado) async {
    final ahora = DateTime.now();
    final venta = Venta(
      id: null,
      numeroCotizacion: '',
      numeroFactura: null,
      clienteId: estado.clienteId ?? 0,
      nombreCliente: estado.clienteNombre,
      fecha: ahora,
      detalles: estado.detalles,
      montoSubtotal: estado.subtotal,
      descuentoGlobal: 0.0,
      itbis: estado.itbis,
      montoTotal: estado.total,
      formaPago: estado.tipoPago,
      costoEnvio: 0.0,
      abonoInicial: estado.abonoInicial,
      vencimiento: estado.vencimiento,
      estadoDocumento: EstadoDocumento.borrador,
      usuarioId: estado.usuarioId,
      fechaRegistro: ahora,
      descuentoId: estado.descuentoId,
      descuentoNombre: estado.descuentoNombre,
      montoDescuento: estado.montoDescuento,
      almacenId: _ref.read(almacenActivoIdEfectivoProvider),
    );
    return await _servicioInventario.registrarVentaConInventario(venta);
  }
}

final registrarVentaUseCaseProvider = Provider<RegistrarVentaUseCase>((ref) {
  final repositorio = ref.read(ventasRepositoryProvider);
  final kardexRepo = ref.read(kardexRepositoryProvider);
  final inventarioServ = ref.read(inventarioServiceProvider);
  final productosDaoInst = ref.read(productosDaoProvider);
  final stockAlmacenDaoInst = ref.read(stockAlmacenDaoProvider);
  final servicio = VentaInventarioServiceImpl(
    ventasRepository: repositorio,
    kardexRepository: kardexRepo,
    inventarioService: inventarioServ,
    productosDao: productosDaoInst,
    stockAlmacenDao: stockAlmacenDaoInst,
  );
  return RegistrarVentaUseCase(ref, servicio);
});

final registrarVentaConInventarioUseCaseProvider =
    Provider<RegistrarVentaConInventarioUseCase>((ref) {
      final repositorio = ref.read(ventasRepositoryProvider);
      final kardexRepo = ref.read(kardexRepositoryProvider);
      final inventarioServ = ref.read(inventarioServiceProvider);
      final productosDaoInst = ref.read(productosDaoProvider);
      final stockAlmacenDaoInst = ref.read(stockAlmacenDaoProvider);
      final servicio = VentaInventarioServiceImpl(
        ventasRepository: repositorio,
        kardexRepository: kardexRepo,
        inventarioService: inventarioServ,
        productosDao: productosDaoInst,
        stockAlmacenDao: stockAlmacenDaoInst,
      );
      return RegistrarVentaConInventarioUseCase(servicio);
    });

final ventaInventarioServiceProvider = Provider<IVentaInventarioService>((ref) {
  final repositorio = ref.read(ventasRepositoryProvider);
  final kardexRepo = ref.read(kardexRepositoryProvider);
  final inventarioServ = ref.read(inventarioServiceProvider);
  final productosDaoInst = ref.read(productosDaoProvider);
  final stockAlmacenDaoInst = ref.read(stockAlmacenDaoProvider);
  return VentaInventarioServiceImpl(
    ventasRepository: repositorio,
    kardexRepository: kardexRepo,
    inventarioService: inventarioServ,
    productosDao: productosDaoInst,
    stockAlmacenDao: stockAlmacenDaoInst,
  );
});
