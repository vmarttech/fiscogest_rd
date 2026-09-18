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

final calcularTotalesCompraUseCaseProvider = Provider<CalcularTotalesCompraUseCase>((final ref) {
  return const CalcularTotalesCompraUseCase();
});

final actualizarInventarioProvider = Provider<ActualizarInventario>((final ref) {
  final repo = ref.watch(inventarioRepositoryProvider);
  return ActualizarInventario(repo);
});

final actualizarCostosProvider = Provider<ActualizarCostos>((final ref) {
  return const ActualizarCostos();
});

final actualizarSaldoClienteProvider = Provider<ActualizarSaldoCliente>((final ref) {
  final repo = ref.watch(clienteRepositoryProvider);
  return ActualizarSaldoCliente(repo);
});

final actualizarSaldoProveedorProvider = Provider<ActualizarSaldoProveedor>((final ref) {
  final repo = ref.watch(proveedorRepositoryProvider);
  return ActualizarSaldoProveedor(repo);
});

final actualizarCajaProvider = Provider<ActualizarCaja>((final ref) {
  final repo = ref.watch(cajaRepositoryProvider);
  return ActualizarCaja(repo);
});

final actualizarEstadisticasProvider = Provider<ActualizarEstadisticas>((final ref) {
  final repo = ref.watch(estadisticasRepositoryProvider);
  return ActualizarEstadisticas(repo);
});

final actualizarReportesProvider = Provider<ActualizarReportes>((final ref) {
  final repo = ref.watch(reportesRepositoryProvider);
  return ActualizarReportes(repo);
});

final ejecutarActualizacionesProvider = Provider<EjecutarActualizacionesComerciales>((final ref) {
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

final calcularCostoAdquisicionProvider = Provider<CalcularCostoAdquisicion>((final ref) {
  return CalcularCostoAdquisicion();
});

final registrarMovimientoKardexProvider = Provider<RegistrarMovimientoKardex>((final ref) {
  final kardexRepo = ref.watch(kardexRepositoryProvider);
  return RegistrarMovimientoKardex(kardexRepo);
});

final cuentasPagarDaoProvider = Provider<CuentasPagarDao>((final ref) {
  final db = ref.watch(databaseProvider);
  return CuentasPagarDao(db);
});

final confirmarCompraUseCaseProvider = Provider<ConfirmarCompraUseCase>((final ref) {
  return ConfirmarCompraUseCase(
    compraRepository: ref.watch(compraRepositoryProvider),
    ejecutarActualizaciones: ref.watch(ejecutarActualizacionesProvider),
    registrarMovimientoKardex: ref.watch(registrarMovimientoKardexProvider),
    calcularCostoAdquisicion: ref.watch(calcularCostoAdquisicionProvider),
    actualizarSaldoProveedor: ref.watch(actualizarSaldoProveedorProvider),
    cuentasPagarDao: ref.watch(cuentasPagarDaoProvider),
  );
});

final registrarCompraUseCaseProvider = Provider<RegistrarCompraUseCase>((final ref) {
  final repo = ref.watch(compraRepositoryProvider);
  return RegistrarCompraUseCase(repo);
});

final listarComprasUseCaseProvider = Provider<ListarComprasUseCase>((final ref) {
  final repo = ref.watch(compraRepositoryProvider);
  return ListarComprasUseCase(repo);
});

// ✅ ESTE ES EL PROVIDER QUE FALTABA — usado por la página
final listadoComprasProvider = FutureProvider<List<Compra>>((final ref) async {
  final usecase = ref.watch(listarComprasUseCaseProvider);
  return usecase.call();
});

final compraPorIdProvider = FutureProvider.family<Compra?, int>((final ref, final compraId) async {
  return ref.watch(compraRepositoryProvider).obtenerCompraPorId(compraId);
});
