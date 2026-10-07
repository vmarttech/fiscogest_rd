// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categoria.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CategoriaImpl _$$CategoriaImplFromJson(Map<String, dynamic> json) =>
    _$CategoriaImpl(
      id: (json['id'] as num?)?.toInt(),
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      codigo: json['codigo'] as String? ?? '',
      padreId: (json['padreId'] as num?)?.toInt(),
      itbisPorCiento: (json['itbisPorCiento'] as num?)?.toDouble(),
      activo: json['activo'] as bool? ?? true,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: json['actualizadoEn'] == null
          ? null
          : DateTime.parse(json['actualizadoEn'] as String),
    );

Map<String, dynamic> _$$CategoriaImplToJson(_$CategoriaImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'descripcion': instance.descripcion,
      'codigo': instance.codigo,
      'padreId': instance.padreId,
      'itbisPorCiento': instance.itbisPorCiento,
      'activo': instance.activo,
      'creadoEn': instance.creadoEn.toIso8601String(),
      'actualizadoEn': instance.actualizadoEn?.toIso8601String(),
    };
