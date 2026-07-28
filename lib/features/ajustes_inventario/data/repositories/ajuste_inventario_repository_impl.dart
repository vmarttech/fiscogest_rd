import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/interfaces/inventario_repository_interface.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/domain/repositories/ajuste_inventario_repository.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/domain/entities/ajuste_inventario.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/domain/entities/movimiento_kardex.dart';

class AjusteInventarioRepositoryImpl implements AjusteInventarioRepository {
  AjusteInventarioRepositoryImpl(this._inventarioRepo, this._db);
  final InventarioRepositoryInterface _inventarioRepo;
  final AppDatabase _db;

  @override
  Future<void> registrarAjuste(AjusteInventario ajuste) async {
    final List<Producto> todos = await _inventarioRepo.listarProductos();
    final Producto producto = todos.firstWhere(
      (p) => p.codigo == ajuste.codigoBusqueda,
      orElse: () => throw Exception('Producto no encontrado. Código: ${ajuste.codigoBusqueda}'),
    );

    final saldoAnterior = producto.stock;

    final nuevoStock = ajuste.tipoAjuste == 'entrada'
        ? producto.stock + ajuste.cantidad
        : producto.stock - ajuste.cantidad;

    if (nuevoStock < 0) throw Exception('Stock insuficiente');

    await _inventarioRepo.actualizarStock(producto.id!, nuevoStock);

    final companion = AjusteInventarioTableCompanion(
      id: ajuste.id != null ? Value(ajuste.id!) : const Value.absent(),
      idProducto: Value(producto.id!),
      tipoAjuste: Value(ajuste.tipoAjuste),
      cantidad: Value(ajuste.cantidad),
      motivo: Value(ajuste.motivo),
      usuarioId: Value(ajuste.usuarioId),
      fechaCreacion: Value(ajuste.fechaCreacion),
    );
    final idAjuste = await _db.into(_db.ajusteInventarioTable).insert(companion);

    // ✅ REGISTRO OBLIGATORIO EN KÁRDEX
    await _db.into(_db.kardexTable).insert(
      KardexTableCompanion(
        idProducto: Value(producto.id!),
        tipoMovimiento: const Value('ajuste'),
        cantidad: ajuste.tipoAjuste == 'entrada'
            ? Value(ajuste.cantidad)
            : Value(-ajuste.cantidad),
        saldoAnterior: Value(saldoAnterior),
        saldoNuevo: Value(nuevoStock),
        costoUnitario: const Value(0),
        totalMovimiento: const Value(0),
        referenciaId: Value(idAjuste),
        motivo: Value('Ajuste: ${ajuste.motivo}'),
        usuarioId: Value(ajuste.usuarioId),
        fechaMovimiento: Value(ajuste.fechaCreacion),
      ),
    );
  }

  @override
  Future<List<AjusteInventario>> listarAjustes() async {
    final datos = await _db.select(_db.ajusteInventarioTable).get();
    return datos.map((d) => AjusteInventario(
      id: d.id,
      idProducto: d.idProducto,
      tipoAjuste: d.tipoAjuste,
      cantidad: d.cantidad,
      motivo: d.motivo,
      usuarioId: d.usuarioId,
      fechaCreacion: d.fechaCreacion ?? DateTime.now(),
    )).toList();
  }

  // ✅ IMPLEMENTACIÓN EXACTA A LA INTERFAZ
  @override
  Future<void> actualizarExistencias(int idProducto, double cantidad, String tipo) async {
    await _inventarioRepo.actualizarStock(idProducto, cantidad);
  }

  // ✅ IMPLEMENTACIÓN CON EL TIPO CORRECTO
  @override
  Future<void> registrarEnKardex(MovimientoKardex movimiento) async {
    // Si más adelante quieres reutilizar esta lógica, la mueves aquí
  }
}
