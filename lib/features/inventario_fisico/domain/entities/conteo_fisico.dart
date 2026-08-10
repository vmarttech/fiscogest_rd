import 'package:equatable/equatable.dart';
// ✅ IMPORT OFICIAL package: elimina no reconocido
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/estado_conteo.dart';

class ConteoFisico extends Equatable {
  const ConteoFisico({
    this.id,
    required this.nombreConteo,
    required this.fechaConteo,
    required this.observaciones,
    required this.usuarioId,
    required this.fechaCreacion,
    required this.estado,
  });

  final int? id;
  final String nombreConteo;
  final DateTime fechaConteo;
  final String observaciones;
  final int usuarioId;
  final DateTime fechaCreacion;
  final EstadoConteo estado;

  ConteoFisico copyWith({
    int? id,
    String? nombreConteo,
    DateTime? fechaConteo,
    String? observaciones,
    int? usuarioId,
    DateTime? fechaCreacion,
    EstadoConteo? estado,
  }) {
    return ConteoFisico(
      id: id ?? this.id,
      nombreConteo: nombreConteo ?? this.nombreConteo,
      fechaConteo: fechaConteo ?? this.fechaConteo,
      observaciones: observaciones ?? this.observaciones,
      usuarioId: usuarioId ?? this.usuarioId,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      estado: estado ?? this.estado,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nombreConteo,
        fechaConteo,
        observaciones,
        usuarioId,
        fechaCreacion,
        estado,
      ];
}
