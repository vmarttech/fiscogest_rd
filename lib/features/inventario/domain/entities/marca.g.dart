// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'marca.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MarcaImpl _$$MarcaImplFromJson(Map<String, dynamic> json) => _$MarcaImpl(
  id: (json['id'] as num?)?.toInt(),
  nombre: json['nombre'] as String,
  descripcion: json['descripcion'] as String?,
  codigo: json['codigo'] as String? ?? '',
  fabricante: json['fabricante'] as String?,
  activo: json['activo'] as bool? ?? true,
  creadoEn: DateTime.parse(json['creadoEn'] as String),
  actualizadoEn: json['actualizadoEn'] == null
      ? null
      : DateTime.parse(json['actualizadoEn'] as String),
);

Map<String, dynamic> _$$MarcaImplToJson(_$MarcaImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'descripcion': instance.descripcion,
      'codigo': instance.codigo,
      'fabricante': instance.fabricante,
      'activo': instance.activo,
      'creadoEn': instance.creadoEn.toIso8601String(),
      'actualizadoEn': instance.actualizadoEn?.toIso8601String(),
    };
