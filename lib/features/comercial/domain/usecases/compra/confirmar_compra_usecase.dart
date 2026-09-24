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
  final Future<void> Function(Compra) actualizarSaldoProveedor;
  final CuentasPagarDao cuentasPagarDao;

  Future<Compra> call(final int compraId) async {
    final compra = await compraRepository.obtenerCompraPorId(compraId);
    if (compra == null) throw StateError('Compra no encontrada');

    // ✅ Permitir desde Borrador O desde Registrada
    if (compra.estado != EstadoCompra.borrador &&
        compra.estado != EstadoCompra.registrada) {
      throw StateError(
        'Solo se puede confirmar compras en estado Borrador o Registrada',
      );
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

    await ejecutarActualizaciones(compraConfirmada);

    return compraConfirmada;
  }
}
