import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/estado_conteo.dart';

class ConteoFisico {
  ConteoFisico({
    this.id,
    required this.nombreConteo,
    required this.fechaConteo,
    this.observaciones,
    required this.usuarioId,
    required this.fechaCreacion,
    required this.estado,
  });

  final int? id;
  final String nombreConteo;
  final DateTime fechaConteo;
  final String? observaciones;
  final int usuarioId;
  final DateTime fechaCreacion;
  final EstadoConteo estado;
}
