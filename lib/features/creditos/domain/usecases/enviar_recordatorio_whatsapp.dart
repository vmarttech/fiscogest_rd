import 'package:fiscogest_rd/core/ui/app_formatters.dart';

/// Resultado de preparar un recordatorio de cobranza por WhatsApp.
class RecordatorioWhatsAppResultado {
  const RecordatorioWhatsAppResultado({
    required this.uri,
    required this.mensaje,
    required this.telefonoE164,
  });

  /// URI lista para launchUrl (https://wa.me/18xxxxxxxx?text=...)
  final Uri uri;

  /// Texto generado (útil para copiar al portapapeles si falla el launch).
  final String mensaje;

  /// Teléfono normalizado solo dígitos con código país (ej. 18095551234).
  final String telefonoE164;
}

/// Use case comercial: prepara el enlace y el mensaje de cobranza amigable.
///
/// No lanza WhatsApp (eso es infraestructura/UI). Solo construye el payload.
/// El WhatsApp que se abre es el del dispositivo del comercio.
class EnviarRecordatorioWhatsApp {
  const EnviarRecordatorioWhatsApp();

  /// Normaliza teléfonos de RD a formato internacional sin '+'.
  /// Acepta: 809..., 829..., 849..., 1809..., +1 809..., etc.
  /// Retorna null si no se puede interpretar como móvil/fijo RD válido.
  static String? normalizarTelefonoRd(String? crudo) {
    if (crudo == null) return null;
    final digitos = crudo.replaceAll(RegExp(r'\D'), '');
    if (digitos.isEmpty) return null;

    // Ya trae código país 1 + 10 dígitos
    if (digitos.length == 11 && digitos.startsWith('1')) {
      final area = digitos.substring(1, 4);
      if (_esAreaRd(area)) return digitos;
      return null;
    }

    // 10 dígitos locales (área + número)
    if (digitos.length == 10) {
      final area = digitos.substring(0, 3);
      if (_esAreaRd(area)) return '1$digitos';
      return null;
    }

    // 7 dígitos sin área → no se puede asumir
    return null;
  }

  static bool _esAreaRd(String area) =>
      area == '809' || area == '829' || area == '849';

  /// Mensaje sutil, personalizado y listo para WhatsApp.
  static String construirMensaje({
    required String nombreCliente,
    required String nombreNegocio,
    required double saldoPendiente,
    String? numeroCuenta,
    String? notaExtra,
  }) {
    final nombre = nombreCliente.trim().isEmpty
        ? 'estimado cliente'
        : nombreCliente.trim().split(RegExp(r'\s+')).first;

    final buffer = StringBuffer();
    buffer.writeln(
      '¡Hola, $nombre! Te saluda $nombreNegocio.',
    );
    buffer.writeln(
      'Esperamos que estés bien. Te escribimos para recordarte que tienes un balance pendiente de ${formatRd(saldoPendiente)}.',
    );
    if (numeroCuenta != null && numeroCuenta.trim().isNotEmpty) {
      buffer.writeln('Referencia: ${numeroCuenta.trim()}.');
    }
    buffer.writeln(
      'Puedes pasar por el local o hacer una transferencia a nuestra cuenta.',
    );
    if (notaExtra != null && notaExtra.trim().isNotEmpty) {
      buffer.writeln(notaExtra.trim());
    }
    buffer.write('¡Gracias por tu apoyo continuo!');
    return buffer.toString();
  }

  /// Prepara URI + mensaje. Lanza [ArgumentError] si el teléfono no es válido.
  RecordatorioWhatsAppResultado preparar({
    required String telefonoCliente,
    required String nombreCliente,
    required String nombreNegocio,
    required double saldoPendiente,
    String? numeroCuenta,
    String? notaExtra,
  }) {
    final e164 = normalizarTelefonoRd(telefonoCliente);
    if (e164 == null) {
      throw ArgumentError(
        'Teléfono inválido. Use un número de RD (809, 829 o 849).',
      );
    }
    if (saldoPendiente <= 0.009) {
      throw ArgumentError('No hay saldo pendiente para recordar.');
    }

    final mensaje = construirMensaje(
      nombreCliente: nombreCliente,
      nombreNegocio: nombreNegocio,
      saldoPendiente: saldoPendiente,
      numeroCuenta: numeroCuenta,
      notaExtra: notaExtra,
    );

    final uri = Uri.parse(
      'https://wa.me/$e164?text=${Uri.encodeComponent(mensaje)}',
    );

    return RecordatorioWhatsAppResultado(
      uri: uri,
      mensaje: mensaje,
      telefonoE164: e164,
    );
  }
}
