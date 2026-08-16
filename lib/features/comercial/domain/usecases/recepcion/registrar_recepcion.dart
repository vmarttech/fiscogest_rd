import 'package:fiscogest_rd/features/comercial/domain/entities/recepcion.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_recepcion_repository.dart';
import 'package:fiscogest_rd/core/domain/eventos/recepcion_eventos.dart';
import 'package:fiscogest_rd/core/services/sincronizacion_service.dart';

class RegistrarRecepcion {

  RegistrarRecepcion(this._repo);
  final IRecepcionRepository _repo;

  Future<String> ejecutar(Recepcion recepcion, String usuarioResponsable) async {
    validar(recepcion);
    final recepcionConEstado = _determinarEstado(recepcion);
    final recepcionId = await _repo.crear(recepcionConEstado);

    if (recepcionConEstado.estado == 'completa' || recepcionConEstado.estado == 'parcial') {
      final evento = RecepcionConfirmada(
        recepcionId: recepcionId,
        compraId: recepcionConEstado.compraId ?? '',
        usuarioResponsable: usuarioResponsable,
      );
      SincronizacionService.instancia.disparar(evento);
    }

    return recepcionId;
  }

  void validar(Recepcion recepcion) {
    if (recepcion.compraId == null || recepcion.compraId!.trim().isEmpty) {
      throw ArgumentError('El ID de compra es obligatorio');
    }
    if (recepcion.detalles == null || recepcion.detalles!.isEmpty) {
      throw ArgumentError('Debe incluir al menos un producto en la recepción');
    }
    for (final detalle in recepcion.detalles!) {
      if (detalle.cantidadRecibida != null && detalle.cantidadRecibida! < 0) {
        throw ArgumentError('Cantidad recibida no puede ser negativa');
      }
    }
  }

  Recepcion _determinarEstado(Recepcion recepcion) {
    if (recepcion.detalles == null || recepcion.detalles!.isEmpty) {
      return recepcion.copyWith(estado: 'pendiente');
    }

    final todosCero = recepcion.detalles!
        .every((d) => d.cantidadRecibida == null || d.cantidadRecibida! == 0);
    final todosIgual = recepcion.detalles!.every((d) =>
        d.cantidadPedida != null &&
        d.cantidadRecibida != null &&
        d.cantidadRecibida! >= d.cantidadPedida!);

    final estado = todosCero
        ? 'pendiente'
        : todosIgual
            ? 'completa'
            : 'parcial';

    return recepcion.copyWith(estado: estado);
  }
}
