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
/// 3. (Opcional) Anular la cuenta por pagar asociada
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
    //    TODO: implementar cuando el DAO tenga un método seguro de anulación
    //    por ejemplo: await cuentasPagarDao.anularPorProveedorYMonto(...)
    //    Por ahora se deja como no-bloqueante para no romper la anulación.
    if (compra.esCredito) {
      // Placeholder seguro: no hacemos nada hasta que exista el método en el DAO.
      // Cuando esté listo, descomentar y ajustar:
      // await cuentasPagarDao.anularCuentaRelacionadaACompra(compra);
    }

    // 3. Marcar la compra como anulada
    final compraAnulada = await compraRepository.anularCompra(compraId);
    return compraAnulada;
  }
}
