import 'package:freezed_annotation/freezed_annotation.dart';

part 'unidad_medida.freezed.dart';
part 'unidad_medida.g.dart';

@freezed
class UnidadMedida with _$UnidadMedida {
  const factory UnidadMedida({
    int? id,
    required String nombre,
    String? abreviatura,
    String? descripcion,
    required DateTime creadoEn,
    DateTime? actualizadoEn,
  }) = _UnidadMedida;

  factory UnidadMedida.fromJson(Map<String, dynamic> json) => _$UnidadMedidaFromJson(json);
}
