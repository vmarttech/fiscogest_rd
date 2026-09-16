import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/compra/confirmar_compra_usecase.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/compra/registrar_compra_usecase.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/compra/listar_compras_usecase.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/compra/calcular_totales_compra_usecase.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/calcular_costo_adquisicion.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/ejecutar_actualizaciones_comerciales.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/inventario_providers.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_pagar_dao.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/actualizar_inventario.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/actualizar_costos.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/actualizar_saldo_cliente.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/actualizar_saldo_proveedor.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/actualizar_caja.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/actualizar_estadisticas.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/actualizar_reportes.dart';
import 'package:fiscogest_rd/features/inventario/domain/usecases/registrar_movimiento_kardex.dart';

final calcularTotalesCompraUseCaseProvider = Provider<CalcularTotalesCompraUseCase>((ref) {
  return const CalcularTotalesCompraUseCase();
});

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

final actualizarSaldoProveedorProvider = Provider<ActualizarSaldoProveedor>((ref) {
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

final ejecutarActualizacionesProvider = Provider<EjecutarActualizacionesComerciales>((ref) {
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

final calcularCostoAdquisicionProvider = Provider<CalcularCostoAdquisicion>((ref) {
  return CalcularCostoAdquisicion();
});

final registrarMovimientoKardexProvider = Provider<RegistrarMovimientoKardex>((ref) {
  final kardexRepo = ref.watch(kardexRepositoryProvider);
  return RegistrarMovimientoKardex(kardexRepo);
});

final cuentasPagarDaoProvider = Provider<CuentasPagarDao>((ref) {
  final db = ref.watch(databaseProvider);
  return CuentasPagarDao(db);
});

final confirmarCompraUseCaseProvider = Provider<ConfirmarCompraUseCase>((ref) {
  return ConfirmarCompraUseCase(
    compraRepository: ref.watch(compraRepositoryProvider),
    ejecutarActualizaciones: ref.watch(ejecutarActualizacionesProvider),
    registrarMovimientoKardex: ref.watch(registrarMovimientoKardexProvider),
    calcularCostoAdquisicion: ref.watch(calcularCostoAdquisicionProvider),
    actualizarSaldoProveedor: ref.watch(actualizarSaldoProveedorProvider),
    cuentasPagarDao: ref.watch(cuentasPagarDaoProvider),
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

final compraPorIdProvider = FutureProvider.family<Compra?, int>((ref, compraId) async {
  return ref.watch(compraRepositoryProvider).obtenerCompraPorId(compraId);
});
