import 'package:fiscogest_rd/features/licencias/domain/device_fingerprint.dart';

/// Estados de dominio para la futura respuesta del validador remoto.
/// No contienen nombres ni parámetros de RPC ni de tablas.
enum EstadoValidacionDispositivo {
  nuevo,
  registrado,
  pruebaUtilizada,
  negocioExistente,
  concesionPromocional,
  autorizado,
  pendiente,
  rechazado,
}

class SolicitudValidacionDispositivo {
  const SolicitudValidacionDispositivo({required this.identidad});
  final DeviceIdentity identidad;
}

class ResultadoValidacionDispositivo {
  const ResultadoValidacionDispositivo({
    required this.estado,
    this.mensajeUsuario,
    this.fechaInicio,
    this.fechaFin,
  });

  final EstadoValidacionDispositivo estado;
  final String? mensajeUsuario;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;

  bool get puedeContinuar =>
      estado == EstadoValidacionDispositivo.autorizado ||
      estado == EstadoValidacionDispositivo.concesionPromocional;
}

/// Punto de extensión. Se conectará al contrato aprobado de Supabase sin
/// delegar al cliente la concesión de pruebas ni la edición de fechas.
abstract interface class ValidadorDispositivoRemoto {
  Future<ResultadoValidacionDispositivo> validar(
    SolicitudValidacionDispositivo solicitud,
  );
}
