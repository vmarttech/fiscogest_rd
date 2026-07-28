import 'package:freezed_annotation/freezed_annotation.dart';

part 'kardex.freezed.dart';

enum TipoMovimiento {
  entrada,
  salida,
  ajuste,
  transferencia,
  devolucion,
  traslado,
}

@freezed
class Kardex with _$Kardex {
  const factory Kardex({
    int? id,
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
    required int usuarioId,
  }) = _Kardex;
}
