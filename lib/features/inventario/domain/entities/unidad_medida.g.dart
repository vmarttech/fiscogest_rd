// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unidad_medida.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UnidadMedidaImpl _$$UnidadMedidaImplFromJson(Map<String, dynamic> json) =>
    _$UnidadMedidaImpl(
      id: (json['id'] as num?)?.toInt(),
      nombre: json['nombre'] as String,
      abreviatura: json['abreviatura'] as String?,
      descripcion: json['descripcion'] as String?,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: json['actualizadoEn'] == null
          ? null
          : DateTime.parse(json['actualizadoEn'] as String),
    );

Map<String, dynamic> _$$UnidadMedidaImplToJson(_$UnidadMedidaImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'abreviatura': instance.abreviatura,
      'descripcion': instance.descripcion,
      'creadoEn': instance.creadoEn.toIso8601String(),
      'actualizadoEn': instance.actualizadoEn?.toIso8601String(),
    };
