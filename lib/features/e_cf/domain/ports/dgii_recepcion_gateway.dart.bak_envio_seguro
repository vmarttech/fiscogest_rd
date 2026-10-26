class DgiiRecepcionResultado {
  const DgiiRecepcionResultado({
    required this.ok,
    this.trackId,
    this.codigo,
    this.mensaje,
  });
  final bool ok;
  final String? trackId;
  final String? codigo;
  final String? mensaje;
}

/// Envío a recepción DGII. Solo se implementa en fases de red.
abstract class DgiiRecepcionGateway {
  Future<DgiiRecepcionResultado> enviar(String xmlFirmado);
}
