import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/salida.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_salida_repository.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_producto_repository.dart';

class OperacionesSalidaService {
  OperacionesSalidaService({
    required ISalidaRepository salidaRepository,
    required IProductoRepository productoRepository,
    required AppDatabase db,
  })  : _salidaRepository = salidaRepository,
        _productoRepository = productoRepository,
        _db = db;

  final ISalidaRepository _salidaRepository;
  final IProductoRepository _productoRepository;
  final AppDatabase _db;

  /// ÚNICO punto autorizado para registrar salida: valida stock, registra y actualiza existencias en transacción segura.
  Future<void> registrarSalidaConValidacionStock({
    required int productoId,
    required int cantidad,
    required String motivo,
    required String usuario,
  }) async {
    await _db.transaction(() async {
      // 1. Validar stock disponible
      final producto = await _productoRepository.obtenerProductoPorId(productoId);
      if (producto == null) throw Exception('Producto no encontrado');
      if (producto.stock < cantidad) {
        throw Exception('Stock insuficiente: Disponible ${producto.stock}, solicitado $cantidad');
      }

      // 2. Crear entidad (ÚNICO lugar válido)
      final nuevaSalida = Salida(
        productoId: productoId,
        cantidad: cantidad,
        motivo: motivo,
        usuario: usuario,
        fecha: DateTime.now(),
      );

      // 3. Registrar salida
      await _salidaRepository.registrarSalida(nuevaSalida);

      // 4. Actualizar existencias
      final productoActualizado = producto.copyWith(stock: producto.stock - cantidad);
      await _productoRepository.actualizarProducto(productoActualizado);
    });
  }
}