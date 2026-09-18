import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/detalle_compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_compra_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/compra/calcular_totales_compra_usecase.dart';

class RegistrarCompraUseCase {
  RegistrarCompraUseCase(
    this._compraRepository,
    this._calcularTotales,
  );

  final ICompraRepository _compraRepository;
  final CalcularTotalesCompraUseCase _calcularTotales;

  Future<Compra> call({
    required Compra compra,
    required List<DetalleCompra> detalles,
  }) async {
    if (detalles.isEmpty) {
      throw Exception('La compra debe contener al menos un producto.');
    }

    final detallesCalculados = _calcularTotales.calcularTodasLasLineas(detalles);
    final totales = _calcularTotales.calcularTotalesGenerales(detallesCalculados);

    final compraActualizada = compra.copyWith(
      subtotalSinImpuestos: totales.subtotalSinImpuestos,
      montoDescuentoGlobal: totales.montoDescuentoGlobal,
      montoImpuesto: totales.montoImpuesto,
      tasaImpuesto: totales.tasaImpuesto,
      totalCompra: totales.totalCompra,
    );

    return _compraRepository.registrarCompra(
      compra: compraActualizada,
      detalles: detallesCalculados,
    );
  }
}
