import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';
import 'package:fiscogest_rd/features/inventario/domain/enums/tipo_movimiento.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/ikardex_repository.dart';

class RegistrarTransferencia {
  RegistrarTransferencia(this._repo);
  final IKardexRepository _repo;

  Future<void> ejecutar({
    required int productoId,
    required double cantidad,
    required double saldoAnterior,
    required double saldoNuevo,
    required double costoUnitario,
    required int usuarioId,
    String? observacion,
  }) async {
    final docRef = 'TRF-${DateTime.now().millisecondsSinceEpoch}';

    await _repo.registrarMovimiento(Kardex(
      id: null,
      productoId: productoId,
      tipoMovimiento: TipoMovimiento.salida,
      cantidad: cantidad,
      saldoAnterior: saldoAnterior,
      saldoNuevo: saldoNuevo,
      costoUnitario: costoUnitario,
      totalMovimiento: cantidad * costoUnitario,
      fechaMovimiento: DateTime.now(),
      documentoReferencia: docRef,
      observacion: observacion,
      usuarioId: usuarioId,
    ));

    await _repo.registrarMovimiento(Kardex(
      id: null,
      productoId: productoId,
      tipoMovimiento: TipoMovimiento.entrada,
      cantidad: cantidad,
      saldoAnterior: saldoAnterior - cantidad,
      saldoNuevo: saldoNuevo,
      costoUnitario: costoUnitario,
      totalMovimiento: cantidad * costoUnitario,
      fechaMovimiento: DateTime.now(),
      documentoReferencia: docRef,
      observacion: observacion,
      usuarioId: usuarioId,
    ));
  }
}
