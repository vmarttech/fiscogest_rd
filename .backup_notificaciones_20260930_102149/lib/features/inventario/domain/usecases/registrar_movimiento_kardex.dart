import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';
import 'package:fiscogest_rd/features/inventario/domain/enums/tipo_movimiento.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/ikardex_repository.dart';

class RegistrarMovimientoKardex {
  RegistrarMovimientoKardex(this._repo);
  final IKardexRepository _repo;

  Future<void> ejecutar({
    required int productoId,
    required TipoMovimiento tipoMovimiento,
    required double cantidad,
    required double saldoAnterior,
    required double saldoNuevo,
    required double costoUnitario,
    required double totalMovimiento,
    DateTime? fechaMovimiento,
    String? documentoReferencia,
    String? observacion,
    required int usuarioId, // ✅ PARÁMETRO AGREGADO
  }) async {
    final movimiento = Kardex(
      id: null,
      productoId: productoId,
      tipoMovimiento: tipoMovimiento,
      cantidad: cantidad,
      saldoAnterior: saldoAnterior,
      saldoNuevo: saldoNuevo,
      costoUnitario: costoUnitario,
      totalMovimiento: totalMovimiento,
      fechaMovimiento: fechaMovimiento ?? DateTime.now(),
      documentoReferencia: documentoReferencia,
      observacion: observacion,
      usuarioId: usuarioId, // ✅ CAMPO OBLIGATORIO
    );

    await _repo.registrarMovimiento(movimiento);
  }
}
