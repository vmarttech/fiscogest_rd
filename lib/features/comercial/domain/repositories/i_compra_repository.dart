import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/detalle_compra.dart';

/// Contrato abstracto para el repositorio de Compras.
abstract class ICompraRepository {
  /// Registra una nueva compra con sus líneas de detalle.
  Future<Compra> registrarCompra({
    required Compra compra,
    required List<DetalleCompra> detalles,
  });

  /// Consulta una compra por su identificador único.
  Future<Compra?> obtenerCompraPorId(int compraId);

  /// Obtiene el listado completo de compras.
  Future<List<Compra>> listarCompras();

  /// Obtiene las líneas de detalle de una compra.
  Future<List<DetalleCompra>> listarDetallesDeCompra(int compraId);

  /// Confirma una compra: cambia estado y fecha de confirmación.
  Future<Compra> confirmarCompra(int compraId);

  /// Anula una compra: cambia estado a anulada y fecha de actualización.
  Future<Compra> anularCompra(int compraId);
}
