import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_compra_repository.dart';

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
  final dynamic ejecutarActualizaciones;
  final dynamic registrarMovimientoKardex;
  final dynamic calcularCostoAdquisicion;
  final dynamic actualizarSaldoProveedor;
  final dynamic cuentasPagarDao;

  Future<Compra> call(int compraId) async {
    final compra = await compraRepository.obtenerCompraPorId(compraId);
    if (compra == null) throw StateError('Compra no encontrada');
    if (compra.estado != EstadoCompra.borrador) {
      throw StateError('Solo se puede confirmar compras en estado Borrador');
    }

    final fechaVencimientoFinal = compra.fechaVencimientoCalculada;
    final compraConfirmada = await compraRepository.confirmarCompra(compraId);

    if (compra.esCredito) {
      await cuentasPagarDao.crearCuentaPorPagar(
        proveedorId: compra.proveedorId,
        numeroDocumento: compra.numeroComprobante,
        concepto: 'Compra ${compra.nombreProveedor}',
        monto: compra.totalCompra,
        fechaEmision: compra.fechaEmision,
        fechaVencimiento: fechaVencimientoFinal,
        tipoGasto: TipoGasto.compra,
        estado: PagarEstado.pendiente,
      );
    }

    await actualizarSaldoProveedor(compra.proveedorId);
    return compraConfirmada;
  }
}
