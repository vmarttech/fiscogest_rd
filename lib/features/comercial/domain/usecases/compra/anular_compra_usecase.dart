import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_compra_repository.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_pagar_dao.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/compra/confirmar_compra_services.dart';

/// Anulación controlada de una compra.
///
/// Flujo:
/// 1. Validar estado (solo confirmada / recibida)
/// 2. Revertir inventario + kardex + costo promedio + saldo proveedor
/// 3. Anular la cuenta por pagar asociada (si existe y no tiene abonos)
/// 4. Marcar la compra como anulada
class AnularCompraUseCase {
  AnularCompraUseCase({
    required this.compraRepository,
    required this.services,
    required this.cuentasPagarDao,
  });

  final ICompraRepository compraRepository;
  final ConfirmarCompraServices services;
  final CuentasPagarDao cuentasPagarDao;

  Future<Compra> call(int compraId) async {
    final compra = await compraRepository.obtenerCompraPorId(compraId);
    if (compra == null) {
      throw StateError('Compra no encontrada: $compraId');
    }

    if (compra.estado == EstadoCompra.anulada) {
      throw StateError('La compra ya se encuentra anulada');
    }
    if (compra.estado == EstadoCompra.borrador) {
      throw StateError('No se anulan borradores — elimine directamente');
    }
    if (compra.estado != EstadoCompra.confirmada &&
        compra.estado != EstadoCompra.recibida) {
      throw StateError(
        'Solo se pueden anular compras en estado Confirmada o Recibida',
      );
    }

    // 1. Revertir impactos de inventario, kardex, costos y saldo proveedor
    await services.revertirActualizaciones(compra);

    // 2. Anular la cuenta por pagar asociada (si era a crédito)
    if (compra.esCredito) {
      await cuentasPagarDao.anularCuentaRelacionadaACompra(
        proveedorId: compra.proveedorId,
        monto: compra.totalCompra,
        fechaEmision: compra.fechaEmision,
        conceptoContiene: 'Compra ${compra.nombreProveedor}',
      );
    }

    // 3. Marcar la compra como anulada
    final compraAnulada = await compraRepository.anularCompra(compraId);
    return compraAnulada;
  }
}
