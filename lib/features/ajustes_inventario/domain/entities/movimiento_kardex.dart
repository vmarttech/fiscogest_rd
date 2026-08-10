import 'package:equatable/equatable.dart';

class MovimientoKardex extends Equatable {

  const MovimientoKardex({
    this.id,
    required this.idProducto,
    required this.tipoMovimiento,
    required this.cantidad,
    required this.saldoActual,
    this.referenciaId,
    required this.motivo,
    required this.usuarioId,
    required this.fechaMovimiento,
  });
  final int? id;
  final int idProducto;
  final String tipoMovimiento;
  final double cantidad;
  final double saldoActual;
  final int? referenciaId;
  final String motivo;
  final int usuarioId;
  final DateTime fechaMovimiento;

  @override
  List<Object?> get props => [
        id,
        idProducto,
        tipoMovimiento,
        cantidad,
        saldoActual,
        referenciaId,
        motivo,
        usuarioId,
        fechaMovimiento,
      ];
}
