// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cliente_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ClienteEntity _$ClienteEntityFromJson(Map<String, dynamic> json) {
  return _ClienteEntity.fromJson(json);
}

/// @nodoc
mixin _$ClienteEntity {
  int? get id => throw _privateConstructorUsedError;
  String get codigo => throw _privateConstructorUsedError;
  String get nombre => throw _privateConstructorUsedError;
  String get rncCedula => throw _privateConstructorUsedError;
  String get telefono => throw _privateConstructorUsedError;
  String get correo => throw _privateConstructorUsedError;
  String get direccion => throw _privateConstructorUsedError;
  bool get activo => throw _privateConstructorUsedError;

  /// Serializes this ClienteEntity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ClienteEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClienteEntityCopyWith<ClienteEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClienteEntityCopyWith<$Res> {
  factory $ClienteEntityCopyWith(
    ClienteEntity value,
    $Res Function(ClienteEntity) then,
  ) = _$ClienteEntityCopyWithImpl<$Res, ClienteEntity>;
  @useResult
  $Res call({
    int? id,
    String codigo,
    String nombre,
    String rncCedula,
    String telefono,
    String correo,
    String direccion,
    bool activo,
  });
}

/// @nodoc
class _$ClienteEntityCopyWithImpl<$Res, $Val extends ClienteEntity>
    implements $ClienteEntityCopyWith<$Res> {
  _$ClienteEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClienteEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? codigo = null,
    Object? nombre = null,
    Object? rncCedula = null,
    Object? telefono = null,
    Object? correo = null,
    Object? direccion = null,
    Object? activo = null,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int?,
            codigo: null == codigo
                ? _value.codigo
                : codigo // ignore: cast_nullable_to_non_nullable
                      as String,
            nombre: null == nombre
                ? _value.nombre
                : nombre // ignore: cast_nullable_to_non_nullable
                      as String,
            rncCedula: null == rncCedula
                ? _value.rncCedula
                : rncCedula // ignore: cast_nullable_to_non_nullable
                      as String,
            telefono: null == telefono
                ? _value.telefono
                : telefono // ignore: cast_nullable_to_non_nullable
                      as String,
            correo: null == correo
                ? _value.correo
                : correo // ignore: cast_nullable_to_non_nullable
                      as String,
            direccion: null == direccion
                ? _value.direccion
                : direccion // ignore: cast_nullable_to_non_nullable
                      as String,
            activo: null == activo
                ? _value.activo
                : activo // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ClienteEntityImplCopyWith<$Res>
    implements $ClienteEntityCopyWith<$Res> {
  factory _$$ClienteEntityImplCopyWith(
    _$ClienteEntityImpl value,
    $Res Function(_$ClienteEntityImpl) then,
  ) = __$$ClienteEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int? id,
    String codigo,
    String nombre,
    String rncCedula,
    String telefono,
    String correo,
    String direccion,
    bool activo,
  });
}

/// @nodoc
class __$$ClienteEntityImplCopyWithImpl<$Res>
    extends _$ClienteEntityCopyWithImpl<$Res, _$ClienteEntityImpl>
    implements _$$ClienteEntityImplCopyWith<$Res> {
  __$$ClienteEntityImplCopyWithImpl(
    _$ClienteEntityImpl _value,
    $Res Function(_$ClienteEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ClienteEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? codigo = null,
    Object? nombre = null,
    Object? rncCedula = null,
    Object? telefono = null,
    Object? correo = null,
    Object? direccion = null,
    Object? activo = null,
  }) {
    return _then(
      _$ClienteEntityImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int?,
        codigo: null == codigo
            ? _value.codigo
            : codigo // ignore: cast_nullable_to_non_nullable
                  as String,
        nombre: null == nombre
            ? _value.nombre
            : nombre // ignore: cast_nullable_to_non_nullable
                  as String,
        rncCedula: null == rncCedula
            ? _value.rncCedula
            : rncCedula // ignore: cast_nullable_to_non_nullable
                  as String,
        telefono: null == telefono
            ? _value.telefono
            : telefono // ignore: cast_nullable_to_non_nullable
                  as String,
        correo: null == correo
            ? _value.correo
            : correo // ignore: cast_nullable_to_non_nullable
                  as String,
        direccion: null == direccion
            ? _value.direccion
            : direccion // ignore: cast_nullable_to_non_nullable
                  as String,
        activo: null == activo
            ? _value.activo
            : activo // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ClienteEntityImpl implements _ClienteEntity {
  const _$ClienteEntityImpl({
    this.id,
    required this.codigo,
    required this.nombre,
    required this.rncCedula,
    required this.telefono,
    required this.correo,
    required this.direccion,
    this.activo = true,
  });

  factory _$ClienteEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClienteEntityImplFromJson(json);

  @override
  final int? id;
  @override
  final String codigo;
  @override
  final String nombre;
  @override
  final String rncCedula;
  @override
  final String telefono;
  @override
  final String correo;
  @override
  final String direccion;
  @override
  @JsonKey()
  final bool activo;

  @override
  String toString() {
    return 'ClienteEntity(id: $id, codigo: $codigo, nombre: $nombre, rncCedula: $rncCedula, telefono: $telefono, correo: $correo, direccion: $direccion, activo: $activo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClienteEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.codigo, codigo) || other.codigo == codigo) &&
            (identical(other.nombre, nombre) || other.nombre == nombre) &&
            (identical(other.rncCedula, rncCedula) ||
                other.rncCedula == rncCedula) &&
            (identical(other.telefono, telefono) ||
                other.telefono == telefono) &&
            (identical(other.correo, correo) || other.correo == correo) &&
            (identical(other.direccion, direccion) ||
                other.direccion == direccion) &&
            (identical(other.activo, activo) || other.activo == activo));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    codigo,
    nombre,
    rncCedula,
    telefono,
    correo,
    direccion,
    activo,
  );

  /// Create a copy of ClienteEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClienteEntityImplCopyWith<_$ClienteEntityImpl> get copyWith =>
      __$$ClienteEntityImplCopyWithImpl<_$ClienteEntityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ClienteEntityImplToJson(this);
  }
}

abstract class _ClienteEntity implements ClienteEntity {
  const factory _ClienteEntity({
    final int? id,
    required final String codigo,
    required final String nombre,
    required final String rncCedula,
    required final String telefono,
    required final String correo,
    required final String direccion,
    final bool activo,
  }) = _$ClienteEntityImpl;

  factory _ClienteEntity.fromJson(Map<String, dynamic> json) =
      _$ClienteEntityImpl.fromJson;

  @override
  int? get id;
  @override
  String get codigo;
  @override
  String get nombre;
  @override
  String get rncCedula;
  @override
  String get telefono;
  @override
  String get correo;
  @override
  String get direccion;
  @override
  bool get activo;

  /// Create a copy of ClienteEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClienteEntityImplCopyWith<_$ClienteEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
