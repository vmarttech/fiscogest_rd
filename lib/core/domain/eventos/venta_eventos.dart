import 'package:fiscogest_rd/core/domain/eventos/evento_negocio.dart';

class VentaConfirmada extends EventoNegocio {

  VentaConfirmada({
    required this.ventaId,
    required super.usuarioResponsable,
  }) : super(
          fecha: DateTime.now(),
          tipo: 'VentaConfirmada',
          entidadId: ventaId,
        );
  final String ventaId;
}
