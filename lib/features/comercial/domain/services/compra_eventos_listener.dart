import 'package:fiscogest_rd/core/eventos/evento_bus.dart';
import 'package:fiscogest_rd/core/eventos/eventos_sistema.dart';

/// Escucha confirmación de compra.
/// El impacto en inventario/costos/proveedor lo hace [ConfirmarCompraServices]
/// vía [ConfirmarCompraUseCase] — aquí NO se vuelve a sumar stock ni kardex.
class CompraEventosListener {
  CompraEventosListener() {
    _registrarEscuchas();
  }

  void _registrarEscuchas() {
    EventoBus.escuchar(EventosSistema.compraConfirmada, _alConfirmarCompra);
  }

  Future<void> _alConfirmarCompra(Map<String, dynamic> datos) async {
    // Intencionalmente vacío: evita duplicar cantidad y costo.
    // Si necesitas notificaciones/UI, hazlo aquí sin tocar inventario.
  }

  void dispose() {
    EventoBus.dejarDeEscuchar(
      EventosSistema.compraConfirmada,
      _alConfirmarCompra,
    );
  }
}
