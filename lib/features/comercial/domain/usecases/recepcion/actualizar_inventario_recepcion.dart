import 'package:fiscogest_rd/features/comercial/domain/entities/recepcion.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_inventario_repository.dart';

class ActualizarInventarioRecepcion {
  ActualizarInventarioRecepcion(this._inventarioRepo);

  final IInventarioRepository _inventarioRepo;

  Future<void> ejecutar(final Recepcion recepcion) async {
    if (recepcion.detalles == null || recepcion.detalles!.isEmpty) {
      throw ArgumentError('No hay productos para actualizar inventario');
    }

    for (final detalle in recepcion.detalles!) {
      if (detalle.productoId == null) {
        throw ArgumentError('Producto sin identificar');
      }

      final cantidadRecibida = detalle.cantidadRecibida ?? 0;
      if (cantidadRecibida > 0) {
        await _inventarioRepo.aumentarExistencias(
          productoId: detalle.productoId!,
          cantidad: cantidadRecibida,
        );
      }
    }
  }
}
