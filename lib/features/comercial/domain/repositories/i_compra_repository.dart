import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/detalle_compra.dart';

abstract class ICompraRepository {
  Future<Compra> registrarCompra({
    required Compra compra,
    required List<DetalleCompra> detalles,
  });

  Future<Compra?> obtenerCompraPorId(int compraId);

  Future<List<Compra>> listarCompras();

  Future<List<DetalleCompra>> listarDetallesDeCompra(int compraId);

  Future<Compra> confirmarCompra(int compraId);

  Future<Compra> marcarComoRecibida(int compraId);

  Future<Compra> anularCompra(int compraId);
}
