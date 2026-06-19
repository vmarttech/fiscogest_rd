import 'package:fiscogestrd/models/producto.dart';
import 'package:fiscogestrd/services/existencia_service.dart';
import 'package:fiscogestrd/services/producto_service.dart';

class ProductoRepository {
  factory ProductoRepository() => _instance;
  ProductoRepository._internal();
  // ✅ INSTANCIA ÚNICA
  static final ProductoRepository _instance = ProductoRepository._internal();

  // ✅ SOLO LOS SERVICIOS QUE USAMOS
  final ProductoService _productoService = ProductoService();
  final ExistenciaService _existenciaService = ExistenciaService();

  // =====================================================
  // ✅ OBTENER TODOS ACTIVOS
  // =====================================================
  Future<List<Producto>> obtenerTodosActivos() async {
    // Como no tenemos campo "activo", devolvemos todos
    return await _productoService.obtenerTodos();
  }

  // =====================================================
  // ✅ OBTENER TODOS
  // =====================================================
  Future<List<Producto>> obtenerTodos() async {
    return await _productoService.obtenerTodos();
  }

  // =====================================================
  // ✅ OBTENER POR ID
  // =====================================================
  Future<Producto?> obtenerPorId(int id) async {
    return await _productoService.obtenerPorId(id);
  }

  // =====================================================
  // ✅ CREAR
  // =====================================================
  Future<int> crear(Producto producto) async {
    final id = await _productoService.crear(producto);
    if (id > 0) {
      await _existenciaService.inicializarExistenciaDeProducto(
        producto.copyWith(id: id),
      );
    }
    return id;
  }

  // =====================================================
  // ✅ ACTUALIZAR
  // =====================================================
  Future<int> actualizar(Producto producto) async {
    if (producto.id == null) return -1;
    final filas = await _productoService.actualizar(producto);
    if (filas > 0) {
      await _existenciaService.actualizarDatosProductoRelacionado(producto);
    }
    return filas;
  }

  // =====================================================
  // ✅ GUARDAR
  // =====================================================
  Future<int> guardar(Producto producto) async {
    return producto.id == null
        ? await crear(producto)
        : await actualizar(producto);
  }

  // =====================================================
  // ✅ BUSCAR
  // =====================================================
  Future<List<Producto>> buscar(String texto) async {
    final todos = await _productoService.obtenerTodos();
    final filtro = texto.trim().toUpperCase();
    return todos.where((p) {
      return p.codigo.toUpperCase().contains(filtro) ||
          p.nombre.toUpperCase().contains(filtro) ||
          (p.descripcion ?? '').toUpperCase().contains(filtro);
    }).toList();
  }

  // =====================================================
  // ✅ BUSCAR POR RÉGIMEN
  // =====================================================
  Future<List<Producto>> buscarPorRegimen(String regimen) async {
    final todos = await _productoService.obtenerTodos();
    return todos.where((p) => p.regimenImpuesto == regimen).toList();
  }

  // =====================================================
  // ✅ ELIMINACIÓN LÓGICA (COMENTADA POR AHORA)
  // =====================================================
  // Future<int> eliminarLogico(int id) async {
  //   final p = await obtenerPorId(id);
  //   if (p == null) return -1;
  //   return await actualizar(p.copyWith(activo: false));
  // }

  // =====================================================
  // ✅ ELIMINACIÓN FÍSICA
  // =====================================================
  Future<int> eliminarFisico(int id) async {
    await _existenciaService.eliminarPorProductoId(id);
    return await _productoService.eliminar(id);
  }

  // =====================================================
  // ✅ ACTUALIZAR STOCK
  // =====================================================
  Future<void> actualizarNivelStock(int productoId, double nuevoValor) async {
    await _existenciaService.actualizarStockDesdeInventario(
      productoId,
      nuevoValor,
    );
  }

  // =====================================================
  // ✅ RESUMEN DE COSTOS
  // =====================================================
  Map<String, double> obtenerResumenCostos(Producto producto) {
    return _productoService.obtenerResumenCostos(producto);
  }
}
