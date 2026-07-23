import '../../domain/entities/marca.dart';

class MarcaRepository {
  final List<Marca> _marcasLocales = [
    Marca(id: 1, nombre: 'Genérica', descripcion: 'Marca genérica por defecto'),
    Marca(id: 2, nombre: 'Nestlé', descripcion: 'Productos alimenticios'),
    Marca(id: 3, nombre: 'Coca-Cola', descripcion: 'Bebidas y refrescos'),
  ];

  Future<List<Marca>> obtenerMarcas() async {
    return _marcasLocales;
  }

  Future<void> agregarMarca(Marca marca) async {
    final existe = _marcasLocales.any((m) => m.nombre.trim().toLowerCase() == marca.nombre.trim().toLowerCase());
    if (existe) {
      throw Exception('Ya existe una marca registrada con ese nombre.');
    }
    final nuevoId = _marcasLocales.isEmpty ? 1 : (_marcasLocales.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b) + 1);
    _marcasLocales.add(marca.copyWith(id: nuevoId));
  }

  Future<void> actualizarMarca(Marca marca) async {
    final duplicada = _marcasLocales.any((m) => m.id != marca.id && m.nombre.trim().toLowerCase() == marca.nombre.trim().toLowerCase());
    if (duplicada) {
      throw Exception('Ya existe otra marca con ese nombre.');
    }
    final index = _marcasLocales.indexWhere((m) => m.id == marca.id);
    if (index != -1) {
      _marcasLocales[index] = marca;
    }
  }

  Future<void> eliminarMarca(int id) async {
    _marcasLocales.removeWhere((m) => m.id == id);
  }
}
