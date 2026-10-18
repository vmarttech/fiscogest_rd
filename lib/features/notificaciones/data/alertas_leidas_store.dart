import 'package:shared_preferences/shared_preferences.dart';

/// IDs de alertas operativas marcadas como leídas (local).
class AlertasLeidasStore {
  static const _key = 'alertas_operativas_leidas_v1';

  Future<Set<String>> obtenerLeidas() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? const <String>[];
    return list.toSet();
  }

  Future<void> marcarLeida(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_key) ?? const <String>[]).toSet()
      ..add(id);
    await prefs.setStringList(_key, set.toList());
  }

  Future<void> marcarVarias(Iterable<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_key) ?? const <String>[]).toSet()
      ..addAll(ids);
    await prefs.setStringList(_key, set.toList());
  }

  /// Quita IDs que ya no aplican (condición resuelta → pueden volver a avisar).
  Future<void> sincronizarActivas(Set<String> idsActivos) async {
    final prefs = await SharedPreferences.getInstance();
    final leidas = (prefs.getStringList(_key) ?? const <String>[]).toSet();
    final limpias = leidas.intersection(idsActivos);
    if (limpias.length != leidas.length) {
      await prefs.setStringList(_key, limpias.toList());
    }
  }

  Future<void> limpiarTodas() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final alertasLeidasStore = AlertasLeidasStore();
