// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unidad_medida.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UnidadMedida _$UnidadMedidaFromJson(Map<String, dynamic> json) {
  return _UnidadMedida.fromJson(json);
}

/// @nodoc
mixin _$UnidadMedida {
  int? get id => throw _privateConstructorUsedError;
  String get nombre => throw _privateConstructorUsedError;
  String? get abreviatura => throw _privateConstructorUsedError;
  String? get descripcion => throw _privateConstructorUsedError;
  DateTime get creadoEn => throw _privateConstructorUsedError;
  DateTime? get actualizadoEn => throw _privateConstructorUsedError;

  /// Serializes this UnidadMedida to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UnidadMedida
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UnidadMedidaCopyWith<UnidadMedida> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UnidadMedidaCopyWith<$Res> {
  factory $UnidadMedidaCopyWith(
    UnidadMedida value,
    $Res Function(UnidadMedida) then,
  ) = _$UnidadMedidaCopyWithImpl<$Res, UnidadMedida>;
  @useResult
  $Res call({
    int? id,
    String nombre,
    String? abreviatura,
    String? descripcion,
    DateTime creadoEn,
    DateTime? actualizadoEn,
  });
}

/// @nodoc
class _$UnidadMedidaCopyWithImpl<$Res, $Val extends UnidadMedida>
    implements $UnidadMedidaCopyWith<$Res> {
  _$UnidadMedidaCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UnidadMedida
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? nombre = null,
    Object? abreviatura = freezed,
    Object? descripcion = freezed,
    Object? creadoEn = null,
    Object? actualizadoEn = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int?,
            nombre: null == nombre
                ? _value.nombre
                : nombre // ignore: cast_nullable_to_non_nullable
                      as String,
            abreviatura: freezed == abreviatura
                ? _value.abreviatura
                : abreviatura // ignore: cast_nullable_to_non_nullable
                      as String?,
            descripcion: freezed == descripcion
                ? _value.descripcion
                : descripcion // ignore: cast_nullable_to_non_nullable
                      as String?,
            creadoEn: null == creadoEn
                ? _value.creadoEn
                : creadoEn // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            actualizadoEn: freezed == actualizadoEn
                ? _value.actualizadoEn
                : actualizadoEn // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UnidadMedidaImplCopyWith<$Res>
    implements $UnidadMedidaCopyWith<$Res> {
  factory _$$UnidadMedidaImplCopyWith(
    _$UnidadMedidaImpl value,
    $Res Function(_$UnidadMedidaImpl) then,
  ) = __$$UnidadMedidaImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int? id,
    String nombre,
    String? abreviatura,
    String? descripcion,
    DateTime creadoEn,
    DateTime? actualizadoEn,
  });
}

/// @nodoc
class __$$UnidadMedidaImplCopyWithImpl<$Res>
    extends _$UnidadMedidaCopyWithImpl<$Res, _$UnidadMedidaImpl>
    implements _$$UnidadMedidaImplCopyWith<$Res> {
  __$$UnidadMedidaImplCopyWithImpl(
    _$UnidadMedidaImpl _value,
    $Res Function(_$UnidadMedidaImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UnidadMedida
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? nombre = null,
    Object? abreviatura = freezed,
    Object? descripcion = freezed,
    Object? creadoEn = null,
    Object? actualizadoEn = freezed,
  }) {
    return _then(
      _$UnidadMedidaImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int?,
        nombre: null == nombre
            ? _value.nombre
            : nombre // ignore: cast_nullable_to_non_nullable
                  as String,
        abreviatura: freezed == abreviatura
            ? _value.abreviatura
            : abreviatura // ignore: cast_nullable_to_non_nullable
                  as String?,
        descripcion: freezed == descripcion
            ? _value.descripcion
            : descripcion // ignore: cast_nullable_to_non_nullable
                  as String?,
        creadoEn: null == creadoEn
            ? _value.creadoEn
            : creadoEn // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        actualizadoEn: freezed == actualizadoEn
            ? _value.actualizadoEn
            : actualizadoEn // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UnidadMedidaImpl implements _UnidadMedida {
  const _$UnidadMedidaImpl({
    this.id,
    required this.nombre,
    this.abreviatura,
    this.descripcion,
    required this.creadoEn,
    this.actualizadoEn,
  });

  factory _$UnidadMedidaImpl.fromJson(Map<String, dynamic> json) =>
      _$$UnidadMedidaImplFromJson(json);

  @override
  final int? id;
  @override
  final String nombre;
  @override
  final String? abreviatura;
  @override
  final String? descripcion;
  @override
  final DateTime creadoEn;
  @override
  final DateTime? actualizadoEn;

  @override
  String toString() {
    return 'UnidadMedida(id: $id, nombre: $nombre, abreviatura: $abreviatura, descripcion: $descripcion, creadoEn: $creadoEn, actualizadoEn: $actualizadoEn)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnidadMedidaImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nombre, nombre) || other.nombre == nombre) &&
            (identical(other.abreviatura, abreviatura) ||
                other.abreviatura == abreviatura) &&
            (identical(other.descripcion, descripcion) ||
                other.descripcion == descripcion) &&
            (identical(other.creadoEn, creadoEn) ||
                other.creadoEn == creadoEn) &&
            (identical(other.actualizadoEn, actualizadoEn) ||
                other.actualizadoEn == actualizadoEn));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    nombre,
    abreviatura,
    descripcion,
    creadoEn,
    actualizadoEn,
  );

  /// Create a copy of UnidadMedida
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnidadMedidaImplCopyWith<_$UnidadMedidaImpl> get copyWith =>
      __$$UnidadMedidaImplCopyWithImpl<_$UnidadMedidaImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UnidadMedidaImplToJson(this);
  }
}

abstract class _UnidadMedida implements UnidadMedida {
  const factory _UnidadMedida({
    final int? id,
    required final String nombre,
    final String? abreviatura,
    final String? descripcion,
    required final DateTime creadoEn,
    final DateTime? actualizadoEn,
  }) = _$UnidadMedidaImpl;

  factory _UnidadMedida.fromJson(Map<String, dynamic> json) =
      _$UnidadMedidaImpl.fromJson;

  @override
  int? get id;
  @override
  String get nombre;
  @override
  String? get abreviatura;
  @override
  String? get descripcion;
  @override
  DateTime get creadoEn;
  @override
  DateTime? get actualizadoEn;

  /// Create a copy of UnidadMedida
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnidadMedidaImplCopyWith<_$UnidadMedidaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
