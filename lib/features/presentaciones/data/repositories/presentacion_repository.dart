import 'package:fiscogest_rd/features/presentaciones/domain/entities/presentacion.dart';

class PresentacionRepository {
  final List<Presentacion> _presentacionesLocales = [
    Presentacion(id: 1, nombre: 'Unidad', abreviatura: 'UND'),
    Presentacion(id: 2, nombre: 'Caja', abreviatura: 'CAJ'),
    Presentacion(id: 3, nombre: 'Kilogramo', abreviatura: 'KG'),
    Presentacion(id: 4, nombre: 'Litro', abreviatura: 'LT'),
  ];

  Future<List<Presentacion>> obtenerPresentaciones() async {
    return _presentacionesLocales;
  }

  Future<void> agregarPresentacion(Presentacion presentacion) async {
    final existe = _presentacionesLocales.any((p) => p.nombre.trim().toLowerCase() == presentacion.nombre.trim().toLowerCase());
    if (existe) {
      throw Exception('Ya existe una presentación registrada con ese nombre.');
    }
    final nuevoId = _presentacionesLocales.isEmpty ? 1 : (_presentacionesLocales.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b) + 1);
    _presentacionesLocales.add(presentacion.copyWith(id: nuevoId));
  }

  Future<void> actualizarPresentacion(Presentacion presentacion) async {
    final duplicada = _presentacionesLocales.any((p) => p.id != presentacion.id && p.nombre.trim().toLowerCase() == presentacion.nombre.trim().toLowerCase());
    if (duplicada) {
      throw Exception('Ya existe otra presentación con ese nombre.');
    }
    final index = _presentacionesLocales.indexWhere((p) => p.id == presentacion.id);
    if (index != -1) {
      _presentacionesLocales[index] = presentacion;
    }
  }

  Future<void> eliminarPresentacion(int id) async {
    _presentacionesLocales.removeWhere((p) => p.id == id);
  }
}
