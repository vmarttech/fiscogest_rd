import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/domain/entities/ajuste_inventario.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/domain/repositories/ajuste_inventario_repository.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';
import 'package:fiscogest_rd/features/inventario/domain/enums/tipo_movimiento.dart';
import 'package:fiscogest_rd/features/inventario/data/datasources/drift_kardex_datasource.dart';
import 'package:fiscogest_rd/features/inventario/data/repositories/kardex_repository_impl.dart';

class AjusteInventarioRepositoryImpl implements AjusteInventarioRepository {
  AjusteInventarioRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<void> registrarAjuste(AjusteInventario ajuste) async {
    await _db
        .into(_db.ajusteInventarioTable)
        .insert(
          AjusteInventarioTableCompanion(
            productoId: Value(ajuste.productoId),
            tipoAjuste: Value(ajuste.tipoAjuste),
            cantidad: Value(ajuste.cantidad),
            motivo: Value(ajuste.motivo),
            observaciones: Value(ajuste.observaciones),
            usuarioId: Value(ajuste.usuarioId),
            fechaCreacion: Value(ajuste.fechaCreacion.millisecondsSinceEpoch),
          ),
        );
  }

  @override
  Future<List<AjusteInventario>> listarAjustes() async {
    final registros = await _db.select(_db.ajusteInventarioTable).get();
    return registros
        .map(
          (fila) => AjusteInventario(
            id: fila.id,
            productoId: fila.productoId,
            tipoAjuste: fila.tipoAjuste,
            cantidad: fila.cantidad,
            motivo: fila.motivo,
            observaciones: fila.observaciones ?? '',
            usuarioId: fila.usuarioId,
            fechaCreacion: DateTime.fromMillisecondsSinceEpoch(
              fila.fechaCreacion,
            ),
          ),
        )
        .toList();
  }

  @override
  Future<void> actualizarExistencias(
    int productoId,
    double cantidad,
    String tipo,
  ) async {
    final producto = await (_db.select(
      _db.productosTable,
    )..where((p) => p.id.equals(productoId))).getSingle();
    final stockActual = producto.stock ?? 0.0;
    final nuevoStock = tipo == 'entrada'
        ? stockActual + cantidad
        : stockActual - cantidad;
    await (_db.update(_db.productosTable)
          ..where((p) => p.id.equals(productoId)))
        .write(ProductosTableCompanion(stock: Value(nuevoStock)));

    final deltaAjuste = tipo == 'entrada'
        ? cantidad.toDouble()
        : -cantidad.toDouble();
    if (deltaAjuste.abs() > 0.0001) {
      await registrarEnKardex(
        Kardex(
          productoId: productoId,
          tipoMovimiento: deltaAjuste > 0
              ? TipoMovimiento.entrada
              : TipoMovimiento.salida,
          cantidad: deltaAjuste.abs(),
          saldoAnterior: stockActual.toDouble(),
          saldoNuevo: nuevoStock.toDouble(),
          costoUnitario: 0,
          totalMovimiento: 0,
          fechaMovimiento: DateTime.now(),
          documentoReferencia: 'Ajuste inventario',
          observacion: 'Ajuste de inventario',
          usuarioId: 0,
        ),
      );
    }
  }

  @override
  Future<void> registrarEnKardex(dynamic movimiento) async {
    if (movimiento is! Kardex) return;
    await KardexRepositoryImpl(
      DriftKardexDatasource(_db),
    ).registrarMovimiento(movimiento);
  }
}
