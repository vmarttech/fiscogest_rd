import 'package:fiscogest_rd/core/domain/eventos/evento_negocio.dart';
import 'package:fiscogest_rd/core/domain/eventos/recepcion_eventos.dart';

class SincronizacionService {
  SincronizacionService._interno();
  static final SincronizacionService instancia = SincronizacionService._interno();

  void disparar(EventoNegocio evento) {
    if (evento is RecepcionConfirmada) {
      _alConfirmarRecepcion(evento);
    }
  }

  void _alConfirmarRecepcion(RecepcionConfirmada evento) {
    _actualizarInventarioPorRecepcion(evento.recepcionId);
    _actualizarCostos(evento.compraId);
    _actualizarEstadisticas(evento.tipo, evento.fecha);
    _actualizarReportes(evento.tipo, evento.fecha);
  }

  void _actualizarInventarioPorRecepcion(String recepcionId) {}
  void _actualizarCostos(String documentoId) {}
  void _actualizarEstadisticas(String tipoEvento, DateTime fecha) {}
  void _actualizarReportes(String tipoEvento, DateTime fecha) {}
}
