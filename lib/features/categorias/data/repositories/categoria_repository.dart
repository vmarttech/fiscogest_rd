import '../../domain/entities/categoria.dart';

class CategoriaRepository {
  final List<Categoria> _categoriasLocales = [
    Categoria(id: 1, nombre: 'General', descripcion: 'Categoría general por defecto'),
    Categoria(id: 2, nombre: 'Bebidas', descripcion: 'Bebidas y refrescos'),
    Categoria(id: 3, nombre: 'Alimentos', descripcion: 'Productos alimenticios y abarrotes'),
  ];

  Future<List<Categoria>> obtenerCategorias() async {
    return _categoriasLocales;
  }

  Future<void> agregarCategoria(Categoria categoria) async {
    final existe = _categoriasLocales.any((c) => c.nombre.trim().toLowerCase() == categoria.nombre.trim().toLowerCase());
    if (existe) {
      throw Exception('Ya existe una categoría registrada con ese nombre.');
    }
    final nuevoId = _categoriasLocales.isEmpty ? 1 : (_categoriasLocales.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b) + 1);
    _categoriasLocales.add(categoria.copyWith(id: nuevoId));
  }

  Future<void> actualizarCategoria(Categoria categoria) async {
    final duplicada = _categoriasLocales.any((c) => c.id != categoria.id && c.nombre.trim().toLowerCase() == categoria.nombre.trim().toLowerCase());
    if (duplicada) {
      throw Exception('Ya existe otra categoría con ese nombre.');
    }
    final index = _categoriasLocales.indexWhere((c) => c.id == categoria.id);
    if (index != -1) {
      _categoriasLocales[index] = categoria;
    }
  }

  Future<void> eliminarCategoria(int id) async {
    _categoriasLocales.removeWhere((c) => c.id == id);
  }
}
