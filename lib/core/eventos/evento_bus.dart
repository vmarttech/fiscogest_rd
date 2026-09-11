typedef CallbackEvento = void Function(Map<String, dynamic> datos);

class EventoBus {
  static final Map<String, List<CallbackEvento>> _suscriptores = {};

  static void emitir(String nombre, Map<String, dynamic> datos) {
    if (!_suscriptores.containsKey(nombre)) return;
    for (final CallbackEvento callback in _suscriptores[nombre]!) {
      try {
        callback(Map<String, dynamic>.unmodifiable(datos));
      } catch (_) {
        // Silenciamos errores en los callbacks
      }
    }
  }

  static void escuchar(String nombre, CallbackEvento callback) {
    if (!_suscriptores.containsKey(nombre)) {
      _suscriptores[nombre] = <CallbackEvento>[];
    }
    _suscriptores[nombre]!.add(callback);
  }

  static void dejarDeEscuchar(String nombre, CallbackEvento callback) {
    if (!_suscriptores.containsKey(nombre)) return;
    _suscriptores[nombre]!.remove(callback);
    if (_suscriptores[nombre]!.isEmpty) {
      _suscriptores.remove(nombre);
    }
  }
}
