// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kardex.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Kardex {
  int? get id => throw _privateConstructorUsedError;
  int get productoId => throw _privateConstructorUsedError;
  TipoMovimiento get tipoMovimiento => throw _privateConstructorUsedError;
  double get cantidad => throw _privateConstructorUsedError;
  double get saldoAnterior => throw _privateConstructorUsedError;
  double get saldoNuevo => throw _privateConstructorUsedError;
  double get costoUnitario => throw _privateConstructorUsedError;
  double get totalMovimiento => throw _privateConstructorUsedError;
  DateTime? get fechaMovimiento => throw _privateConstructorUsedError;
  String? get documentoReferencia => throw _privateConstructorUsedError;
  String? get observacion => throw _privateConstructorUsedError;
  int get usuarioId => throw _privateConstructorUsedError;

  /// Create a copy of Kardex
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $KardexCopyWith<Kardex> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $KardexCopyWith<$Res> {
  factory $KardexCopyWith(Kardex value, $Res Function(Kardex) then) =
      _$KardexCopyWithImpl<$Res, Kardex>;
  @useResult
  $Res call({
    int? id,
    int productoId,
    TipoMovimiento tipoMovimiento,
    double cantidad,
    double saldoAnterior,
    double saldoNuevo,
    double costoUnitario,
    double totalMovimiento,
    DateTime? fechaMovimiento,
    String? documentoReferencia,
    String? observacion,
    int usuarioId,
  });
}

/// @nodoc
class _$KardexCopyWithImpl<$Res, $Val extends Kardex>
    implements $KardexCopyWith<$Res> {
  _$KardexCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Kardex
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? productoId = null,
    Object? tipoMovimiento = null,
    Object? cantidad = null,
    Object? saldoAnterior = null,
    Object? saldoNuevo = null,
    Object? costoUnitario = null,
    Object? totalMovimiento = null,
    Object? fechaMovimiento = freezed,
    Object? documentoReferencia = freezed,
    Object? observacion = freezed,
    Object? usuarioId = null,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int?,
            productoId: null == productoId
                ? _value.productoId
                : productoId // ignore: cast_nullable_to_non_nullable
                      as int,
            tipoMovimiento: null == tipoMovimiento
                ? _value.tipoMovimiento
                : tipoMovimiento // ignore: cast_nullable_to_non_nullable
                      as TipoMovimiento,
            cantidad: null == cantidad
                ? _value.cantidad
                : cantidad // ignore: cast_nullable_to_non_nullable
                      as double,
            saldoAnterior: null == saldoAnterior
                ? _value.saldoAnterior
                : saldoAnterior // ignore: cast_nullable_to_non_nullable
                      as double,
            saldoNuevo: null == saldoNuevo
                ? _value.saldoNuevo
                : saldoNuevo // ignore: cast_nullable_to_non_nullable
                      as double,
            costoUnitario: null == costoUnitario
                ? _value.costoUnitario
                : costoUnitario // ignore: cast_nullable_to_non_nullable
                      as double,
            totalMovimiento: null == totalMovimiento
                ? _value.totalMovimiento
                : totalMovimiento // ignore: cast_nullable_to_non_nullable
                      as double,
            fechaMovimiento: freezed == fechaMovimiento
                ? _value.fechaMovimiento
                : fechaMovimiento // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            documentoReferencia: freezed == documentoReferencia
                ? _value.documentoReferencia
                : documentoReferencia // ignore: cast_nullable_to_non_nullable
                      as String?,
            observacion: freezed == observacion
                ? _value.observacion
                : observacion // ignore: cast_nullable_to_non_nullable
                      as String?,
            usuarioId: null == usuarioId
                ? _value.usuarioId
                : usuarioId // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$KardexImplCopyWith<$Res> implements $KardexCopyWith<$Res> {
  factory _$$KardexImplCopyWith(
    _$KardexImpl value,
    $Res Function(_$KardexImpl) then,
  ) = __$$KardexImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int? id,
    int productoId,
    TipoMovimiento tipoMovimiento,
    double cantidad,
    double saldoAnterior,
    double saldoNuevo,
    double costoUnitario,
    double totalMovimiento,
    DateTime? fechaMovimiento,
    String? documentoReferencia,
    String? observacion,
    int usuarioId,
  });
}

/// @nodoc
class __$$KardexImplCopyWithImpl<$Res>
    extends _$KardexCopyWithImpl<$Res, _$KardexImpl>
    implements _$$KardexImplCopyWith<$Res> {
  __$$KardexImplCopyWithImpl(
    _$KardexImpl _value,
    $Res Function(_$KardexImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Kardex
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? productoId = null,
    Object? tipoMovimiento = null,
    Object? cantidad = null,
    Object? saldoAnterior = null,
    Object? saldoNuevo = null,
    Object? costoUnitario = null,
    Object? totalMovimiento = null,
    Object? fechaMovimiento = freezed,
    Object? documentoReferencia = freezed,
    Object? observacion = freezed,
    Object? usuarioId = null,
  }) {
    return _then(
      _$KardexImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int?,
        productoId: null == productoId
            ? _value.productoId
            : productoId // ignore: cast_nullable_to_non_nullable
                  as int,
        tipoMovimiento: null == tipoMovimiento
            ? _value.tipoMovimiento
            : tipoMovimiento // ignore: cast_nullable_to_non_nullable
                  as TipoMovimiento,
        cantidad: null == cantidad
            ? _value.cantidad
            : cantidad // ignore: cast_nullable_to_non_nullable
                  as double,
        saldoAnterior: null == saldoAnterior
            ? _value.saldoAnterior
            : saldoAnterior // ignore: cast_nullable_to_non_nullable
                  as double,
        saldoNuevo: null == saldoNuevo
            ? _value.saldoNuevo
            : saldoNuevo // ignore: cast_nullable_to_non_nullable
                  as double,
        costoUnitario: null == costoUnitario
            ? _value.costoUnitario
            : costoUnitario // ignore: cast_nullable_to_non_nullable
                  as double,
        totalMovimiento: null == totalMovimiento
            ? _value.totalMovimiento
            : totalMovimiento // ignore: cast_nullable_to_non_nullable
                  as double,
        fechaMovimiento: freezed == fechaMovimiento
            ? _value.fechaMovimiento
            : fechaMovimiento // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        documentoReferencia: freezed == documentoReferencia
            ? _value.documentoReferencia
            : documentoReferencia // ignore: cast_nullable_to_non_nullable
                  as String?,
        observacion: freezed == observacion
            ? _value.observacion
            : observacion // ignore: cast_nullable_to_non_nullable
                  as String?,
        usuarioId: null == usuarioId
            ? _value.usuarioId
            : usuarioId // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$KardexImpl implements _Kardex {
  const _$KardexImpl({
    this.id,
    required this.productoId,
    required this.tipoMovimiento,
    required this.cantidad,
    required this.saldoAnterior,
    required this.saldoNuevo,
    required this.costoUnitario,
    required this.totalMovimiento,
    this.fechaMovimiento,
    this.documentoReferencia,
    this.observacion,
    required this.usuarioId,
  });

  @override
  final int? id;
  @override
  final int productoId;
  @override
  final TipoMovimiento tipoMovimiento;
  @override
  final double cantidad;
  @override
  final double saldoAnterior;
  @override
  final double saldoNuevo;
  @override
  final double costoUnitario;
  @override
  final double totalMovimiento;
  @override
  final DateTime? fechaMovimiento;
  @override
  final String? documentoReferencia;
  @override
  final String? observacion;
  @override
  final int usuarioId;

  @override
  String toString() {
    return 'Kardex(id: $id, productoId: $productoId, tipoMovimiento: $tipoMovimiento, cantidad: $cantidad, saldoAnterior: $saldoAnterior, saldoNuevo: $saldoNuevo, costoUnitario: $costoUnitario, totalMovimiento: $totalMovimiento, fechaMovimiento: $fechaMovimiento, documentoReferencia: $documentoReferencia, observacion: $observacion, usuarioId: $usuarioId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$KardexImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.productoId, productoId) ||
                other.productoId == productoId) &&
            (identical(other.tipoMovimiento, tipoMovimiento) ||
                other.tipoMovimiento == tipoMovimiento) &&
            (identical(other.cantidad, cantidad) ||
                other.cantidad == cantidad) &&
            (identical(other.saldoAnterior, saldoAnterior) ||
                other.saldoAnterior == saldoAnterior) &&
            (identical(other.saldoNuevo, saldoNuevo) ||
                other.saldoNuevo == saldoNuevo) &&
            (identical(other.costoUnitario, costoUnitario) ||
                other.costoUnitario == costoUnitario) &&
            (identical(other.totalMovimiento, totalMovimiento) ||
                other.totalMovimiento == totalMovimiento) &&
            (identical(other.fechaMovimiento, fechaMovimiento) ||
                other.fechaMovimiento == fechaMovimiento) &&
            (identical(other.documentoReferencia, documentoReferencia) ||
                other.documentoReferencia == documentoReferencia) &&
            (identical(other.observacion, observacion) ||
                other.observacion == observacion) &&
            (identical(other.usuarioId, usuarioId) ||
                other.usuarioId == usuarioId));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    productoId,
    tipoMovimiento,
    cantidad,
    saldoAnterior,
    saldoNuevo,
    costoUnitario,
    totalMovimiento,
    fechaMovimiento,
    documentoReferencia,
    observacion,
    usuarioId,
  );

  /// Create a copy of Kardex
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$KardexImplCopyWith<_$KardexImpl> get copyWith =>
      __$$KardexImplCopyWithImpl<_$KardexImpl>(this, _$identity);
}

abstract class _Kardex implements Kardex {
  const factory _Kardex({
    final int? id,
    required final int productoId,
    required final TipoMovimiento tipoMovimiento,
    required final double cantidad,
    required final double saldoAnterior,
    required final double saldoNuevo,
    required final double costoUnitario,
    required final double totalMovimiento,
    final DateTime? fechaMovimiento,
    final String? documentoReferencia,
    final String? observacion,
    required final int usuarioId,
  }) = _$KardexImpl;

  @override
  int? get id;
  @override
  int get productoId;
  @override
  TipoMovimiento get tipoMovimiento;
  @override
  double get cantidad;
  @override
  double get saldoAnterior;
  @override
  double get saldoNuevo;
  @override
  double get costoUnitario;
  @override
  double get totalMovimiento;
  @override
  DateTime? get fechaMovimiento;
  @override
  String? get documentoReferencia;
  @override
  String? get observacion;
  @override
  int get usuarioId;

  /// Create a copy of Kardex
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$KardexImplCopyWith<_$KardexImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
