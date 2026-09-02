class EventoNegocio {
  const EventoNegocio({
    required this.fecha,
    required this.tipo,
    required this.entidadId,
    required this.usuarioResponsable,
  });
  final DateTime fecha;
  final String tipo;
  final String entidadId;
  final String usuarioResponsable;
}
