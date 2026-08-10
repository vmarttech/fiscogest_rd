import 'package:equatable/equatable.dart';

class DiferenciaConteo extends Equatable {

  const DiferenciaConteo({
    this.id,
    required this.conteoId,
    required this.codigoProducto,
    required this.nombreProducto,
    required this.stockSistema,
    required this.stockFisico,
    required this.diferencia,
    required this.motivo,
    required this.estado,
  });
  final int? id;
  final int conteoId;
  final String codigoProducto;
  final String nombreProducto;
  final double stockSistema;
  final double stockFisico;
  final double diferencia;
  final String motivo;
  final String estado;

  @override
  List<Object?> get props => [
        id,
        conteoId,
        codigoProducto,
        nombreProducto,
        stockSistema,
        stockFisico,
        diferencia,
        motivo,
        estado,
      ];
}
