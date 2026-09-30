import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/detalle_compra.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart' as repo;
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_compra_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/compra/calcular_totales_compra_usecase.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/compra/confirmar_compra_services.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/compra/confirmar_compra_usecase.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/compra/marcar_como_recibida_usecase.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/compra/marcar_como_pagada_usecase.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/compra/registrar_compra_usecase.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/compra/anular_compra_usecase.dart';

final calcularTotalesCompraUseCaseProvider = Provider<CalcularTotalesCompraUseCase>((Ref ref) {
  // Lee config si el provider existe; si no, 18%
  bool simplificado = false;
  try {
    // Ajusta el nombre del provider si en tu proyecto es otro:
    final cfg = ref.watch(configuracionControllerProvider).valueOrNull;
    simplificado = cfg?.modoSimplificado ?? false;
  } catch (_) {}
  return CalcularTotalesCompraUseCase(tasaItbis: simplificado ? 0.0 : 0.18);
});

final listadoComprasProvider = FutureProvider.autoDispose<List<Compra>>((Ref ref) async {
  try {
    final ICompraRepository repoCompra = ref.watch(repo.compraRepositoryProvider);
    final list = await repoCompra.listarCompras();
    debugPrint('[ListaCompras] ok: ${list.length}');
    return list;
  } catch (e, st) {
    debugPrint('[ListaCompras] ERROR: $e\n$st');
    rethrow;
  }
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
    actualizarSaldoProveedor: (Compra compra) async {
      await svc.actualizarSaldoProveedor(compra);
    },
  );
});

final marcarComoRecibidaUseCaseProvider = Provider.autoDispose<MarcarComoRecibidaUseCase>((Ref ref) {
  return MarcarComoRecibidaUseCase(
    compraRepository: ref.watch(repo.compraRepositoryProvider),
  );
});

final marcarComoRecibidaProvider = Provider.autoDispose<Future<Compra> Function(int)>((Ref ref) {
  final useCase = ref.watch(marcarComoRecibidaUseCaseProvider);
  return (int compraId) async {
    final resultado = await useCase(compraId);
    ref.invalidate(listadoComprasProvider);
    ref.invalidate(compraPorIdProvider(compraId));
    return resultado;
  };
});

final marcarComoPagadaUseCaseProvider = Provider.autoDispose<MarcarComoPagadaUseCase>((Ref ref) {
  return MarcarComoPagadaUseCase(
    compraRepository: ref.watch(repo.compraRepositoryProvider),
  );
});

final marcarComoPagadaProvider = Provider.autoDispose<Future<Compra> Function(int)>((Ref ref) {
  final useCase = ref.watch(marcarComoPagadaUseCaseProvider);
  return (int compraId) async {
    final resultado = await useCase(compraId);
    ref.invalidate(listadoComprasProvider);
    ref.invalidate(compraPorIdProvider(compraId));
    return resultado;
  };
});

final anularCompraUseCaseProvider = Provider.autoDispose<AnularCompraUseCase>((Ref ref) {
  final ConfirmarCompraServices svc = ref.watch(confirmarCompraServicesProvider);
  return AnularCompraUseCase(
    compraRepository: ref.watch(repo.compraRepositoryProvider),
    services: svc,
    cuentasPagarDao: ref.watch(repo.cuentasPagarDaoProvider),
  );
});

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
