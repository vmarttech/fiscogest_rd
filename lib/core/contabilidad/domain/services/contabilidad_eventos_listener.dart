import 'package:flutter/foundation.dart';
import 'package:fiscogest_rd/core/eventos/evento_bus.dart';
import 'package:fiscogest_rd/core/eventos/eventos_sistema.dart';

/// Escucha eventos del sistema y genera asientos contables automáticos.
///
/// Sigue el mismo patrón que [CompraEventosListener]: se suscribe al EventoBus
/// en la inicialización y se desuscribe al disponerse.
class ContabilidadEventosListener {
  ContabilidadEventosListener() {
    _registrarEscuchas();
    debugPrint('ContabilidadEventosListener: inicializado');
  }

  void _registrarEscuchas() {
    EventoBus.escuchar(EventosSistema.compraConfirmada, _alConfirmarCompra);
    EventoBus.escuchar(EventosSistema.ventaConfirmada, _alConfirmarVenta);
  }

  /// Al confirmar una compra: generar asiento de adquisición.
  Future<void> _alConfirmarCompra(Map<String, dynamic> datos) async {
    final compraId = datos['compraId'] as int?;
    if (compraId == null) return;
    debugPrint('Contabilidad → Compra confirmada ID=$compraId — pendiente de generar asiento');
  }

  /// Al confirmar una venta: generar asiento de ingreso + costo.
  Future<void> _alConfirmarVenta(Map<String, dynamic> datos) async {
    final ventaId = datos['ventaId'] as int?;
    if (ventaId == null) return;
    debugPrint('Contabilidad → Venta confirmada ID=$ventaId — pendiente de generar asiento');
  }

  void dispose() {
    EventoBus.dejarDeEscuchar(
      EventosSistema.compraConfirmada,
      _alConfirmarCompra,
    );
    EventoBus.dejarDeEscuchar(
      EventosSistema.ventaConfirmada,
      _alConfirmarVenta,
    );
    debugPrint('ContabilidadEventosListener: detenido');
  }
}
