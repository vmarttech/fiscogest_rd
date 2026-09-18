import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/detalle_compra.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart' as repo;
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_compra_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/compra/confirmar_compra_services.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/compra/confirmar_compra_usecase.dart';

final listadoComprasProvider = FutureProvider.autoDispose<List<Compra>>((Ref ref) async {
  final ICompraRepository repoCompra = ref.watch(repo.compraRepositoryProvider);
  return repoCompra.listarCompras();
});

final compraPorIdProvider = FutureProvider.autoDispose.family<Compra?, int>((Ref ref, int id) async {
  final ICompraRepository repoCompra = ref.watch(repo.compraRepositoryProvider);
  return repoCompra.obtenerCompraPorId(id);
});

final confirmarCompraServicesProvider = Provider<ConfirmarCompraServices>((Ref ref) {
  return ConfirmarCompraServices(
    kardexRepo: ref.watch(repo.kardexRepositoryProvider),
    productoRepo: ref.watch(repo.inventarioProductoRepositoryProvider),
    proveedorRepo: ref.watch(repo.proveedorRepositoryProvider),
    compraRepo: ref.watch(repo.compraRepositoryProvider),
  );
});

final confirmarCompraUseCaseProvider = Provider.autoDispose<ConfirmarCompraUseCase>((Ref ref) {
  final ConfirmarCompraServices svc = ref.watch(confirmarCompraServicesProvider);
  return ConfirmarCompraUseCase(
    compraRepository: ref.watch(repo.compraRepositoryProvider),
    ejecutarActualizaciones: svc.ejecutarActualizaciones,
    registrarMovimientoKardex: svc.registrarMovimientoKardex,
    calcularCostoAdquisicion: svc.calcularCostoAdquisicion,
    actualizarSaldoProveedor: (int proveedorId) async {
      final List<Compra> todas = await ref.watch(listadoComprasProvider.future);
      final Compra compra = todas.firstWhere(
        (Compra c) => c.proveedorId == proveedorId && c.esCredito,
        orElse: () => throw StateError('Compra no encontrada para proveedor $proveedorId'),
      );
      await svc.actualizarSaldoProveedor(compra);
    },
    cuentasPagarDao: ref.watch(repo.cuentasPagarDaoProvider),
  );
});

final registrarCompraUseCaseProvider = Provider.autoDispose<Future<Compra> Function({required Compra compra, required List<DetalleCompra> detalles})>((Ref ref) {
  return ({required compra, required detalles}) async {
    final ICompraRepository repoCompra = ref.read(repo.compraRepositoryProvider);
    final Compra resultado = await repoCompra.registrarCompra(compra: compra, detalles: detalles);
    ref.invalidate(listadoComprasProvider);
    return resultado;
  };
});
