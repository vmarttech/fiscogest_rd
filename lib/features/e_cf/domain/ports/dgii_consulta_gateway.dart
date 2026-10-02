class DgiiConsultaResultado {
  const DgiiConsultaResultado({
    required this.ok,
    this.estadoDgii,
    this.codigo,
    this.mensaje,
    this.payloadRaw,
  });
  final bool ok;
  final String? estadoDgii;
  final String? codigo;
  final String? mensaje;
  final String? payloadRaw;
}

abstract class DgiiConsultaGateway {
  Future<DgiiConsultaResultado> consultar(String trackId);
}
