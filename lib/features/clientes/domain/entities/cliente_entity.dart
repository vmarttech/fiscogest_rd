import 'package:freezed_annotation/freezed_annotation.dart';

part 'cliente_entity.freezed.dart';
part 'cliente_entity.g.dart';

@freezed
class ClienteEntity with _$ClienteEntity {
  const factory ClienteEntity({
    int? id,
    required String codigo,
    required String nombre,
    required String rncCedula,
    required String telefono,
    required String correo,
    required String direccion,
    @Default(true) bool activo,
    @Default(0.0) double saldoPendiente,
  }) = _ClienteEntity;

  factory ClienteEntity.fromJson(Map<String, dynamic> json) =>
      _$ClienteEntityFromJson(json);
}
