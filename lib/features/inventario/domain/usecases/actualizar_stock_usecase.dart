import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/ikardex_repository.dart';
import 'package:fiscogest_rd/features/inventario/domain/enums/tipo_movimiento.dart';

// ✅ CONSTRUCTOR PRIMERO: corrige aviso sort_constructors_first
class ActualizarStockUseCase {
  final IKardexRepository _kardexRepo;
  ActualizarStockUseCase(this._kardexRepo);

  Future<void> call({
    required int productoId,
    required String tipoMovimientoStr,
    required double cantidad,
    required double saldoAnterior,
    required double saldoNuevo,
    required double costoUnitario,
    required double totalMovimiento,
    required int usuarioId,
    String? documentoReferencia,
    String? observacion,
    DateTime? fechaMovimiento,
  }) async {
    // ✅ CONVERSIÓN SEGURA: String → Enum TipoMovimiento, elimina error asignación
    final tipoMovimiento = TipoMovimiento.values.firstWhere(
      (e) => e.name == tipoMovimientoStr,
      orElse: () => TipoMovimiento.ajuste,
    );

    final movimientoKardex = Kardex(
      id: null,
      productoId: productoId,
      tipoMovimiento: tipoMovimiento.name,
      cantidad: cantidad,
      saldoAnterior: saldoAnterior,
      saldoNuevo: saldoNuevo,
      costoUnitario: costoUnitario,
      totalMovimiento: totalMovimiento,
      documentoReferencia: documentoReferencia,
      observacion: observacion,
      usuarioId: usuarioId,
      fechaMovimiento: fechaMovimiento ?? DateTime.now(),
    );

    await _kardexRepo.registrarMovimiento(movimientoKardex);
  }
}
