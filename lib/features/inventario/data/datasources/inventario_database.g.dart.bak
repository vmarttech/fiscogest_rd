// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventario_database.dart';

// ignore_for_file: type=lint
class $InventarioTableTable extends InventarioTable
    with TableInfo<$InventarioTableTable, InventarioTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventarioTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _codigoMeta = const VerificationMeta('codigo');
  @override
  late final GeneratedColumn<String> codigo = GeneratedColumn<String>(
    'codigo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _precioCompraMeta = const VerificationMeta(
    'precioCompra',
  );
  @override
  late final GeneratedColumn<double> precioCompra = GeneratedColumn<double>(
    'precio_compra',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _precioVentaMeta = const VerificationMeta(
    'precioVenta',
  );
  @override
  late final GeneratedColumn<double> precioVenta = GeneratedColumn<double>(
    'precio_venta',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stockActualMeta = const VerificationMeta(
    'stockActual',
  );
  @override
  late final GeneratedColumn<double> stockActual = GeneratedColumn<double>(
    'stock_actual',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _stockMinimoMeta = const VerificationMeta(
    'stockMinimo',
  );
  @override
  late final GeneratedColumn<double> stockMinimo = GeneratedColumn<double>(
    'stock_minimo',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _categoriaIdMeta = const VerificationMeta(
    'categoriaId',
  );
  @override
  late final GeneratedColumn<int> categoriaId = GeneratedColumn<int>(
    'categoria_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _marcaIdMeta = const VerificationMeta(
    'marcaId',
  );
  @override
  late final GeneratedColumn<int> marcaId = GeneratedColumn<int>(
    'marca_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unidadIdMeta = const VerificationMeta(
    'unidadId',
  );
  @override
  late final GeneratedColumn<int> unidadId = GeneratedColumn<int>(
    'unidad_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
    'activo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("activo" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
  static const VerificationMeta _fechaActualizacionMeta =
      const VerificationMeta('fechaActualizacion');
  @override
  late final GeneratedColumn<DateTime> fechaActualizacion =
      GeneratedColumn<DateTime>(
        'fecha_actualizacion',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    codigo,
    nombre,
    precioCompra,
    precioVenta,
    stockActual,
    stockMinimo,
    categoriaId,
    marcaId,
    unidadId,
    activo,
    fechaCreacion,
    fechaActualizacion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventario_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventarioTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('codigo')) {
      context.handle(
        _codigoMeta,
        codigo.isAcceptableOrUnknown(data['codigo']!, _codigoMeta),
      );
    } else if (isInserting) {
      context.missing(_codigoMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('precio_compra')) {
      context.handle(
        _precioCompraMeta,
        precioCompra.isAcceptableOrUnknown(
          data['precio_compra']!,
          _precioCompraMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_precioCompraMeta);
    }
    if (data.containsKey('precio_venta')) {
      context.handle(
        _precioVentaMeta,
        precioVenta.isAcceptableOrUnknown(
          data['precio_venta']!,
          _precioVentaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_precioVentaMeta);
    }
    if (data.containsKey('stock_actual')) {
      context.handle(
        _stockActualMeta,
        stockActual.isAcceptableOrUnknown(
          data['stock_actual']!,
          _stockActualMeta,
        ),
      );
    }
    if (data.containsKey('stock_minimo')) {
      context.handle(
        _stockMinimoMeta,
        stockMinimo.isAcceptableOrUnknown(
          data['stock_minimo']!,
          _stockMinimoMeta,
        ),
      );
    }
    if (data.containsKey('categoria_id')) {
      context.handle(
        _categoriaIdMeta,
        categoriaId.isAcceptableOrUnknown(
          data['categoria_id']!,
          _categoriaIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categoriaIdMeta);
    }
    if (data.containsKey('marca_id')) {
      context.handle(
        _marcaIdMeta,
        marcaId.isAcceptableOrUnknown(data['marca_id']!, _marcaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_marcaIdMeta);
    }
    if (data.containsKey('unidad_id')) {
      context.handle(
        _unidadIdMeta,
        unidadId.isAcceptableOrUnknown(data['unidad_id']!, _unidadIdMeta),
      );
    } else if (isInserting) {
      context.missing(_unidadIdMeta);
    }
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
      );
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
    if (data.containsKey('fecha_actualizacion')) {
      context.handle(
        _fechaActualizacionMeta,
        fechaActualizacion.isAcceptableOrUnknown(
          data['fecha_actualizacion']!,
          _fechaActualizacionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventarioTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventarioTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      codigo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      precioCompra: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}precio_compra'],
      )!,
      precioVenta: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}precio_venta'],
      )!,
      stockActual: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stock_actual'],
      )!,
      stockMinimo: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stock_minimo'],
      )!,
      categoriaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}categoria_id'],
      )!,
      marcaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}marca_id'],
      )!,
      unidadId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unidad_id'],
      )!,
      activo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activo'],
      )!,
      fechaCreacion: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_creacion'],
      )!,
      fechaActualizacion: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_actualizacion'],
      ),
    );
  }

  @override
  $InventarioTableTable createAlias(String alias) {
    return $InventarioTableTable(attachedDatabase, alias);
  }
}

class InventarioTableData extends DataClass
    implements Insertable<InventarioTableData> {
  final int id;
  final String codigo;
  final String nombre;
  final double precioCompra;
  final double precioVenta;
  final double stockActual;
  final double stockMinimo;
  final int categoriaId;
  final int marcaId;
  final int unidadId;
  final bool activo;
  final DateTime fechaCreacion;
  final DateTime? fechaActualizacion;
  const InventarioTableData({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.precioCompra,
    required this.precioVenta,
    required this.stockActual,
    required this.stockMinimo,
    required this.categoriaId,
    required this.marcaId,
    required this.unidadId,
    required this.activo,
    required this.fechaCreacion,
    this.fechaActualizacion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['codigo'] = Variable<String>(codigo);
    map['nombre'] = Variable<String>(nombre);
    map['precio_compra'] = Variable<double>(precioCompra);
    map['precio_venta'] = Variable<double>(precioVenta);
    map['stock_actual'] = Variable<double>(stockActual);
    map['stock_minimo'] = Variable<double>(stockMinimo);
    map['categoria_id'] = Variable<int>(categoriaId);
    map['marca_id'] = Variable<int>(marcaId);
    map['unidad_id'] = Variable<int>(unidadId);
    map['activo'] = Variable<bool>(activo);
    map['fecha_creacion'] = Variable<DateTime>(fechaCreacion);
    if (!nullToAbsent || fechaActualizacion != null) {
      map['fecha_actualizacion'] = Variable<DateTime>(fechaActualizacion);
    }
    return map;
  }

  InventarioTableCompanion toCompanion(bool nullToAbsent) {
    return InventarioTableCompanion(
      id: Value(id),
      codigo: Value(codigo),
      nombre: Value(nombre),
      precioCompra: Value(precioCompra),
      precioVenta: Value(precioVenta),
      stockActual: Value(stockActual),
      stockMinimo: Value(stockMinimo),
      categoriaId: Value(categoriaId),
      marcaId: Value(marcaId),
      unidadId: Value(unidadId),
      activo: Value(activo),
      fechaCreacion: Value(fechaCreacion),
      fechaActualizacion: fechaActualizacion == null && nullToAbsent
          ? const Value.absent()
          : Value(fechaActualizacion),
    );
  }

  factory InventarioTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventarioTableData(
      id: serializer.fromJson<int>(json['id']),
      codigo: serializer.fromJson<String>(json['codigo']),
      nombre: serializer.fromJson<String>(json['nombre']),
      precioCompra: serializer.fromJson<double>(json['precioCompra']),
      precioVenta: serializer.fromJson<double>(json['precioVenta']),
      stockActual: serializer.fromJson<double>(json['stockActual']),
      stockMinimo: serializer.fromJson<double>(json['stockMinimo']),
      categoriaId: serializer.fromJson<int>(json['categoriaId']),
      marcaId: serializer.fromJson<int>(json['marcaId']),
      unidadId: serializer.fromJson<int>(json['unidadId']),
      activo: serializer.fromJson<bool>(json['activo']),
      fechaCreacion: serializer.fromJson<DateTime>(json['fechaCreacion']),
      fechaActualizacion: serializer.fromJson<DateTime?>(
        json['fechaActualizacion'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'codigo': serializer.toJson<String>(codigo),
      'nombre': serializer.toJson<String>(nombre),
      'precioCompra': serializer.toJson<double>(precioCompra),
      'precioVenta': serializer.toJson<double>(precioVenta),
      'stockActual': serializer.toJson<double>(stockActual),
      'stockMinimo': serializer.toJson<double>(stockMinimo),
      'categoriaId': serializer.toJson<int>(categoriaId),
      'marcaId': serializer.toJson<int>(marcaId),
      'unidadId': serializer.toJson<int>(unidadId),
      'activo': serializer.toJson<bool>(activo),
      'fechaCreacion': serializer.toJson<DateTime>(fechaCreacion),
      'fechaActualizacion': serializer.toJson<DateTime?>(fechaActualizacion),
    };
  }

  InventarioTableData copyWith({
    int? id,
    String? codigo,
    String? nombre,
    double? precioCompra,
    double? precioVenta,
    double? stockActual,
    double? stockMinimo,
    int? categoriaId,
    int? marcaId,
    int? unidadId,
    bool? activo,
    DateTime? fechaCreacion,
    Value<DateTime?> fechaActualizacion = const Value.absent(),
  }) => InventarioTableData(
    id: id ?? this.id,
    codigo: codigo ?? this.codigo,
    nombre: nombre ?? this.nombre,
    precioCompra: precioCompra ?? this.precioCompra,
    precioVenta: precioVenta ?? this.precioVenta,
    stockActual: stockActual ?? this.stockActual,
    stockMinimo: stockMinimo ?? this.stockMinimo,
    categoriaId: categoriaId ?? this.categoriaId,
    marcaId: marcaId ?? this.marcaId,
    unidadId: unidadId ?? this.unidadId,
    activo: activo ?? this.activo,
    fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    fechaActualizacion: fechaActualizacion.present
        ? fechaActualizacion.value
        : this.fechaActualizacion,
  );
  InventarioTableData copyWithCompanion(InventarioTableCompanion data) {
    return InventarioTableData(
      id: data.id.present ? data.id.value : this.id,
      codigo: data.codigo.present ? data.codigo.value : this.codigo,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      precioCompra: data.precioCompra.present
          ? data.precioCompra.value
          : this.precioCompra,
      precioVenta: data.precioVenta.present
          ? data.precioVenta.value
          : this.precioVenta,
      stockActual: data.stockActual.present
          ? data.stockActual.value
          : this.stockActual,
      stockMinimo: data.stockMinimo.present
          ? data.stockMinimo.value
          : this.stockMinimo,
      categoriaId: data.categoriaId.present
          ? data.categoriaId.value
          : this.categoriaId,
      marcaId: data.marcaId.present ? data.marcaId.value : this.marcaId,
      unidadId: data.unidadId.present ? data.unidadId.value : this.unidadId,
      activo: data.activo.present ? data.activo.value : this.activo,
      fechaCreacion: data.fechaCreacion.present
          ? data.fechaCreacion.value
          : this.fechaCreacion,
      fechaActualizacion: data.fechaActualizacion.present
          ? data.fechaActualizacion.value
          : this.fechaActualizacion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventarioTableData(')
          ..write('id: $id, ')
          ..write('codigo: $codigo, ')
          ..write('nombre: $nombre, ')
          ..write('precioCompra: $precioCompra, ')
          ..write('precioVenta: $precioVenta, ')
          ..write('stockActual: $stockActual, ')
          ..write('stockMinimo: $stockMinimo, ')
          ..write('categoriaId: $categoriaId, ')
          ..write('marcaId: $marcaId, ')
          ..write('unidadId: $unidadId, ')
          ..write('activo: $activo, ')
          ..write('fechaCreacion: $fechaCreacion, ')
          ..write('fechaActualizacion: $fechaActualizacion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    codigo,
    nombre,
    precioCompra,
    precioVenta,
    stockActual,
    stockMinimo,
    categoriaId,
    marcaId,
    unidadId,
    activo,
    fechaCreacion,
    fechaActualizacion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventarioTableData &&
          other.id == this.id &&
          other.codigo == this.codigo &&
          other.nombre == this.nombre &&
          other.precioCompra == this.precioCompra &&
          other.precioVenta == this.precioVenta &&
          other.stockActual == this.stockActual &&
          other.stockMinimo == this.stockMinimo &&
          other.categoriaId == this.categoriaId &&
          other.marcaId == this.marcaId &&
          other.unidadId == this.unidadId &&
          other.activo == this.activo &&
          other.fechaCreacion == this.fechaCreacion &&
          other.fechaActualizacion == this.fechaActualizacion);
}

class InventarioTableCompanion extends UpdateCompanion<InventarioTableData> {
  final Value<int> id;
  final Value<String> codigo;
  final Value<String> nombre;
  final Value<double> precioCompra;
  final Value<double> precioVenta;
  final Value<double> stockActual;
  final Value<double> stockMinimo;
  final Value<int> categoriaId;
  final Value<int> marcaId;
  final Value<int> unidadId;
  final Value<bool> activo;
  final Value<DateTime> fechaCreacion;
  final Value<DateTime?> fechaActualizacion;
  const InventarioTableCompanion({
    this.id = const Value.absent(),
    this.codigo = const Value.absent(),
    this.nombre = const Value.absent(),
    this.precioCompra = const Value.absent(),
    this.precioVenta = const Value.absent(),
    this.stockActual = const Value.absent(),
    this.stockMinimo = const Value.absent(),
    this.categoriaId = const Value.absent(),
    this.marcaId = const Value.absent(),
    this.unidadId = const Value.absent(),
    this.activo = const Value.absent(),
    this.fechaCreacion = const Value.absent(),
    this.fechaActualizacion = const Value.absent(),
  });
  InventarioTableCompanion.insert({
    this.id = const Value.absent(),
    required String codigo,
    required String nombre,
    required double precioCompra,
    required double precioVenta,
    this.stockActual = const Value.absent(),
    this.stockMinimo = const Value.absent(),
    required int categoriaId,
    required int marcaId,
    required int unidadId,
    this.activo = const Value.absent(),
    this.fechaCreacion = const Value.absent(),
    this.fechaActualizacion = const Value.absent(),
  }) : codigo = Value(codigo),
       nombre = Value(nombre),
       precioCompra = Value(precioCompra),
       precioVenta = Value(precioVenta),
       categoriaId = Value(categoriaId),
       marcaId = Value(marcaId),
       unidadId = Value(unidadId);
  static Insertable<InventarioTableData> custom({
    Expression<int>? id,
    Expression<String>? codigo,
    Expression<String>? nombre,
    Expression<double>? precioCompra,
    Expression<double>? precioVenta,
    Expression<double>? stockActual,
    Expression<double>? stockMinimo,
    Expression<int>? categoriaId,
    Expression<int>? marcaId,
    Expression<int>? unidadId,
    Expression<bool>? activo,
    Expression<DateTime>? fechaCreacion,
    Expression<DateTime>? fechaActualizacion,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (codigo != null) 'codigo': codigo,
      if (nombre != null) 'nombre': nombre,
      if (precioCompra != null) 'precio_compra': precioCompra,
      if (precioVenta != null) 'precio_venta': precioVenta,
      if (stockActual != null) 'stock_actual': stockActual,
      if (stockMinimo != null) 'stock_minimo': stockMinimo,
      if (categoriaId != null) 'categoria_id': categoriaId,
      if (marcaId != null) 'marca_id': marcaId,
      if (unidadId != null) 'unidad_id': unidadId,
      if (activo != null) 'activo': activo,
      if (fechaCreacion != null) 'fecha_creacion': fechaCreacion,
      if (fechaActualizacion != null) 'fecha_actualizacion': fechaActualizacion,
    });
  }

  InventarioTableCompanion copyWith({
    Value<int>? id,
    Value<String>? codigo,
    Value<String>? nombre,
    Value<double>? precioCompra,
    Value<double>? precioVenta,
    Value<double>? stockActual,
    Value<double>? stockMinimo,
    Value<int>? categoriaId,
    Value<int>? marcaId,
    Value<int>? unidadId,
    Value<bool>? activo,
    Value<DateTime>? fechaCreacion,
    Value<DateTime?>? fechaActualizacion,
  }) {
    return InventarioTableCompanion(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      precioCompra: precioCompra ?? this.precioCompra,
      precioVenta: precioVenta ?? this.precioVenta,
      stockActual: stockActual ?? this.stockActual,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      categoriaId: categoriaId ?? this.categoriaId,
      marcaId: marcaId ?? this.marcaId,
      unidadId: unidadId ?? this.unidadId,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (codigo.present) {
      map['codigo'] = Variable<String>(codigo.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (precioCompra.present) {
      map['precio_compra'] = Variable<double>(precioCompra.value);
    }
    if (precioVenta.present) {
      map['precio_venta'] = Variable<double>(precioVenta.value);
    }
    if (stockActual.present) {
      map['stock_actual'] = Variable<double>(stockActual.value);
    }
    if (stockMinimo.present) {
      map['stock_minimo'] = Variable<double>(stockMinimo.value);
    }
    if (categoriaId.present) {
      map['categoria_id'] = Variable<int>(categoriaId.value);
    }
    if (marcaId.present) {
      map['marca_id'] = Variable<int>(marcaId.value);
    }
    if (unidadId.present) {
      map['unidad_id'] = Variable<int>(unidadId.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    if (fechaCreacion.present) {
      map['fecha_creacion'] = Variable<DateTime>(fechaCreacion.value);
    }
    if (fechaActualizacion.present) {
      map['fecha_actualizacion'] = Variable<DateTime>(fechaActualizacion.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventarioTableCompanion(')
          ..write('id: $id, ')
          ..write('codigo: $codigo, ')
          ..write('nombre: $nombre, ')
          ..write('precioCompra: $precioCompra, ')
          ..write('precioVenta: $precioVenta, ')
          ..write('stockActual: $stockActual, ')
          ..write('stockMinimo: $stockMinimo, ')
          ..write('categoriaId: $categoriaId, ')
          ..write('marcaId: $marcaId, ')
          ..write('unidadId: $unidadId, ')
          ..write('activo: $activo, ')
          ..write('fechaCreacion: $fechaCreacion, ')
          ..write('fechaActualizacion: $fechaActualizacion')
          ..write(')'))
        .toString();
  }
}

abstract class _$InventarioDatabase extends GeneratedDatabase {
  _$InventarioDatabase(QueryExecutor e) : super(e);
  $InventarioDatabaseManager get managers => $InventarioDatabaseManager(this);
  late final $InventarioTableTable inventarioTable = $InventarioTableTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [inventarioTable];
}

typedef $$InventarioTableTableCreateCompanionBuilder =
    InventarioTableCompanion Function({
      Value<int> id,
      required String codigo,
      required String nombre,
      required double precioCompra,
      required double precioVenta,
      Value<double> stockActual,
      Value<double> stockMinimo,
      required int categoriaId,
      required int marcaId,
      required int unidadId,
      Value<bool> activo,
      Value<DateTime> fechaCreacion,
      Value<DateTime?> fechaActualizacion,
    });
typedef $$InventarioTableTableUpdateCompanionBuilder =
    InventarioTableCompanion Function({
      Value<int> id,
      Value<String> codigo,
      Value<String> nombre,
      Value<double> precioCompra,
      Value<double> precioVenta,
      Value<double> stockActual,
      Value<double> stockMinimo,
      Value<int> categoriaId,
      Value<int> marcaId,
      Value<int> unidadId,
      Value<bool> activo,
      Value<DateTime> fechaCreacion,
      Value<DateTime?> fechaActualizacion,
    });

class $$InventarioTableTableFilterComposer
    extends Composer<_$InventarioDatabase, $InventarioTableTable> {
  $$InventarioTableTableFilterComposer({
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

  ColumnFilters<String> get codigo => $composableBuilder(
    column: $table.codigo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get precioCompra => $composableBuilder(
    column: $table.precioCompra,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get precioVenta => $composableBuilder(
    column: $table.precioVenta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stockActual => $composableBuilder(
    column: $table.stockActual,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stockMinimo => $composableBuilder(
    column: $table.stockMinimo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoriaId => $composableBuilder(
    column: $table.categoriaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get marcaId => $composableBuilder(
    column: $table.marcaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unidadId => $composableBuilder(
    column: $table.unidadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaCreacion => $composableBuilder(
    column: $table.fechaCreacion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaActualizacion => $composableBuilder(
    column: $table.fechaActualizacion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InventarioTableTableOrderingComposer
    extends Composer<_$InventarioDatabase, $InventarioTableTable> {
  $$InventarioTableTableOrderingComposer({
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

  ColumnOrderings<String> get codigo => $composableBuilder(
    column: $table.codigo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get precioCompra => $composableBuilder(
    column: $table.precioCompra,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get precioVenta => $composableBuilder(
    column: $table.precioVenta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stockActual => $composableBuilder(
    column: $table.stockActual,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stockMinimo => $composableBuilder(
    column: $table.stockMinimo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoriaId => $composableBuilder(
    column: $table.categoriaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get marcaId => $composableBuilder(
    column: $table.marcaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unidadId => $composableBuilder(
    column: $table.unidadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaCreacion => $composableBuilder(
    column: $table.fechaCreacion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaActualizacion => $composableBuilder(
    column: $table.fechaActualizacion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InventarioTableTableAnnotationComposer
    extends Composer<_$InventarioDatabase, $InventarioTableTable> {
  $$InventarioTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get codigo =>
      $composableBuilder(column: $table.codigo, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<double> get precioCompra => $composableBuilder(
    column: $table.precioCompra,
    builder: (column) => column,
  );

  GeneratedColumn<double> get precioVenta => $composableBuilder(
    column: $table.precioVenta,
    builder: (column) => column,
  );

  GeneratedColumn<double> get stockActual => $composableBuilder(
    column: $table.stockActual,
    builder: (column) => column,
  );

  GeneratedColumn<double> get stockMinimo => $composableBuilder(
    column: $table.stockMinimo,
    builder: (column) => column,
  );

  GeneratedColumn<int> get categoriaId => $composableBuilder(
    column: $table.categoriaId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get marcaId =>
      $composableBuilder(column: $table.marcaId, builder: (column) => column);

  GeneratedColumn<int> get unidadId =>
      $composableBuilder(column: $table.unidadId, builder: (column) => column);

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  GeneratedColumn<DateTime> get fechaCreacion => $composableBuilder(
    column: $table.fechaCreacion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaActualizacion => $composableBuilder(
    column: $table.fechaActualizacion,
    builder: (column) => column,
  );
}

class $$InventarioTableTableTableManager
    extends
        RootTableManager<
          _$InventarioDatabase,
          $InventarioTableTable,
          InventarioTableData,
          $$InventarioTableTableFilterComposer,
          $$InventarioTableTableOrderingComposer,
          $$InventarioTableTableAnnotationComposer,
          $$InventarioTableTableCreateCompanionBuilder,
          $$InventarioTableTableUpdateCompanionBuilder,
          (
            InventarioTableData,
            BaseReferences<
              _$InventarioDatabase,
              $InventarioTableTable,
              InventarioTableData
            >,
          ),
          InventarioTableData,
          PrefetchHooks Function()
        > {
  $$InventarioTableTableTableManager(
    _$InventarioDatabase db,
    $InventarioTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventarioTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventarioTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventarioTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> codigo = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<double> precioCompra = const Value.absent(),
                Value<double> precioVenta = const Value.absent(),
                Value<double> stockActual = const Value.absent(),
                Value<double> stockMinimo = const Value.absent(),
                Value<int> categoriaId = const Value.absent(),
                Value<int> marcaId = const Value.absent(),
                Value<int> unidadId = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<DateTime> fechaCreacion = const Value.absent(),
                Value<DateTime?> fechaActualizacion = const Value.absent(),
              }) => InventarioTableCompanion(
                id: id,
                codigo: codigo,
                nombre: nombre,
                precioCompra: precioCompra,
                precioVenta: precioVenta,
                stockActual: stockActual,
                stockMinimo: stockMinimo,
                categoriaId: categoriaId,
                marcaId: marcaId,
                unidadId: unidadId,
                activo: activo,
                fechaCreacion: fechaCreacion,
                fechaActualizacion: fechaActualizacion,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String codigo,
                required String nombre,
                required double precioCompra,
                required double precioVenta,
                Value<double> stockActual = const Value.absent(),
                Value<double> stockMinimo = const Value.absent(),
                required int categoriaId,
                required int marcaId,
                required int unidadId,
                Value<bool> activo = const Value.absent(),
                Value<DateTime> fechaCreacion = const Value.absent(),
                Value<DateTime?> fechaActualizacion = const Value.absent(),
              }) => InventarioTableCompanion.insert(
                id: id,
                codigo: codigo,
                nombre: nombre,
                precioCompra: precioCompra,
                precioVenta: precioVenta,
                stockActual: stockActual,
                stockMinimo: stockMinimo,
                categoriaId: categoriaId,
                marcaId: marcaId,
                unidadId: unidadId,
                activo: activo,
                fechaCreacion: fechaCreacion,
                fechaActualizacion: fechaActualizacion,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InventarioTableTableProcessedTableManager =
    ProcessedTableManager<
      _$InventarioDatabase,
      $InventarioTableTable,
      InventarioTableData,
      $$InventarioTableTableFilterComposer,
      $$InventarioTableTableOrderingComposer,
      $$InventarioTableTableAnnotationComposer,
      $$InventarioTableTableCreateCompanionBuilder,
      $$InventarioTableTableUpdateCompanionBuilder,
      (
        InventarioTableData,
        BaseReferences<
          _$InventarioDatabase,
          $InventarioTableTable,
          InventarioTableData
        >,
      ),
      InventarioTableData,
      PrefetchHooks Function()
    >;

class $InventarioDatabaseManager {
  final _$InventarioDatabase _db;
  $InventarioDatabaseManager(this._db);
  $$InventarioTableTableTableManager get inventarioTable =>
      $$InventarioTableTableTableManager(_db, _db.inventarioTable);
}
