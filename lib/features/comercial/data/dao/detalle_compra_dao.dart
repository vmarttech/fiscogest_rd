import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/compras_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/detalle_compra_table.dart';
part 'detalle_compra_dao.g.dart';

@DriftAccessor(tables: [DetalleCompraTable, ComprasTable])
class DetalleCompraDao extends DatabaseAccessor<AppDatabase>
    with _$DetalleCompraDaoMixin {
  DetalleCompraDao(super.db);

  static ({double montoDescuento, double subtotal}) calcularLinea({
    required double cantidad,
    required double costoUnitario,
    required double descuentoPorcentaje,
  }) {
    final importeBruto = cantidad * costoUnitario;
    final montoDescuento = importeBruto * (descuentoPorcentaje / 100);
    final subtotal = importeBruto - montoDescuento;
    return (montoDescuento: montoDescuento, subtotal: subtotal);
  }

  Future<int> insertDetalleCompra(DetalleCompraTableCompanion detalle) async {
    final calculado = calcularLinea(
      cantidad: detalle.cantidad.value ?? 0.0,
      costoUnitario: detalle.costoUnitario.value ?? 0.0,
      descuentoPorcentaje: detalle.descuentoPorcentaje.value ?? 0.0,
    );
    return await into<DetalleCompraTable, DetalleCompraTableData>(
      detalleCompraTable,
    ).insert(
      detalle.copyWith(
        montoDescuentoLinea: Value(calculado.montoDescuento),
        subtotalLinea: Value(calculado.subtotal),
      ),
    );
  }

  Future<List<DetalleCompraTableData>> obtenerDetallesPorCompra(
    int compraId,
  ) async {
    return await (select<DetalleCompraTable, DetalleCompraTableData>(
            detalleCompraTable,
          )
          ..where((t) => t.compraId.equals(compraId))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  Future<int> recalcularDetallesPorCompra(int compraId) async {
    final lista = await obtenerDetallesPorCompra(compraId);
    int contador = 0;
    for (final fila in lista) {
      final calc = calcularLinea(
        cantidad: fila.cantidad ?? 0.0,
        costoUnitario: fila.costoUnitario ?? 0.0,
        descuentoPorcentaje: fila.descuentoPorcentaje ?? 0.0,
      );
      final afectadas =
          await update<DetalleCompraTable, DetalleCompraTableData>(
            detalleCompraTable,
          ).replace(
            DetalleCompraTableCompanion(
              id: Value(fila.id),
              compraId: Value(fila.compraId),
              productoId: Value(fila.productoId),
              nombreProducto: Value(fila.nombreProducto),
              cantidad: Value(fila.cantidad),
              costoUnitario: Value(fila.costoUnitario),
              descuentoPorcentaje: Value(fila.descuentoPorcentaje),
              montoDescuentoLinea: Value(calc.montoDescuento),
              subtotalLinea: Value(calc.subtotal),
            ),
          );
      contador += afectadas as int;
    }
    return contador;
  }
}
