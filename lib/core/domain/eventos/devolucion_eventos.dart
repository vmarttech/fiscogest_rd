import 'package:fiscogest_rd/core/domain/eventos/evento_negocio.dart';

class DevolucionProcesada extends EventoNegocio {

  DevolucionProcesada({
    required this.devolucionId,
    required super.usuarioResponsable,
  }) : super(
          fecha: DateTime.now(),
          tipo: 'DevolucionProcesada',
          entidadId: devolucionId,
        );
  final String devolucionId;
}
