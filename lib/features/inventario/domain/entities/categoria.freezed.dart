// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'categoria.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Categoria _$CategoriaFromJson(Map<String, dynamic> json) {
  return _Categoria.fromJson(json);
}

/// @nodoc
mixin _$Categoria {
  int? get id => throw _privateConstructorUsedError;
  String get nombre => throw _privateConstructorUsedError;
  String? get descripcion => throw _privateConstructorUsedError;
  DateTime get creadoEn => throw _privateConstructorUsedError;
  DateTime? get actualizadoEn => throw _privateConstructorUsedError;

  /// Serializes this Categoria to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Categoria
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CategoriaCopyWith<Categoria> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CategoriaCopyWith<$Res> {
  factory $CategoriaCopyWith(Categoria value, $Res Function(Categoria) then) =
      _$CategoriaCopyWithImpl<$Res, Categoria>;
  @useResult
  $Res call({
    int? id,
    String nombre,
    String? descripcion,
    DateTime creadoEn,
    DateTime? actualizadoEn,
  });
}

/// @nodoc
class _$CategoriaCopyWithImpl<$Res, $Val extends Categoria>
    implements $CategoriaCopyWith<$Res> {
  _$CategoriaCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Categoria
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? nombre = null,
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
abstract class _$$CategoriaImplCopyWith<$Res>
    implements $CategoriaCopyWith<$Res> {
  factory _$$CategoriaImplCopyWith(
    _$CategoriaImpl value,
    $Res Function(_$CategoriaImpl) then,
  ) = __$$CategoriaImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int? id,
    String nombre,
    String? descripcion,
    DateTime creadoEn,
    DateTime? actualizadoEn,
  });
}

/// @nodoc
class __$$CategoriaImplCopyWithImpl<$Res>
    extends _$CategoriaCopyWithImpl<$Res, _$CategoriaImpl>
    implements _$$CategoriaImplCopyWith<$Res> {
  __$$CategoriaImplCopyWithImpl(
    _$CategoriaImpl _value,
    $Res Function(_$CategoriaImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Categoria
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? nombre = null,
    Object? descripcion = freezed,
    Object? creadoEn = null,
    Object? actualizadoEn = freezed,
  }) {
    return _then(
      _$CategoriaImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int?,
        nombre: null == nombre
            ? _value.nombre
            : nombre // ignore: cast_nullable_to_non_nullable
                  as String,
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
class _$CategoriaImpl implements _Categoria {
  const _$CategoriaImpl({
    this.id,
    required this.nombre,
    this.descripcion,
    required this.creadoEn,
    this.actualizadoEn,
  });

  factory _$CategoriaImpl.fromJson(Map<String, dynamic> json) =>
      _$$CategoriaImplFromJson(json);

  @override
  final int? id;
  @override
  final String nombre;
  @override
  final String? descripcion;
  @override
  final DateTime creadoEn;
  @override
  final DateTime? actualizadoEn;

  @override
  String toString() {
    return 'Categoria(id: $id, nombre: $nombre, descripcion: $descripcion, creadoEn: $creadoEn, actualizadoEn: $actualizadoEn)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CategoriaImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nombre, nombre) || other.nombre == nombre) &&
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
    descripcion,
    creadoEn,
    actualizadoEn,
  );

  /// Create a copy of Categoria
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CategoriaImplCopyWith<_$CategoriaImpl> get copyWith =>
      __$$CategoriaImplCopyWithImpl<_$CategoriaImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CategoriaImplToJson(this);
  }
}

abstract class _Categoria implements Categoria {
  const factory _Categoria({
    final int? id,
    required final String nombre,
    final String? descripcion,
    required final DateTime creadoEn,
    final DateTime? actualizadoEn,
  }) = _$CategoriaImpl;

  factory _Categoria.fromJson(Map<String, dynamic> json) =
      _$CategoriaImpl.fromJson;

  @override
  int? get id;
  @override
  String get nombre;
  @override
  String? get descripcion;
  @override
  DateTime get creadoEn;
  @override
  DateTime? get actualizadoEn;

  /// Create a copy of Categoria
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CategoriaImplCopyWith<_$CategoriaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
