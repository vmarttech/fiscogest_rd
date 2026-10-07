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
      codigo: json['codigo'] as String? ?? '',
      factorABase: (json['factorABase'] as num?)?.toDouble() ?? 1.0,
      esBase: json['esBase'] as bool? ?? false,
      activo: json['activo'] as bool? ?? true,
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
      'codigo': instance.codigo,
      'factorABase': instance.factorABase,
      'esBase': instance.esBase,
      'activo': instance.activo,
      'creadoEn': instance.creadoEn.toIso8601String(),
      'actualizadoEn': instance.actualizadoEn?.toIso8601String(),
    };
