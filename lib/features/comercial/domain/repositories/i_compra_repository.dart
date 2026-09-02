import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/detalle_compra.dart';

/// Contrato abstracto para el repositorio de Compras.
///
/// Define operaciones disponibles sobre compras y sus líneas,
/// sin exponer detalles de almacenamiento ni tecnología.
abstract class ICompraRepository {
  /// Registra una nueva compra con sus líneas de detalle.
  /// Devuelve la compra registrada incluyendo su identificador.
  Future<Compra> registrarCompra({
    required Compra compra,
    required List<DetalleCompra> detalles,
  });

  /// Consulta una compra por su identificador único.
  /// Devuelve null si no existe.
  Future<Compra?> obtenerCompraPorId(int compraId);

  /// Obtiene el listado completo de compras registradas.
  Future<List<Compra>> listarCompras();

  /// Obtiene las líneas de detalle correspondientes a una compra.
  Future<List<DetalleCompra>> listarDetallesDeCompra(int compraId);

  /// Actualiza el estado de una compra y marca fecha de confirmación.
  Future<Compra> confirmarCompra(int compraId);
}
