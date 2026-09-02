import 'package:fiscogest_rd/core/domain/eventos/evento_negocio.dart';

class RecepcionConfirmada extends EventoNegocio {
  RecepcionConfirmada({
    required this.recepcionId,
    required this.compraId,
    required super.usuarioResponsable,
  }) : super(
         fecha: DateTime.now(),
         tipo: 'RecepcionConfirmada',
         entidadId: recepcionId.toString(),
       );

  final int recepcionId;
  final int? compraId;
}
