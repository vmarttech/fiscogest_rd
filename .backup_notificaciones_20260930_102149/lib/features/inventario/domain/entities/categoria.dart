import 'package:freezed_annotation/freezed_annotation.dart';

part 'categoria.freezed.dart';
part 'categoria.g.dart';

@freezed
class Categoria with _$Categoria {
  const factory Categoria({
    int? id,
    required String nombre,
    String? descripcion,
    required DateTime creadoEn,
    DateTime? actualizadoEn,
  }) = _Categoria;

  factory Categoria.fromJson(Map<String, dynamic> json) =>
      _$CategoriaFromJson(json);
}
