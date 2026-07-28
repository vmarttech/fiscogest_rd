// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventario_fisico_database.dart';

// ignore_for_file: type=lint
class $ConteosFisicosTable extends ConteosFisicos
    with TableInfo<$ConteosFisicosTable, ConteosFisico> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConteosFisicosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nombreConteoMeta = const VerificationMeta(
    'nombreConteo',
  );
  @override
  late final GeneratedColumn<String> nombreConteo = GeneratedColumn<String>(
    'nombre_conteo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaConteoMeta = const VerificationMeta(
    'fechaConteo',
  );
  @override
  late final GeneratedColumn<DateTime> fechaConteo = GeneratedColumn<DateTime>(
    'fecha_conteo',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _observacionesMeta = const VerificationMeta(
    'observaciones',
  );
  @override
  late final GeneratedColumn<String> observaciones = GeneratedColumn<String>(
    'observaciones',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usuarioIdMeta = const VerificationMeta(
    'usuarioId',
  );
  @override
  late final GeneratedColumn<int> usuarioId = GeneratedColumn<int>(
    'usuario_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaCreacionMeta = const VerificationMeta(
    'fechaCreacion',
  );
  @override
  late final GeneratedColumn<DateTime> fechaCreacion =
      GeneratedColumn<DateTime>(
        'fecha_creacion',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _estadoMeta = const VerificationMeta('estado');
  @override
  late final GeneratedColumn<String> estado = GeneratedColumn<String>(
    'estado',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pendiente'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nombreConteo,
    fechaConteo,
    observaciones,
    usuarioId,
    fechaCreacion,
    estado,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conteos_fisicos';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConteosFisico> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nombre_conteo')) {
      context.handle(
        _nombreConteoMeta,
        nombreConteo.isAcceptableOrUnknown(
          data['nombre_conteo']!,
          _nombreConteoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nombreConteoMeta);
    }
    if (data.containsKey('fecha_conteo')) {
      context.handle(
        _fechaConteoMeta,
        fechaConteo.isAcceptableOrUnknown(
          data['fecha_conteo']!,
          _fechaConteoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fechaConteoMeta);
    }
    if (data.containsKey('observaciones')) {
      context.handle(
        _observacionesMeta,
        observaciones.isAcceptableOrUnknown(
          data['observaciones']!,
          _observacionesMeta,
        ),
      );
    }
    if (data.containsKey('usuario_id')) {
      context.handle(
        _usuarioIdMeta,
        usuarioId.isAcceptableOrUnknown(data['usuario_id']!, _usuarioIdMeta),
      );
    } else if (isInserting) {
      context.missing(_usuarioIdMeta);
    }
    if (data.containsKey('fecha_creacion')) {
      context.handle(
        _fechaCreacionMeta,
        fechaCreacion.isAcceptableOrUnknown(
          data['fecha_creacion']!,
          _fechaCreacionMeta,
        ),
      );
    }
    if (data.containsKey('estado')) {
      context.handle(
        _estadoMeta,
        estado.isAcceptableOrUnknown(data['estado']!, _estadoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConteosFisico map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConteosFisico(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nombreConteo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre_conteo'],
      )!,
      fechaConteo: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_conteo'],
      )!,
      observaciones: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observaciones'],
      ),
      usuarioId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}usuario_id'],
      )!,
      fechaCreacion: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_creacion'],
      )!,
      estado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estado'],
      )!,
    );
  }

  @override
  $ConteosFisicosTable createAlias(String alias) {
    return $ConteosFisicosTable(attachedDatabase, alias);
  }
}

class ConteosFisico extends DataClass implements Insertable<ConteosFisico> {
  final int id;
  final String nombreConteo;
  final DateTime fechaConteo;
  final String? observaciones;
  final int usuarioId;
  final DateTime fechaCreacion;
  final String estado;
  const ConteosFisico({
    required this.id,
    required this.nombreConteo,
    required this.fechaConteo,
    this.observaciones,
    required this.usuarioId,
    required this.fechaCreacion,
    required this.estado,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nombre_conteo'] = Variable<String>(nombreConteo);
    map['fecha_conteo'] = Variable<DateTime>(fechaConteo);
    if (!nullToAbsent || observaciones != null) {
      map['observaciones'] = Variable<String>(observaciones);
    }
    map['usuario_id'] = Variable<int>(usuarioId);
    map['fecha_creacion'] = Variable<DateTime>(fechaCreacion);
    map['estado'] = Variable<String>(estado);
    return map;
  }

  ConteosFisicosCompanion toCompanion(bool nullToAbsent) {
    return ConteosFisicosCompanion(
      id: Value(id),
      nombreConteo: Value(nombreConteo),
      fechaConteo: Value(fechaConteo),
      observaciones: observaciones == null && nullToAbsent
          ? const Value.absent()
          : Value(observaciones),
      usuarioId: Value(usuarioId),
      fechaCreacion: Value(fechaCreacion),
      estado: Value(estado),
    );
  }

  factory ConteosFisico.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConteosFisico(
      id: serializer.fromJson<int>(json['id']),
      nombreConteo: serializer.fromJson<String>(json['nombreConteo']),
      fechaConteo: serializer.fromJson<DateTime>(json['fechaConteo']),
      observaciones: serializer.fromJson<String?>(json['observaciones']),
      usuarioId: serializer.fromJson<int>(json['usuarioId']),
      fechaCreacion: serializer.fromJson<DateTime>(json['fechaCreacion']),
      estado: serializer.fromJson<String>(json['estado']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nombreConteo': serializer.toJson<String>(nombreConteo),
      'fechaConteo': serializer.toJson<DateTime>(fechaConteo),
      'observaciones': serializer.toJson<String?>(observaciones),
      'usuarioId': serializer.toJson<int>(usuarioId),
      'fechaCreacion': serializer.toJson<DateTime>(fechaCreacion),
      'estado': serializer.toJson<String>(estado),
    };
  }

  ConteosFisico copyWith({
    int? id,
    String? nombreConteo,
    DateTime? fechaConteo,
    Value<String?> observaciones = const Value.absent(),
    int? usuarioId,
    DateTime? fechaCreacion,
    String? estado,
  }) => ConteosFisico(
    id: id ?? this.id,
    nombreConteo: nombreConteo ?? this.nombreConteo,
    fechaConteo: fechaConteo ?? this.fechaConteo,
    observaciones: observaciones.present
        ? observaciones.value
        : this.observaciones,
    usuarioId: usuarioId ?? this.usuarioId,
    fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    estado: estado ?? this.estado,
  );
  ConteosFisico copyWithCompanion(ConteosFisicosCompanion data) {
    return ConteosFisico(
      id: data.id.present ? data.id.value : this.id,
      nombreConteo: data.nombreConteo.present
          ? data.nombreConteo.value
          : this.nombreConteo,
      fechaConteo: data.fechaConteo.present
          ? data.fechaConteo.value
          : this.fechaConteo,
      observaciones: data.observaciones.present
          ? data.observaciones.value
          : this.observaciones,
      usuarioId: data.usuarioId.present ? data.usuarioId.value : this.usuarioId,
      fechaCreacion: data.fechaCreacion.present
          ? data.fechaCreacion.value
          : this.fechaCreacion,
      estado: data.estado.present ? data.estado.value : this.estado,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConteosFisico(')
          ..write('id: $id, ')
          ..write('nombreConteo: $nombreConteo, ')
          ..write('fechaConteo: $fechaConteo, ')
          ..write('observaciones: $observaciones, ')
          ..write('usuarioId: $usuarioId, ')
          ..write('fechaCreacion: $fechaCreacion, ')
          ..write('estado: $estado')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nombreConteo,
    fechaConteo,
    observaciones,
    usuarioId,
    fechaCreacion,
    estado,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConteosFisico &&
          other.id == this.id &&
          other.nombreConteo == this.nombreConteo &&
          other.fechaConteo == this.fechaConteo &&
          other.observaciones == this.observaciones &&
          other.usuarioId == this.usuarioId &&
          other.fechaCreacion == this.fechaCreacion &&
          other.estado == this.estado);
}

class ConteosFisicosCompanion extends UpdateCompanion<ConteosFisico> {
  final Value<int> id;
  final Value<String> nombreConteo;
  final Value<DateTime> fechaConteo;
  final Value<String?> observaciones;
  final Value<int> usuarioId;
  final Value<DateTime> fechaCreacion;
  final Value<String> estado;
  const ConteosFisicosCompanion({
    this.id = const Value.absent(),
    this.nombreConteo = const Value.absent(),
    this.fechaConteo = const Value.absent(),
    this.observaciones = const Value.absent(),
    this.usuarioId = const Value.absent(),
    this.fechaCreacion = const Value.absent(),
    this.estado = const Value.absent(),
  });
  ConteosFisicosCompanion.insert({
    this.id = const Value.absent(),
    required String nombreConteo,
    required DateTime fechaConteo,
    this.observaciones = const Value.absent(),
    required int usuarioId,
    this.fechaCreacion = const Value.absent(),
    this.estado = const Value.absent(),
  }) : nombreConteo = Value(nombreConteo),
       fechaConteo = Value(fechaConteo),
       usuarioId = Value(usuarioId);
  static Insertable<ConteosFisico> custom({
    Expression<int>? id,
    Expression<String>? nombreConteo,
    Expression<DateTime>? fechaConteo,
    Expression<String>? observaciones,
    Expression<int>? usuarioId,
    Expression<DateTime>? fechaCreacion,
    Expression<String>? estado,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombreConteo != null) 'nombre_conteo': nombreConteo,
      if (fechaConteo != null) 'fecha_conteo': fechaConteo,
      if (observaciones != null) 'observaciones': observaciones,
      if (usuarioId != null) 'usuario_id': usuarioId,
      if (fechaCreacion != null) 'fecha_creacion': fechaCreacion,
      if (estado != null) 'estado': estado,
    });
  }

  ConteosFisicosCompanion copyWith({
    Value<int>? id,
    Value<String>? nombreConteo,
    Value<DateTime>? fechaConteo,
    Value<String?>? observaciones,
    Value<int>? usuarioId,
    Value<DateTime>? fechaCreacion,
    Value<String>? estado,
  }) {
    return ConteosFisicosCompanion(
      id: id ?? this.id,
      nombreConteo: nombreConteo ?? this.nombreConteo,
      fechaConteo: fechaConteo ?? this.fechaConteo,
      observaciones: observaciones ?? this.observaciones,
      usuarioId: usuarioId ?? this.usuarioId,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      estado: estado ?? this.estado,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nombreConteo.present) {
      map['nombre_conteo'] = Variable<String>(nombreConteo.value);
    }
    if (fechaConteo.present) {
      map['fecha_conteo'] = Variable<DateTime>(fechaConteo.value);
    }
    if (observaciones.present) {
      map['observaciones'] = Variable<String>(observaciones.value);
    }
    if (usuarioId.present) {
      map['usuario_id'] = Variable<int>(usuarioId.value);
    }
    if (fechaCreacion.present) {
      map['fecha_creacion'] = Variable<DateTime>(fechaCreacion.value);
    }
    if (estado.present) {
      map['estado'] = Variable<String>(estado.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConteosFisicosCompanion(')
          ..write('id: $id, ')
          ..write('nombreConteo: $nombreConteo, ')
          ..write('fechaConteo: $fechaConteo, ')
          ..write('observaciones: $observaciones, ')
          ..write('usuarioId: $usuarioId, ')
          ..write('fechaCreacion: $fechaCreacion, ')
          ..write('estado: $estado')
          ..write(')'))
        .toString();
  }
}

class $DiferenciasConteoTable extends DiferenciasConteo
    with TableInfo<$DiferenciasConteoTable, DiferenciasConteoData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiferenciasConteoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _conteoIdMeta = const VerificationMeta(
    'conteoId',
  );
  @override
  late final GeneratedColumn<int> conteoId = GeneratedColumn<int>(
    'conteo_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productoIdMeta = const VerificationMeta(
    'productoId',
  );
  @override
  late final GeneratedColumn<int> productoId = GeneratedColumn<int>(
    'producto_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codigoProductoMeta = const VerificationMeta(
    'codigoProducto',
  );
  @override
  late final GeneratedColumn<String> codigoProducto = GeneratedColumn<String>(
    'codigo_producto',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreProductoMeta = const VerificationMeta(
    'nombreProducto',
  );
  @override
  late final GeneratedColumn<String> nombreProducto = GeneratedColumn<String>(
    'nombre_producto',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stockSistemaMeta = const VerificationMeta(
    'stockSistema',
  );
  @override
  late final GeneratedColumn<double> stockSistema = GeneratedColumn<double>(
    'stock_sistema',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stockFisicoMeta = const VerificationMeta(
    'stockFisico',
  );
  @override
  late final GeneratedColumn<double> stockFisico = GeneratedColumn<double>(
    'stock_fisico',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _diferenciaMeta = const VerificationMeta(
    'diferencia',
  );
  @override
  late final GeneratedColumn<double> diferencia = GeneratedColumn<double>(
    'diferencia',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _motivoMeta = const VerificationMeta('motivo');
  @override
  late final GeneratedColumn<String> motivo = GeneratedColumn<String>(
    'motivo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estadoMeta = const VerificationMeta('estado');
  @override
  late final GeneratedColumn<String> estado = GeneratedColumn<String>(
    'estado',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pendiente'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    conteoId,
    productoId,
    codigoProducto,
    nombreProducto,
    stockSistema,
    stockFisico,
    diferencia,
    motivo,
    estado,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'diferencias_conteo';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiferenciasConteoData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('conteo_id')) {
      context.handle(
        _conteoIdMeta,
        conteoId.isAcceptableOrUnknown(data['conteo_id']!, _conteoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_conteoIdMeta);
    }
    if (data.containsKey('producto_id')) {
      context.handle(
        _productoIdMeta,
        productoId.isAcceptableOrUnknown(data['producto_id']!, _productoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productoIdMeta);
    }
    if (data.containsKey('codigo_producto')) {
      context.handle(
        _codigoProductoMeta,
        codigoProducto.isAcceptableOrUnknown(
          data['codigo_producto']!,
          _codigoProductoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_codigoProductoMeta);
    }
    if (data.containsKey('nombre_producto')) {
      context.handle(
        _nombreProductoMeta,
        nombreProducto.isAcceptableOrUnknown(
          data['nombre_producto']!,
          _nombreProductoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nombreProductoMeta);
    }
    if (data.containsKey('stock_sistema')) {
      context.handle(
        _stockSistemaMeta,
        stockSistema.isAcceptableOrUnknown(
          data['stock_sistema']!,
          _stockSistemaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stockSistemaMeta);
    }
    if (data.containsKey('stock_fisico')) {
      context.handle(
        _stockFisicoMeta,
        stockFisico.isAcceptableOrUnknown(
          data['stock_fisico']!,
          _stockFisicoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stockFisicoMeta);
    }
    if (data.containsKey('diferencia')) {
      context.handle(
        _diferenciaMeta,
        diferencia.isAcceptableOrUnknown(data['diferencia']!, _diferenciaMeta),
      );
    } else if (isInserting) {
      context.missing(_diferenciaMeta);
    }
    if (data.containsKey('motivo')) {
      context.handle(
        _motivoMeta,
        motivo.isAcceptableOrUnknown(data['motivo']!, _motivoMeta),
      );
    }
    if (data.containsKey('estado')) {
      context.handle(
        _estadoMeta,
        estado.isAcceptableOrUnknown(data['estado']!, _estadoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiferenciasConteoData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiferenciasConteoData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      conteoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}conteo_id'],
      )!,
      productoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}producto_id'],
      )!,
      codigoProducto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo_producto'],
      )!,
      nombreProducto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre_producto'],
      )!,
      stockSistema: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stock_sistema'],
      )!,
      stockFisico: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stock_fisico'],
      )!,
      diferencia: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}diferencia'],
      )!,
      motivo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}motivo'],
      ),
      estado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estado'],
      )!,
    );
  }

  @override
  $DiferenciasConteoTable createAlias(String alias) {
    return $DiferenciasConteoTable(attachedDatabase, alias);
  }
}

class DiferenciasConteoData extends DataClass
    implements Insertable<DiferenciasConteoData> {
  final int id;
  final int conteoId;
  final int productoId;
  final String codigoProducto;
  final String nombreProducto;
  final double stockSistema;
  final double stockFisico;
  final double diferencia;
  final String? motivo;
  final String estado;
  const DiferenciasConteoData({
    required this.id,
    required this.conteoId,
    required this.productoId,
    required this.codigoProducto,
    required this.nombreProducto,
    required this.stockSistema,
    required this.stockFisico,
    required this.diferencia,
    this.motivo,
    required this.estado,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['conteo_id'] = Variable<int>(conteoId);
    map['producto_id'] = Variable<int>(productoId);
    map['codigo_producto'] = Variable<String>(codigoProducto);
    map['nombre_producto'] = Variable<String>(nombreProducto);
    map['stock_sistema'] = Variable<double>(stockSistema);
    map['stock_fisico'] = Variable<double>(stockFisico);
    map['diferencia'] = Variable<double>(diferencia);
    if (!nullToAbsent || motivo != null) {
      map['motivo'] = Variable<String>(motivo);
    }
    map['estado'] = Variable<String>(estado);
    return map;
  }

  DiferenciasConteoCompanion toCompanion(bool nullToAbsent) {
    return DiferenciasConteoCompanion(
      id: Value(id),
      conteoId: Value(conteoId),
      productoId: Value(productoId),
      codigoProducto: Value(codigoProducto),
      nombreProducto: Value(nombreProducto),
      stockSistema: Value(stockSistema),
      stockFisico: Value(stockFisico),
      diferencia: Value(diferencia),
      motivo: motivo == null && nullToAbsent
          ? const Value.absent()
          : Value(motivo),
      estado: Value(estado),
    );
  }

  factory DiferenciasConteoData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiferenciasConteoData(
      id: serializer.fromJson<int>(json['id']),
      conteoId: serializer.fromJson<int>(json['conteoId']),
      productoId: serializer.fromJson<int>(json['productoId']),
      codigoProducto: serializer.fromJson<String>(json['codigoProducto']),
      nombreProducto: serializer.fromJson<String>(json['nombreProducto']),
      stockSistema: serializer.fromJson<double>(json['stockSistema']),
      stockFisico: serializer.fromJson<double>(json['stockFisico']),
      diferencia: serializer.fromJson<double>(json['diferencia']),
      motivo: serializer.fromJson<String?>(json['motivo']),
      estado: serializer.fromJson<String>(json['estado']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'conteoId': serializer.toJson<int>(conteoId),
      'productoId': serializer.toJson<int>(productoId),
      'codigoProducto': serializer.toJson<String>(codigoProducto),
      'nombreProducto': serializer.toJson<String>(nombreProducto),
      'stockSistema': serializer.toJson<double>(stockSistema),
      'stockFisico': serializer.toJson<double>(stockFisico),
      'diferencia': serializer.toJson<double>(diferencia),
      'motivo': serializer.toJson<String?>(motivo),
      'estado': serializer.toJson<String>(estado),
    };
  }

  DiferenciasConteoData copyWith({
    int? id,
    int? conteoId,
    int? productoId,
    String? codigoProducto,
    String? nombreProducto,
    double? stockSistema,
    double? stockFisico,
    double? diferencia,
    Value<String?> motivo = const Value.absent(),
    String? estado,
  }) => DiferenciasConteoData(
    id: id ?? this.id,
    conteoId: conteoId ?? this.conteoId,
    productoId: productoId ?? this.productoId,
    codigoProducto: codigoProducto ?? this.codigoProducto,
    nombreProducto: nombreProducto ?? this.nombreProducto,
    stockSistema: stockSistema ?? this.stockSistema,
    stockFisico: stockFisico ?? this.stockFisico,
    diferencia: diferencia ?? this.diferencia,
    motivo: motivo.present ? motivo.value : this.motivo,
    estado: estado ?? this.estado,
  );
  DiferenciasConteoData copyWithCompanion(DiferenciasConteoCompanion data) {
    return DiferenciasConteoData(
      id: data.id.present ? data.id.value : this.id,
      conteoId: data.conteoId.present ? data.conteoId.value : this.conteoId,
      productoId: data.productoId.present
          ? data.productoId.value
          : this.productoId,
      codigoProducto: data.codigoProducto.present
          ? data.codigoProducto.value
          : this.codigoProducto,
      nombreProducto: data.nombreProducto.present
          ? data.nombreProducto.value
          : this.nombreProducto,
      stockSistema: data.stockSistema.present
          ? data.stockSistema.value
          : this.stockSistema,
      stockFisico: data.stockFisico.present
          ? data.stockFisico.value
          : this.stockFisico,
      diferencia: data.diferencia.present
          ? data.diferencia.value
          : this.diferencia,
      motivo: data.motivo.present ? data.motivo.value : this.motivo,
      estado: data.estado.present ? data.estado.value : this.estado,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiferenciasConteoData(')
          ..write('id: $id, ')
          ..write('conteoId: $conteoId, ')
          ..write('productoId: $productoId, ')
          ..write('codigoProducto: $codigoProducto, ')
          ..write('nombreProducto: $nombreProducto, ')
          ..write('stockSistema: $stockSistema, ')
          ..write('stockFisico: $stockFisico, ')
          ..write('diferencia: $diferencia, ')
          ..write('motivo: $motivo, ')
          ..write('estado: $estado')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    conteoId,
    productoId,
    codigoProducto,
    nombreProducto,
    stockSistema,
    stockFisico,
    diferencia,
    motivo,
    estado,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiferenciasConteoData &&
          other.id == this.id &&
          other.conteoId == this.conteoId &&
          other.productoId == this.productoId &&
          other.codigoProducto == this.codigoProducto &&
          other.nombreProducto == this.nombreProducto &&
          other.stockSistema == this.stockSistema &&
          other.stockFisico == this.stockFisico &&
          other.diferencia == this.diferencia &&
          other.motivo == this.motivo &&
          other.estado == this.estado);
}

class DiferenciasConteoCompanion
    extends UpdateCompanion<DiferenciasConteoData> {
  final Value<int> id;
  final Value<int> conteoId;
  final Value<int> productoId;
  final Value<String> codigoProducto;
  final Value<String> nombreProducto;
  final Value<double> stockSistema;
  final Value<double> stockFisico;
  final Value<double> diferencia;
  final Value<String?> motivo;
  final Value<String> estado;
  const DiferenciasConteoCompanion({
    this.id = const Value.absent(),
    this.conteoId = const Value.absent(),
    this.productoId = const Value.absent(),
    this.codigoProducto = const Value.absent(),
    this.nombreProducto = const Value.absent(),
    this.stockSistema = const Value.absent(),
    this.stockFisico = const Value.absent(),
    this.diferencia = const Value.absent(),
    this.motivo = const Value.absent(),
    this.estado = const Value.absent(),
  });
  DiferenciasConteoCompanion.insert({
    this.id = const Value.absent(),
    required int conteoId,
    required int productoId,
    required String codigoProducto,
    required String nombreProducto,
    required double stockSistema,
    required double stockFisico,
    required double diferencia,
    this.motivo = const Value.absent(),
    this.estado = const Value.absent(),
  }) : conteoId = Value(conteoId),
       productoId = Value(productoId),
       codigoProducto = Value(codigoProducto),
       nombreProducto = Value(nombreProducto),
       stockSistema = Value(stockSistema),
       stockFisico = Value(stockFisico),
       diferencia = Value(diferencia);
  static Insertable<DiferenciasConteoData> custom({
    Expression<int>? id,
    Expression<int>? conteoId,
    Expression<int>? productoId,
    Expression<String>? codigoProducto,
    Expression<String>? nombreProducto,
    Expression<double>? stockSistema,
    Expression<double>? stockFisico,
    Expression<double>? diferencia,
    Expression<String>? motivo,
    Expression<String>? estado,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conteoId != null) 'conteo_id': conteoId,
      if (productoId != null) 'producto_id': productoId,
      if (codigoProducto != null) 'codigo_producto': codigoProducto,
      if (nombreProducto != null) 'nombre_producto': nombreProducto,
      if (stockSistema != null) 'stock_sistema': stockSistema,
      if (stockFisico != null) 'stock_fisico': stockFisico,
      if (diferencia != null) 'diferencia': diferencia,
      if (motivo != null) 'motivo': motivo,
      if (estado != null) 'estado': estado,
    });
  }

  DiferenciasConteoCompanion copyWith({
    Value<int>? id,
    Value<int>? conteoId,
    Value<int>? productoId,
    Value<String>? codigoProducto,
    Value<String>? nombreProducto,
    Value<double>? stockSistema,
    Value<double>? stockFisico,
    Value<double>? diferencia,
    Value<String?>? motivo,
    Value<String>? estado,
  }) {
    return DiferenciasConteoCompanion(
      id: id ?? this.id,
      conteoId: conteoId ?? this.conteoId,
      productoId: productoId ?? this.productoId,
      codigoProducto: codigoProducto ?? this.codigoProducto,
      nombreProducto: nombreProducto ?? this.nombreProducto,
      stockSistema: stockSistema ?? this.stockSistema,
      stockFisico: stockFisico ?? this.stockFisico,
      diferencia: diferencia ?? this.diferencia,
      motivo: motivo ?? this.motivo,
      estado: estado ?? this.estado,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (conteoId.present) {
      map['conteo_id'] = Variable<int>(conteoId.value);
    }
    if (productoId.present) {
      map['producto_id'] = Variable<int>(productoId.value);
    }
    if (codigoProducto.present) {
      map['codigo_producto'] = Variable<String>(codigoProducto.value);
    }
    if (nombreProducto.present) {
      map['nombre_producto'] = Variable<String>(nombreProducto.value);
    }
    if (stockSistema.present) {
      map['stock_sistema'] = Variable<double>(stockSistema.value);
    }
    if (stockFisico.present) {
      map['stock_fisico'] = Variable<double>(stockFisico.value);
    }
    if (diferencia.present) {
      map['diferencia'] = Variable<double>(diferencia.value);
    }
    if (motivo.present) {
      map['motivo'] = Variable<String>(motivo.value);
    }
    if (estado.present) {
      map['estado'] = Variable<String>(estado.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiferenciasConteoCompanion(')
          ..write('id: $id, ')
          ..write('conteoId: $conteoId, ')
          ..write('productoId: $productoId, ')
          ..write('codigoProducto: $codigoProducto, ')
          ..write('nombreProducto: $nombreProducto, ')
          ..write('stockSistema: $stockSistema, ')
          ..write('stockFisico: $stockFisico, ')
          ..write('diferencia: $diferencia, ')
          ..write('motivo: $motivo, ')
          ..write('estado: $estado')
          ..write(')'))
        .toString();
  }
}

abstract class _$InventarioFisicoDatabase extends GeneratedDatabase {
  _$InventarioFisicoDatabase(QueryExecutor e) : super(e);
  $InventarioFisicoDatabaseManager get managers =>
      $InventarioFisicoDatabaseManager(this);
  late final $ConteosFisicosTable conteosFisicos = $ConteosFisicosTable(this);
  late final $DiferenciasConteoTable diferenciasConteo =
      $DiferenciasConteoTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    conteosFisicos,
    diferenciasConteo,
  ];
}

typedef $$ConteosFisicosTableCreateCompanionBuilder =
    ConteosFisicosCompanion Function({
      Value<int> id,
      required String nombreConteo,
      required DateTime fechaConteo,
      Value<String?> observaciones,
      required int usuarioId,
      Value<DateTime> fechaCreacion,
      Value<String> estado,
    });
typedef $$ConteosFisicosTableUpdateCompanionBuilder =
    ConteosFisicosCompanion Function({
      Value<int> id,
      Value<String> nombreConteo,
      Value<DateTime> fechaConteo,
      Value<String?> observaciones,
      Value<int> usuarioId,
      Value<DateTime> fechaCreacion,
      Value<String> estado,
    });

class $$ConteosFisicosTableFilterComposer
    extends Composer<_$InventarioFisicoDatabase, $ConteosFisicosTable> {
  $$ConteosFisicosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombreConteo => $composableBuilder(
    column: $table.nombreConteo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaConteo => $composableBuilder(
    column: $table.fechaConteo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observaciones => $composableBuilder(
    column: $table.observaciones,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get usuarioId => $composableBuilder(
    column: $table.usuarioId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaCreacion => $composableBuilder(
    column: $table.fechaCreacion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConteosFisicosTableOrderingComposer
    extends Composer<_$InventarioFisicoDatabase, $ConteosFisicosTable> {
  $$ConteosFisicosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombreConteo => $composableBuilder(
    column: $table.nombreConteo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaConteo => $composableBuilder(
    column: $table.fechaConteo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observaciones => $composableBuilder(
    column: $table.observaciones,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get usuarioId => $composableBuilder(
    column: $table.usuarioId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaCreacion => $composableBuilder(
    column: $table.fechaCreacion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConteosFisicosTableAnnotationComposer
    extends Composer<_$InventarioFisicoDatabase, $ConteosFisicosTable> {
  $$ConteosFisicosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombreConteo => $composableBuilder(
    column: $table.nombreConteo,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaConteo => $composableBuilder(
    column: $table.fechaConteo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get observaciones => $composableBuilder(
    column: $table.observaciones,
    builder: (column) => column,
  );

  GeneratedColumn<int> get usuarioId =>
      $composableBuilder(column: $table.usuarioId, builder: (column) => column);

  GeneratedColumn<DateTime> get fechaCreacion => $composableBuilder(
    column: $table.fechaCreacion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => column);
}

class $$ConteosFisicosTableTableManager
    extends
        RootTableManager<
          _$InventarioFisicoDatabase,
          $ConteosFisicosTable,
          ConteosFisico,
          $$ConteosFisicosTableFilterComposer,
          $$ConteosFisicosTableOrderingComposer,
          $$ConteosFisicosTableAnnotationComposer,
          $$ConteosFisicosTableCreateCompanionBuilder,
          $$ConteosFisicosTableUpdateCompanionBuilder,
          (
            ConteosFisico,
            BaseReferences<
              _$InventarioFisicoDatabase,
              $ConteosFisicosTable,
              ConteosFisico
            >,
          ),
          ConteosFisico,
          PrefetchHooks Function()
        > {
  $$ConteosFisicosTableTableManager(
    _$InventarioFisicoDatabase db,
    $ConteosFisicosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConteosFisicosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConteosFisicosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConteosFisicosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nombreConteo = const Value.absent(),
                Value<DateTime> fechaConteo = const Value.absent(),
                Value<String?> observaciones = const Value.absent(),
                Value<int> usuarioId = const Value.absent(),
                Value<DateTime> fechaCreacion = const Value.absent(),
                Value<String> estado = const Value.absent(),
              }) => ConteosFisicosCompanion(
                id: id,
                nombreConteo: nombreConteo,
                fechaConteo: fechaConteo,
                observaciones: observaciones,
                usuarioId: usuarioId,
                fechaCreacion: fechaCreacion,
                estado: estado,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nombreConteo,
                required DateTime fechaConteo,
                Value<String?> observaciones = const Value.absent(),
                required int usuarioId,
                Value<DateTime> fechaCreacion = const Value.absent(),
                Value<String> estado = const Value.absent(),
              }) => ConteosFisicosCompanion.insert(
                id: id,
                nombreConteo: nombreConteo,
                fechaConteo: fechaConteo,
                observaciones: observaciones,
                usuarioId: usuarioId,
                fechaCreacion: fechaCreacion,
                estado: estado,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConteosFisicosTableProcessedTableManager =
    ProcessedTableManager<
      _$InventarioFisicoDatabase,
      $ConteosFisicosTable,
      ConteosFisico,
      $$ConteosFisicosTableFilterComposer,
      $$ConteosFisicosTableOrderingComposer,
      $$ConteosFisicosTableAnnotationComposer,
      $$ConteosFisicosTableCreateCompanionBuilder,
      $$ConteosFisicosTableUpdateCompanionBuilder,
      (
        ConteosFisico,
        BaseReferences<
          _$InventarioFisicoDatabase,
          $ConteosFisicosTable,
          ConteosFisico
        >,
      ),
      ConteosFisico,
      PrefetchHooks Function()
    >;
typedef $$DiferenciasConteoTableCreateCompanionBuilder =
    DiferenciasConteoCompanion Function({
      Value<int> id,
      required int conteoId,
      required int productoId,
      required String codigoProducto,
      required String nombreProducto,
      required double stockSistema,
      required double stockFisico,
      required double diferencia,
      Value<String?> motivo,
      Value<String> estado,
    });
typedef $$DiferenciasConteoTableUpdateCompanionBuilder =
    DiferenciasConteoCompanion Function({
      Value<int> id,
      Value<int> conteoId,
      Value<int> productoId,
      Value<String> codigoProducto,
      Value<String> nombreProducto,
      Value<double> stockSistema,
      Value<double> stockFisico,
      Value<double> diferencia,
      Value<String?> motivo,
      Value<String> estado,
    });

class $$DiferenciasConteoTableFilterComposer
    extends Composer<_$InventarioFisicoDatabase, $DiferenciasConteoTable> {
  $$DiferenciasConteoTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get conteoId => $composableBuilder(
    column: $table.conteoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get productoId => $composableBuilder(
    column: $table.productoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codigoProducto => $composableBuilder(
    column: $table.codigoProducto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombreProducto => $composableBuilder(
    column: $table.nombreProducto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stockSistema => $composableBuilder(
    column: $table.stockSistema,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stockFisico => $composableBuilder(
    column: $table.stockFisico,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get diferencia => $composableBuilder(
    column: $table.diferencia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get motivo => $composableBuilder(
    column: $table.motivo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DiferenciasConteoTableOrderingComposer
    extends Composer<_$InventarioFisicoDatabase, $DiferenciasConteoTable> {
  $$DiferenciasConteoTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get conteoId => $composableBuilder(
    column: $table.conteoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get productoId => $composableBuilder(
    column: $table.productoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codigoProducto => $composableBuilder(
    column: $table.codigoProducto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombreProducto => $composableBuilder(
    column: $table.nombreProducto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stockSistema => $composableBuilder(
    column: $table.stockSistema,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stockFisico => $composableBuilder(
    column: $table.stockFisico,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get diferencia => $composableBuilder(
    column: $table.diferencia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motivo => $composableBuilder(
    column: $table.motivo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DiferenciasConteoTableAnnotationComposer
    extends Composer<_$InventarioFisicoDatabase, $DiferenciasConteoTable> {
  $$DiferenciasConteoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get conteoId =>
      $composableBuilder(column: $table.conteoId, builder: (column) => column);

  GeneratedColumn<int> get productoId => $composableBuilder(
    column: $table.productoId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get codigoProducto => $composableBuilder(
    column: $table.codigoProducto,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nombreProducto => $composableBuilder(
    column: $table.nombreProducto,
    builder: (column) => column,
  );

  GeneratedColumn<double> get stockSistema => $composableBuilder(
    column: $table.stockSistema,
    builder: (column) => column,
  );

  GeneratedColumn<double> get stockFisico => $composableBuilder(
    column: $table.stockFisico,
    builder: (column) => column,
  );

  GeneratedColumn<double> get diferencia => $composableBuilder(
    column: $table.diferencia,
    builder: (column) => column,
  );

  GeneratedColumn<String> get motivo =>
      $composableBuilder(column: $table.motivo, builder: (column) => column);

  GeneratedColumn<String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => column);
}

class $$DiferenciasConteoTableTableManager
    extends
        RootTableManager<
          _$InventarioFisicoDatabase,
          $DiferenciasConteoTable,
          DiferenciasConteoData,
          $$DiferenciasConteoTableFilterComposer,
          $$DiferenciasConteoTableOrderingComposer,
          $$DiferenciasConteoTableAnnotationComposer,
          $$DiferenciasConteoTableCreateCompanionBuilder,
          $$DiferenciasConteoTableUpdateCompanionBuilder,
          (
            DiferenciasConteoData,
            BaseReferences<
              _$InventarioFisicoDatabase,
              $DiferenciasConteoTable,
              DiferenciasConteoData
            >,
          ),
          DiferenciasConteoData,
          PrefetchHooks Function()
        > {
  $$DiferenciasConteoTableTableManager(
    _$InventarioFisicoDatabase db,
    $DiferenciasConteoTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiferenciasConteoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiferenciasConteoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiferenciasConteoTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> conteoId = const Value.absent(),
                Value<int> productoId = const Value.absent(),
                Value<String> codigoProducto = const Value.absent(),
                Value<String> nombreProducto = const Value.absent(),
                Value<double> stockSistema = const Value.absent(),
                Value<double> stockFisico = const Value.absent(),
                Value<double> diferencia = const Value.absent(),
                Value<String?> motivo = const Value.absent(),
                Value<String> estado = const Value.absent(),
              }) => DiferenciasConteoCompanion(
                id: id,
                conteoId: conteoId,
                productoId: productoId,
                codigoProducto: codigoProducto,
                nombreProducto: nombreProducto,
                stockSistema: stockSistema,
                stockFisico: stockFisico,
                diferencia: diferencia,
                motivo: motivo,
                estado: estado,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int conteoId,
                required int productoId,
                required String codigoProducto,
                required String nombreProducto,
                required double stockSistema,
                required double stockFisico,
                required double diferencia,
                Value<String?> motivo = const Value.absent(),
                Value<String> estado = const Value.absent(),
              }) => DiferenciasConteoCompanion.insert(
                id: id,
                conteoId: conteoId,
                productoId: productoId,
                codigoProducto: codigoProducto,
                nombreProducto: nombreProducto,
                stockSistema: stockSistema,
                stockFisico: stockFisico,
                diferencia: diferencia,
                motivo: motivo,
                estado: estado,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DiferenciasConteoTableProcessedTableManager =
    ProcessedTableManager<
      _$InventarioFisicoDatabase,
      $DiferenciasConteoTable,
      DiferenciasConteoData,
      $$DiferenciasConteoTableFilterComposer,
      $$DiferenciasConteoTableOrderingComposer,
      $$DiferenciasConteoTableAnnotationComposer,
      $$DiferenciasConteoTableCreateCompanionBuilder,
      $$DiferenciasConteoTableUpdateCompanionBuilder,
      (
        DiferenciasConteoData,
        BaseReferences<
          _$InventarioFisicoDatabase,
          $DiferenciasConteoTable,
          DiferenciasConteoData
        >,
      ),
      DiferenciasConteoData,
      PrefetchHooks Function()
    >;

class $InventarioFisicoDatabaseManager {
  final _$InventarioFisicoDatabase _db;
  $InventarioFisicoDatabaseManager(this._db);
  $$ConteosFisicosTableTableManager get conteosFisicos =>
      $$ConteosFisicosTableTableManager(_db, _db.conteosFisicos);
  $$DiferenciasConteoTableTableManager get diferenciasConteo =>
      $$DiferenciasConteoTableTableManager(_db, _db.diferenciasConteo);
}
