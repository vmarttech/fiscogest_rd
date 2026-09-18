import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_compra_repository.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_pagar_dao.dart';

class ConfirmarCompraUseCase {
  ConfirmarCompraUseCase({
    required this.compraRepository,
    required this.ejecutarActualizaciones,
    required this.registrarMovimientoKardex,
    required this.calcularCostoAdquisicion,
    required this.actualizarSaldoProveedor,
    required this.cuentasPagarDao,
  });

  final ICompraRepository compraRepository;
  final Future<void> Function(Compra) ejecutarActualizaciones;
  final Future<void> Function(Compra) registrarMovimientoKardex;
  final Future<void> Function(Compra) calcularCostoAdquisicion;
  final Future<void> Function(int) actualizarSaldoProveedor;
  final CuentasPagarDao cuentasPagarDao;

  Future<Compra> call(final int compraId) async {
    final compra = await compraRepository.obtenerCompraPorId(compraId);
    if (compra == null) throw StateError('Compra no encontrada');
    if (compra.estado != EstadoCompra.borrador) {
      throw StateError('Solo se puede confirmar compras en estado Borrador');
    }

    final fechaVencimientoFinal = compra.fechaVencimientoCalculada;
    final compraConfirmada = await compraRepository.confirmarCompra(compraId);

    if (compra.esCredito) {
      await cuentasPagarDao.registrarCuentaPagar(
        proveedorId: compra.proveedorId,
        concepto: 'Compra ${compra.nombreProveedor}',
        monto: compra.totalCompra,
        fechaEmision: compra.fechaEmision,
        fechaVencimiento: fechaVencimientoFinal!,
        tipoGasto: TipoGasto.compra,
        estado: PagarEstado.pendiente,
      );
    }

    await calcularCostoAdquisicion(compraConfirmada);
    await registrarMovimientoKardex(compraConfirmada);
    await ejecutarActualizaciones(compraConfirmada);
    await actualizarSaldoProveedor(compra.proveedorId);

    return compraConfirmada;
  }
}
