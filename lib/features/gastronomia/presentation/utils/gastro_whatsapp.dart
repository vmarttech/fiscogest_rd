import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

/// Utilidades WhatsApp / compartir para gastronomía (negocios sin web).
class GastroWhatsapp {
  /// Normaliza teléfono RD a dígitos internacionales.
  static String digitos(String raw) {
    var d = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.isEmpty) return '';
    if (d.length == 10 &&
        (d.startsWith('809') || d.startsWith('829') || d.startsWith('849'))) {
      d = '1$d';
    } else if (d.length == 10) {
      d = '1$d';
    }
    return d;
  }

  static Future<bool> abrir(String telefono, {String mensaje = ''}) async {
    final num = digitos(telefono);
    if (num.isEmpty) return false;
    final uri = Uri.parse(
      mensaje.isEmpty
          ? 'https://wa.me/$num'
          : 'https://wa.me/$num?text=${Uri.encodeComponent(mensaje)}',
    );
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> compartirTexto(String texto, {String? subject}) {
    return Share.share(texto, subject: subject);
  }

  static String mensajePedido({
    required int pedidoId,
    required String nombreCliente,
    required double total,
    required String estado,
    String direccion = '',
  }) {
    final b = StringBuffer();
    b.writeln('Hola${nombreCliente.isNotEmpty ? ' $nombreCliente' : ''},');
    b.writeln('Tu pedido #$pedidoId está *$estado*.');
    b.writeln('Total: RD\$ ${total.toStringAsFixed(2)}');
    if (direccion.trim().isNotEmpty) {
      b.writeln('Entrega: $direccion');
    }
    b.writeln();
    b.writeln('Gracias por preferirnos.');
    return b.toString();
  }
}
