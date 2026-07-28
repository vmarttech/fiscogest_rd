import 'package:fiscogest_rd/features/unidades/domain/entities/unidad.dart';

class UnidadRepository {
  final List<Unidad> _unidadesLocales = [
    Unidad(id: 1, nombre: 'Unidad', abreviatura: 'UND'),
    Unidad(id: 2, nombre: 'Kilogramo', abreviatura: 'KG'),
    Unidad(id: 3, nombre: 'Litro', abreviatura: 'LT'),
    Unidad(id: 4, nombre: 'Metro', abreviatura: 'MT'),
  ];

  Future<List<Unidad>> obtenerUnidades() async {
    return _unidadesLocales;
  }

  Future<void> agregarUnidad(Unidad unidad) async {
    final existe = _unidadesLocales.any((u) => u.nombre.trim().toLowerCase() == unidad.nombre.trim().toLowerCase());
    if (existe) {
      throw Exception('Ya existe una unidad registrada con ese nombre.');
    }
    final nuevoId = _unidadesLocales.isEmpty ? 1 : (_unidadesLocales.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b) + 1);
    _unidadesLocales.add(unidad.copyWith(id: nuevoId));
  }

  Future<void> actualizarUnidad(Unidad unidad) async {
    final duplicada = _unidadesLocales.any((u) => u.id != unidad.id && u.nombre.trim().toLowerCase() == unidad.nombre.trim().toLowerCase());
    if (duplicada) {
      throw Exception('Ya existe otra unidad con ese nombre.');
    }
    final index = _unidadesLocales.indexWhere((u) => u.id == unidad.id);
    if (index != -1) {
      _unidadesLocales[index] = unidad;
    }
  }

  Future<void> eliminarUnidad(int id) async {
    _unidadesLocales.removeWhere((u) => u.id == id);
  }
}
