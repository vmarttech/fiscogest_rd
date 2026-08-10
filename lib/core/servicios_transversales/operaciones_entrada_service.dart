import 'package:fiscogest_rd/core/database/app_database.dart';
// ELIMINADO: import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/entrada.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_entrada_repository.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_producto_repository.dart';

class OperacionesEntradaService {
  OperacionesEntradaService({
    required IEntradaRepository entradaRepository,
    required IProductoRepository productoRepository,
    required AppDatabase db,
  })  : _entradaRepository = entradaRepository,
        _productoRepository = productoRepository,
        _db = db;

  final IEntradaRepository _entradaRepository;
  final IProductoRepository _productoRepository;
  final AppDatabase _db;

  /// Coordina la operación transaccional completa: registra entrada y actualiza stock en una sola operación segura.
  /// ÚNICO punto autorizado para ejecutar esta lógica de negocio.
  Future<void> registrarEntradaConAjusteStock({
    required int productoId,
    required double cantidad,
    required String motivo,
    required String usuario,
  }) async {
    // ✅ TRANSACCIÓN ATÓMICA: si algo falla, nada se guarda
    await _db.transaction(() async {
      // 1. Crear la entidad de entrada (ÚNICO lugar válido para crearla en todo el flujo)
      final nuevaEntrada = Entrada(
        productoId: productoId,
        cantidad: cantidad,
        motivo: motivo,
        usuario: usuario,
        fecha: DateTime.now(),
      );

      // 2. Registrar la entrada en el repositorio
      await _entradaRepository.registrarEntrada(nuevaEntrada);

      // 3. Obtener el producto actual y actualizar stock
      final producto = await _productoRepository.obtenerProductoPorId(productoId);
      if (producto != null) {
        final stockActualizado = producto.stock + cantidad;
        final productoModificado = producto.copyWith(stock: stockActualizado);
        await _productoRepository.actualizarProducto(productoModificado);
      }
    });
  }
}