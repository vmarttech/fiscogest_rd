import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/detalle_compra.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart' as repo;
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_compra_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/compra/calcular_totales_compra_usecase.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/compra/confirmar_compra_services.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/compra/confirmar_compra_usecase.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/compra/registrar_compra_usecase.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/compra/anular_compra_usecase.dart';

final calcularTotalesCompraUseCaseProvider = Provider<CalcularTotalesCompraUseCase>((Ref ref) {
  return const CalcularTotalesCompraUseCase();
});

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
    cuentasPagarDao: ref.watch(repo.cuentasPagarDaoProvider),
    ejecutarActualizaciones: svc.ejecutarActualizaciones,
    registrarMovimientoKardex: svc.registrarMovimientoKardex,
    calcularCostoAdquisicion: svc.calcularCostoAdquisicion,
    actualizarSaldoProveedor: (int compraId) async {
      final Compra? compra = await ref.watch(compraPorIdProvider(compraId).future);
      if (compra == null) throw StateError('Compra no encontrada: $compraId');
      await svc.actualizarSaldoProveedor(compra);
    },
  );
});

final anularCompraUseCaseProvider = Provider.autoDispose<AnularCompraUseCase>((Ref ref) {
  final ConfirmarCompraServices svc = ref.watch(confirmarCompraServicesProvider);
  return AnularCompraUseCase(
    compraRepository: ref.watch(repo.compraRepositoryProvider),
    services: svc,
    cuentasPagarDao: ref.watch(repo.cuentasPagarDaoProvider),
  );
});

/// Helper listo para usar desde la UI
final anularCompraProvider = Provider.autoDispose<Future<Compra> Function(int)>((Ref ref) {
  final useCase = ref.watch(anularCompraUseCaseProvider);
  return (int compraId) async {
    final resultado = await useCase(compraId);
    ref.invalidate(listadoComprasProvider);
    ref.invalidate(compraPorIdProvider(compraId));
    return resultado;
  };
});

final registrarCompraUseCaseProvider = Provider.autoDispose<Future<Compra> Function({required Compra compra, required List<DetalleCompra> detalles})>((Ref ref) {
  final CalcularTotalesCompraUseCase calculador = ref.watch(calcularTotalesCompraUseCaseProvider);
  final ICompraRepository repoCompra = ref.read(repo.compraRepositoryProvider);
  final RegistrarCompraUseCase casoUso = RegistrarCompraUseCase(repoCompra, calculador);
  return ({required compra, required detalles}) async {
    final Compra resultado = await casoUso(compra: compra, detalles: detalles);
    ref.invalidate(listadoComprasProvider);
    return resultado;
  };
});
