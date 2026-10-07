import 'package:freezed_annotation/freezed_annotation.dart';

part 'marca.freezed.dart';
part 'marca.g.dart';

@freezed
class Marca with _$Marca {
  const factory Marca({
    int? id,
    required String nombre,
    String? descripcion,
    @Default('') String codigo,
    String? fabricante,
    @Default(true) bool activo,
    required DateTime creadoEn,
    DateTime? actualizadoEn,
  }) = _Marca;

  factory Marca.fromJson(Map<String, dynamic> json) => _$MarcaFromJson(json);
}
