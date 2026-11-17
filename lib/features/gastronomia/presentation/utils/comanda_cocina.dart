import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/gastronomia/presentation/utils/gastro_whatsapp.dart';

/// Ticket de cocina (sin precios) para compartir/imprimir desde un pedido.
class ComandaCocina {
  static Future<void> compartir(PedidoGastronomiaData pedido,
      List<PedidoGastronomiaLineaData> lineas) async {
    final b = StringBuffer();
    b.writeln('=== COMANDA COCINA ===');
    b.writeln('Pedido #${pedido.id} · ${pedido.tipo}');
    b.writeln('Cliente: ${pedido.nombreCliente}');
    if (pedido.notas.isNotEmpty) b.writeln('Notas: ${pedido.notas}');
    b.writeln('---');
    for (final l in lineas) {
      b.writeln('${l.cantidad.toInt()}x ${l.nombreSnapshot}');
      if (l.notas.isNotEmpty) b.writeln('   -> ${l.notas}');
    }
    b.writeln('=== FIN ===');
    await GastroWhatsapp.compartirTexto(b.toString(),
        subject: 'Comanda #${pedido.id}');
  }
}
