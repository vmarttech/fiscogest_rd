import 'dart:async';

import 'package:flutter/services.dart';

/// Detecta lecturas de scanners USB (keyboard wedge).
///
/// Los scanners USB se enumeran como teclado: envían caracteres muy rápido
/// y terminan con Enter. Este servicio distingue eso de la escritura humana
/// y emite el código por un [Stream] global.
///
/// Compatible con prácticamente todos los scanners HID (Honeywell, Zebra,
/// Symbol, Genéricos chinos, etc.) sin drivers adicionales.
class UsbBarcodeScannerService {
  UsbBarcodeScannerService._();
  static final UsbBarcodeScannerService instance = UsbBarcodeScannerService._();

  final _controller = StreamController<String>.broadcast();

  /// Códigos leídos por cualquier scanner USB conectado.
  Stream<String> get onScan => _controller.stream;

  final StringBuffer _buffer = StringBuffer();
  DateTime? _lastKeyAt;

  /// Intervalo máximo entre teclas para considerarlo "rápido" (scanner).
  /// Escritura humana suele ser > 80–100 ms entre teclas.
  static const Duration maxIntervaloTeclas = Duration(milliseconds: 45);

  /// Longitud mínima para aceptar un código (evita falsos positivos).
  static const int minLongitud = 3;

  /// Timeout: si pasan muchos ms sin tecla, se limpia el buffer.
  static const Duration timeoutBuffer = Duration(milliseconds: 120);

  bool _activo = false;
  bool habilitado = true;

  /// Activa el listener global (llamar una vez al iniciar la app en desktop).
  void start() {
    if (_activo) return;
    HardwareKeyboard.instance.addHandler(_onKey);
    _activo = true;
  }

  void stop() {
    if (!_activo) return;
    HardwareKeyboard.instance.removeHandler(_onKey);
    _activo = false;
    _buffer.clear();
  }

  /// Permite desactivar temporalmente (p.ej. diálogos de texto libre).

  bool _onKey(KeyEvent event) {
    if (!habilitado) return false;
    if (event is! KeyDownEvent) return false;

    final now = DateTime.now();

    // Enter / NumpadEnter → posible fin de lectura del scanner
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final codigo = _buffer.toString().trim();
      _buffer.clear();
      _lastKeyAt = null;

      if (codigo.length >= minLongitud) {
        // Emitir sin consumir el Enter: así el TextField con foco
        // también recibe onSubmitted si aplica.
        _controller.add(codigo);
      }
      return false;
    }

    // Solo caracteres imprimibles de 1 glifo
    final ch = event.character;
    if (ch == null || ch.isEmpty || ch.length > 1) {
      // Teclas especiales (Shift, Ctrl, F-keys…) → no forman parte del código
      // Si hay un gap grande, limpiamos por si acaso.
      if (_lastKeyAt != null &&
          now.difference(_lastKeyAt!) > timeoutBuffer) {
        _buffer.clear();
        _lastKeyAt = null;
      }
      return false;
    }

    // Si pasó mucho tiempo desde la última tecla → reiniciar buffer
    // (escritura humana lenta no debe acumularse como código).
    if (_lastKeyAt != null &&
        now.difference(_lastKeyAt!) > maxIntervaloTeclas) {
      _buffer.clear();
    }

    _buffer.write(ch);
    _lastKeyAt = now;
    return false; // nunca bloqueamos teclas normales
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
