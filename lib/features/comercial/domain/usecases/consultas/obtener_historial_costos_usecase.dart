import 'package:fiscogest_rd/features/comercial/domain/entities/historial_costo.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_compra_repository.dart';

/// Obtiene el historial de costos de un producto a partir de las compras confirmadas.
class ObtenerHistorialCostosUseCase {
  const ObtenerHistorialCostosUseCase(this._compraRepo);

  final ICompraRepository _compraRepo;

  Future<HistorialCostoResumen> call(int productoId) async {
    final compras = await _compraRepo.listarCompras();

    // Solo compras que no estén en borrador ni anuladas
    final comprasValidas = compras.where((c) {
      final e = c.estado.name.toLowerCase();
      return e != 'borrador' && e != 'anulada';
    }).toList();

    final List<HistorialCostoItem> items = [];

    for (final compra in comprasValidas) {
      final detalles = await _compraRepo.listarDetallesDeCompra(compra.id);
      for (final d in detalles) {
        if (d.productoId != productoId) continue;
        items.add(
          HistorialCostoItem(
            compraId: compra.id,
            fecha: compra.fechaEmision,
            proveedorNombre: compra.nombreProveedor,
            costoUnitario: d.costoUnitario,
            costoAdquisicion: d.costoAdquisicion > 0 ? d.costoAdquisicion : d.costoUnitario,
            cantidad: d.cantidad,
            ncf: compra.ncf,
          ),
        );
      }
    }

    // Ordenar por fecha descendente
    items.sort((a, b) => b.fecha.compareTo(a.fecha));

    final nombre = await _nombreDesdeDetalle(productoId);

    final ultimoCosto = items.isEmpty ? 0.0 : items.first.costoAdquisicion;
    final costoPromedio = items.isEmpty
        ? 0.0
        : items.map((e) => e.costoAdquisicion).reduce((a, b) => a + b) / items.length;

    double variacion = 0;
    double variacionPct = 0;
    if (items.length >= 2) {
      final anterior = items[1].costoAdquisicion;
      variacion = ultimoCosto - anterior;
      if (anterior != 0) {
        variacionPct = (variacion / anterior) * 100;
      }
    }

    return HistorialCostoResumen(
      productoId: productoId,
      nombreProducto: nombre,
      items: items,
      ultimoCosto: ultimoCosto,
      costoPromedio: costoPromedio,
      variacion: variacion,
      variacionPorcentaje: variacionPct,
    );
  }

  Future<String> _nombreDesdeDetalle(int productoId) async {
    final compras = await _compraRepo.listarCompras();
    for (final c in compras) {
      final dets = await _compraRepo.listarDetallesDeCompra(c.id);
      for (final d in dets) {
        if (d.productoId == productoId && d.nombreProducto.isNotEmpty) {
          return d.nombreProducto;
        }
      }
    }
    return 'Producto #$productoId';
  }
}
