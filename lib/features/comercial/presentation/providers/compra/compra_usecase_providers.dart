import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/compra/confirmar_compra_usecase.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/compra/registrar_compra_usecase.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/compra/listar_compras_usecase.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/ejecutar_actualizaciones_comerciales.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/actualizar_inventario.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/actualizar_costos.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/actualizar_saldo_cliente.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/actualizar_saldo_proveedor.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/actualizar_caja.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/actualizar_estadisticas.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/actualizar_reportes.dart';

final actualizarInventarioProvider = Provider<ActualizarInventario>((ref) {
  final repo = ref.watch(inventarioRepositoryProvider);
  return ActualizarInventario(repo);
});

final actualizarCostosProvider = Provider<ActualizarCostos>((ref) {
  return const ActualizarCostos();
});

final actualizarSaldoClienteProvider = Provider<ActualizarSaldoCliente>((ref) {
  final repo = ref.watch(clienteRepositoryProvider);
  return ActualizarSaldoCliente(repo);
});

final actualizarSaldoProveedorProvider = Provider<ActualizarSaldoProveedor>((
  ref,
) {
  final repo = ref.watch(proveedorRepositoryProvider);
  return ActualizarSaldoProveedor(repo);
});

final actualizarCajaProvider = Provider<ActualizarCaja>((ref) {
  final repo = ref.watch(cajaRepositoryProvider);
  return ActualizarCaja(repo);
});

final actualizarEstadisticasProvider = Provider<ActualizarEstadisticas>((ref) {
  final repo = ref.watch(estadisticasRepositoryProvider);
  return ActualizarEstadisticas(repo);
});

final actualizarReportesProvider = Provider<ActualizarReportes>((ref) {
  final repo = ref.watch(reportesRepositoryProvider);
  return ActualizarReportes(repo);
});

final ejecutarActualizacionesProvider =
    Provider<EjecutarActualizacionesComerciales>((ref) {
      return EjecutarActualizacionesComerciales(
        actualizarInventario: ref.watch(actualizarInventarioProvider),
        actualizarCostos: ref.watch(actualizarCostosProvider),
        actualizarSaldoCliente: ref.watch(actualizarSaldoClienteProvider),
        actualizarSaldoProveedor: ref.watch(actualizarSaldoProveedorProvider),
        actualizarCaja: ref.watch(actualizarCajaProvider),
        actualizarEstadisticas: ref.watch(actualizarEstadisticasProvider),
        actualizarReportes: ref.watch(actualizarReportesProvider),
      );
    });

final confirmarCompraUseCaseProvider = Provider<ConfirmarCompraUseCase>((ref) {
  final compraRepository = ref.watch(compraRepositoryProvider);
  final ejecutarActualizaciones = ref.watch(ejecutarActualizacionesProvider);
  return ConfirmarCompraUseCase(
    compraRepository: compraRepository,
    ejecutarActualizaciones: ejecutarActualizaciones,
  );
});

final registrarCompraUseCaseProvider = Provider<RegistrarCompraUseCase>((ref) {
  final repo = ref.watch(compraRepositoryProvider);
  return RegistrarCompraUseCase(repo);
});

final listarComprasUseCaseProvider = Provider<ListarComprasUseCase>((ref) {
  final repo = ref.watch(compraRepositoryProvider);
  return ListarComprasUseCase(repo);
});

// ✅ Provider para obtener una compra por ID — bien estructurado, siguiendo patrón del proyecto
final compraPorIdProvider = FutureProvider.family<Compra?, int>((ref, compraId) async {
  final compraRepository = ref.watch(compraRepositoryProvider);
  return compraRepository.obtenerCompraPorId(compraId);
});
