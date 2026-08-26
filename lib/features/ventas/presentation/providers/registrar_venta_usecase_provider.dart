import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/inventario/domain/services/i_inventario_service.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/inventario_providers.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/services/i_venta_inventario_service.dart';
import 'package:fiscogest_rd/features/ventas/data/services/venta_inventario_service_impl.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/inventario/data/services/inventario_service_impl.dart';
import 'package:fiscogest_rd/features/inventario/data/dao/productos_dao.dart';
import 'package:fiscogest_rd/features/ventas/domain/usecases/registrar_venta.dart';

// ─── Providers ──────────────────────────────────────────────────
final inventarioServiceProvider = Provider<IInventarioService>((ref) {
  final db = ref.watch(databaseProvider);
  return InventarioServiceImpl(db);
});

final productosDaoProvider = Provider<ProductosDao>((ref) {
  final db = ref.watch(databaseProvider);
  return ProductosDao(db);
});

// ─── Caso de uso principal ─────────────────────────────────────
class RegistrarVentaUseCase {
  RegistrarVentaUseCase(this._servicioInventario);
  final IVentaInventarioService _servicioInventario;

  Future<Venta> ejecutar(RegistrarVentaState estado) async {
    final venta = Venta(
      numero: '',
      clienteId: estado.clienteId ?? 0,
      nombreCliente: estado.clienteNombre,
      fecha: DateTime.now(),
      detalles: estado.detalles,
      subtotal: estado.subtotal,
      itbis: estado.itbis,
      total: estado.total,
      tipoPago: estado.tipoPago,
      esCredito: estado.esCredito,
      usuarioId: estado.usuarioId,
      createdAt: DateTime.now(),
      descuentoId: estado.descuentoId,
      descuentoNombre: estado.descuentoNombre,
      montoDescuento: estado.montoDescuento,
    );
    return await _servicioInventario.registrarVentaConInventario(venta);
  }
}

final registrarVentaUseCaseProvider = Provider<RegistrarVentaUseCase>((ref) {
  final repositorio = ref.read(ventasRepositoryProvider);
  final kardexRepo = ref.read(kardexRepositoryProvider);
  final inventarioServ = ref.read(inventarioServiceProvider);
  final productosDaoInst = ref.read(productosDaoProvider);
  final servicio = VentaInventarioServiceImpl(
    ventasRepository: repositorio,
    kardexRepository: kardexRepo,
    inventarioService: inventarioServ,
    productosDao: productosDaoInst,
  );
  return RegistrarVentaUseCase(servicio);
});

final registrarVentaConInventarioUseCaseProvider = Provider<RegistrarVentaConInventarioUseCase>((ref) {
  final repositorio = ref.read(ventasRepositoryProvider);
  final kardexRepo = ref.read(kardexRepositoryProvider);
  final inventarioServ = ref.read(inventarioServiceProvider);
  final productosDaoInst = ref.read(productosDaoProvider);
  final servicio = VentaInventarioServiceImpl(
    ventasRepository: repositorio,
    kardexRepository: kardexRepo,
    inventarioService: inventarioServ,
    productosDao: productosDaoInst,
  );
  return RegistrarVentaConInventarioUseCase(servicio);
});
