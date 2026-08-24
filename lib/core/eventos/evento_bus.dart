class EventoBus {
  static final Map<String, List<Function>> _suscriptores = {};

  static void emitir(String nombre, Map<String, dynamic> datos) {
    if (!_suscriptores.containsKey(nombre)) return;
    for (final callback in _suscriptores[nombre]!) {
      try {
        callback(Map<String, dynamic>.unmodifiable(datos));
      } catch (_) {}
    }
  }

  static void escuchar(String nombre, Function callback) {
    if (!_suscriptores.containsKey(nombre)) {
      _suscriptores[nombre] = [];
    }
    _suscriptores[nombre]!.add(callback);
  }

  static void dejarDeEscuchar(String nombre, Function callback) {
    if (!_suscriptores.containsKey(nombre)) return;
    _suscriptores[nombre]!.remove(callback);
    if (_suscriptores[nombre]!.isEmpty) {
      _suscriptores.remove(nombre);
    }
  }
}
