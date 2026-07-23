// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ClientesTableTable extends ClientesTable
    with TableInfo<$ClientesTableTable, ClientesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClientesTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _rncCedulaMeta = const VerificationMeta(
    'rncCedula',
  );
  @override
  late final GeneratedColumn<String> rncCedula = GeneratedColumn<String>(
    'rnc_cedula',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _telefonoMeta = const VerificationMeta(
    'telefono',
  );
  @override
  late final GeneratedColumn<String> telefono = GeneratedColumn<String>(
    'telefono',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correoMeta = const VerificationMeta('correo');
  @override
  late final GeneratedColumn<String> correo = GeneratedColumn<String>(
    'correo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _direccionMeta = const VerificationMeta(
    'direccion',
  );
  @override
  late final GeneratedColumn<String> direccion = GeneratedColumn<String>(
    'direccion',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    codigo,
    nombre,
    rncCedula,
    telefono,
    correo,
    direccion,
    activo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clientes_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClientesTableData> instance, {
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
    if (data.containsKey('rnc_cedula')) {
      context.handle(
        _rncCedulaMeta,
        rncCedula.isAcceptableOrUnknown(data['rnc_cedula']!, _rncCedulaMeta),
      );
    } else if (isInserting) {
      context.missing(_rncCedulaMeta);
    }
    if (data.containsKey('telefono')) {
      context.handle(
        _telefonoMeta,
        telefono.isAcceptableOrUnknown(data['telefono']!, _telefonoMeta),
      );
    } else if (isInserting) {
      context.missing(_telefonoMeta);
    }
    if (data.containsKey('correo')) {
      context.handle(
        _correoMeta,
        correo.isAcceptableOrUnknown(data['correo']!, _correoMeta),
      );
    } else if (isInserting) {
      context.missing(_correoMeta);
    }
    if (data.containsKey('direccion')) {
      context.handle(
        _direccionMeta,
        direccion.isAcceptableOrUnknown(data['direccion']!, _direccionMeta),
      );
    } else if (isInserting) {
      context.missing(_direccionMeta);
    }
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClientesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClientesTableData(
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
      rncCedula: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rnc_cedula'],
      )!,
      telefono: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}telefono'],
      )!,
      correo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}correo'],
      )!,
      direccion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direccion'],
      )!,
      activo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activo'],
      )!,
    );
  }

  @override
  $ClientesTableTable createAlias(String alias) {
    return $ClientesTableTable(attachedDatabase, alias);
  }
}

class ClientesTableData extends DataClass
    implements Insertable<ClientesTableData> {
  final int id;
  final String codigo;
  final String nombre;
  final String rncCedula;
  final String telefono;
  final String correo;
  final String direccion;
  final bool activo;
  const ClientesTableData({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.rncCedula,
    required this.telefono,
    required this.correo,
    required this.direccion,
    required this.activo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['codigo'] = Variable<String>(codigo);
    map['nombre'] = Variable<String>(nombre);
    map['rnc_cedula'] = Variable<String>(rncCedula);
    map['telefono'] = Variable<String>(telefono);
    map['correo'] = Variable<String>(correo);
    map['direccion'] = Variable<String>(direccion);
    map['activo'] = Variable<bool>(activo);
    return map;
  }

  ClientesTableCompanion toCompanion(bool nullToAbsent) {
    return ClientesTableCompanion(
      id: Value(id),
      codigo: Value(codigo),
      nombre: Value(nombre),
      rncCedula: Value(rncCedula),
      telefono: Value(telefono),
      correo: Value(correo),
      direccion: Value(direccion),
      activo: Value(activo),
    );
  }

  factory ClientesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClientesTableData(
      id: serializer.fromJson<int>(json['id']),
      codigo: serializer.fromJson<String>(json['codigo']),
      nombre: serializer.fromJson<String>(json['nombre']),
      rncCedula: serializer.fromJson<String>(json['rncCedula']),
      telefono: serializer.fromJson<String>(json['telefono']),
      correo: serializer.fromJson<String>(json['correo']),
      direccion: serializer.fromJson<String>(json['direccion']),
      activo: serializer.fromJson<bool>(json['activo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'codigo': serializer.toJson<String>(codigo),
      'nombre': serializer.toJson<String>(nombre),
      'rncCedula': serializer.toJson<String>(rncCedula),
      'telefono': serializer.toJson<String>(telefono),
      'correo': serializer.toJson<String>(correo),
      'direccion': serializer.toJson<String>(direccion),
      'activo': serializer.toJson<bool>(activo),
    };
  }

  ClientesTableData copyWith({
    int? id,
    String? codigo,
    String? nombre,
    String? rncCedula,
    String? telefono,
    String? correo,
    String? direccion,
    bool? activo,
  }) => ClientesTableData(
    id: id ?? this.id,
    codigo: codigo ?? this.codigo,
    nombre: nombre ?? this.nombre,
    rncCedula: rncCedula ?? this.rncCedula,
    telefono: telefono ?? this.telefono,
    correo: correo ?? this.correo,
    direccion: direccion ?? this.direccion,
    activo: activo ?? this.activo,
  );
  ClientesTableData copyWithCompanion(ClientesTableCompanion data) {
    return ClientesTableData(
      id: data.id.present ? data.id.value : this.id,
      codigo: data.codigo.present ? data.codigo.value : this.codigo,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      rncCedula: data.rncCedula.present ? data.rncCedula.value : this.rncCedula,
      telefono: data.telefono.present ? data.telefono.value : this.telefono,
      correo: data.correo.present ? data.correo.value : this.correo,
      direccion: data.direccion.present ? data.direccion.value : this.direccion,
      activo: data.activo.present ? data.activo.value : this.activo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClientesTableData(')
          ..write('id: $id, ')
          ..write('codigo: $codigo, ')
          ..write('nombre: $nombre, ')
          ..write('rncCedula: $rncCedula, ')
          ..write('telefono: $telefono, ')
          ..write('correo: $correo, ')
          ..write('direccion: $direccion, ')
          ..write('activo: $activo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    codigo,
    nombre,
    rncCedula,
    telefono,
    correo,
    direccion,
    activo,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClientesTableData &&
          other.id == this.id &&
          other.codigo == this.codigo &&
          other.nombre == this.nombre &&
          other.rncCedula == this.rncCedula &&
          other.telefono == this.telefono &&
          other.correo == this.correo &&
          other.direccion == this.direccion &&
          other.activo == this.activo);
}

class ClientesTableCompanion extends UpdateCompanion<ClientesTableData> {
  final Value<int> id;
  final Value<String> codigo;
  final Value<String> nombre;
  final Value<String> rncCedula;
  final Value<String> telefono;
  final Value<String> correo;
  final Value<String> direccion;
  final Value<bool> activo;
  const ClientesTableCompanion({
    this.id = const Value.absent(),
    this.codigo = const Value.absent(),
    this.nombre = const Value.absent(),
    this.rncCedula = const Value.absent(),
    this.telefono = const Value.absent(),
    this.correo = const Value.absent(),
    this.direccion = const Value.absent(),
    this.activo = const Value.absent(),
  });
  ClientesTableCompanion.insert({
    this.id = const Value.absent(),
    required String codigo,
    required String nombre,
    required String rncCedula,
    required String telefono,
    required String correo,
    required String direccion,
    this.activo = const Value.absent(),
  }) : codigo = Value(codigo),
       nombre = Value(nombre),
       rncCedula = Value(rncCedula),
       telefono = Value(telefono),
       correo = Value(correo),
       direccion = Value(direccion);
  static Insertable<ClientesTableData> custom({
    Expression<int>? id,
    Expression<String>? codigo,
    Expression<String>? nombre,
    Expression<String>? rncCedula,
    Expression<String>? telefono,
    Expression<String>? correo,
    Expression<String>? direccion,
    Expression<bool>? activo,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (codigo != null) 'codigo': codigo,
      if (nombre != null) 'nombre': nombre,
      if (rncCedula != null) 'rnc_cedula': rncCedula,
      if (telefono != null) 'telefono': telefono,
      if (correo != null) 'correo': correo,
      if (direccion != null) 'direccion': direccion,
      if (activo != null) 'activo': activo,
    });
  }

  ClientesTableCompanion copyWith({
    Value<int>? id,
    Value<String>? codigo,
    Value<String>? nombre,
    Value<String>? rncCedula,
    Value<String>? telefono,
    Value<String>? correo,
    Value<String>? direccion,
    Value<bool>? activo,
  }) {
    return ClientesTableCompanion(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      rncCedula: rncCedula ?? this.rncCedula,
      telefono: telefono ?? this.telefono,
      correo: correo ?? this.correo,
      direccion: direccion ?? this.direccion,
      activo: activo ?? this.activo,
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
    if (rncCedula.present) {
      map['rnc_cedula'] = Variable<String>(rncCedula.value);
    }
    if (telefono.present) {
      map['telefono'] = Variable<String>(telefono.value);
    }
    if (correo.present) {
      map['correo'] = Variable<String>(correo.value);
    }
    if (direccion.present) {
      map['direccion'] = Variable<String>(direccion.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClientesTableCompanion(')
          ..write('id: $id, ')
          ..write('codigo: $codigo, ')
          ..write('nombre: $nombre, ')
          ..write('rncCedula: $rncCedula, ')
          ..write('telefono: $telefono, ')
          ..write('correo: $correo, ')
          ..write('direccion: $direccion, ')
          ..write('activo: $activo')
          ..write(')'))
        .toString();
  }
}

class $ConfiguracionTableTable extends ConfiguracionTable
    with TableInfo<$ConfiguracionTableTable, ConfiguracionTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConfiguracionTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nombreNegocioMeta = const VerificationMeta(
    'nombreNegocio',
  );
  @override
  late final GeneratedColumn<String> nombreNegocio = GeneratedColumn<String>(
    'nombre_negocio',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rncCedulaMeta = const VerificationMeta(
    'rncCedula',
  );
  @override
  late final GeneratedColumn<String> rncCedula = GeneratedColumn<String>(
    'rnc_cedula',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monedaMeta = const VerificationMeta('moneda');
  @override
  late final GeneratedColumn<String> moneda = GeneratedColumn<String>(
    'moneda',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatoFechaMeta = const VerificationMeta(
    'formatoFecha',
  );
  @override
  late final GeneratedColumn<String> formatoFecha = GeneratedColumn<String>(
    'formato_fecha',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _impuestoPorcentajeMeta =
      const VerificationMeta('impuestoPorcentaje');
  @override
  late final GeneratedColumn<double> impuestoPorcentaje =
      GeneratedColumn<double>(
        'impuesto_porcentaje',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _idiomaMeta = const VerificationMeta('idioma');
  @override
  late final GeneratedColumn<String> idioma = GeneratedColumn<String>(
    'idioma',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nombreNegocio,
    rncCedula,
    moneda,
    formatoFecha,
    impuestoPorcentaje,
    idioma,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'configuracion_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConfiguracionTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nombre_negocio')) {
      context.handle(
        _nombreNegocioMeta,
        nombreNegocio.isAcceptableOrUnknown(
          data['nombre_negocio']!,
          _nombreNegocioMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nombreNegocioMeta);
    }
    if (data.containsKey('rnc_cedula')) {
      context.handle(
        _rncCedulaMeta,
        rncCedula.isAcceptableOrUnknown(data['rnc_cedula']!, _rncCedulaMeta),
      );
    } else if (isInserting) {
      context.missing(_rncCedulaMeta);
    }
    if (data.containsKey('moneda')) {
      context.handle(
        _monedaMeta,
        moneda.isAcceptableOrUnknown(data['moneda']!, _monedaMeta),
      );
    } else if (isInserting) {
      context.missing(_monedaMeta);
    }
    if (data.containsKey('formato_fecha')) {
      context.handle(
        _formatoFechaMeta,
        formatoFecha.isAcceptableOrUnknown(
          data['formato_fecha']!,
          _formatoFechaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_formatoFechaMeta);
    }
    if (data.containsKey('impuesto_porcentaje')) {
      context.handle(
        _impuestoPorcentajeMeta,
        impuestoPorcentaje.isAcceptableOrUnknown(
          data['impuesto_porcentaje']!,
          _impuestoPorcentajeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_impuestoPorcentajeMeta);
    }
    if (data.containsKey('idioma')) {
      context.handle(
        _idiomaMeta,
        idioma.isAcceptableOrUnknown(data['idioma']!, _idiomaMeta),
      );
    } else if (isInserting) {
      context.missing(_idiomaMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConfiguracionTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConfiguracionTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nombreNegocio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre_negocio'],
      )!,
      rncCedula: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rnc_cedula'],
      )!,
      moneda: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}moneda'],
      )!,
      formatoFecha: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}formato_fecha'],
      )!,
      impuestoPorcentaje: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}impuesto_porcentaje'],
      )!,
      idioma: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idioma'],
      )!,
    );
  }

  @override
  $ConfiguracionTableTable createAlias(String alias) {
    return $ConfiguracionTableTable(attachedDatabase, alias);
  }
}

class ConfiguracionTableData extends DataClass
    implements Insertable<ConfiguracionTableData> {
  final int id;
  final String nombreNegocio;
  final String rncCedula;
  final String moneda;
  final String formatoFecha;
  final double impuestoPorcentaje;
  final String idioma;
  const ConfiguracionTableData({
    required this.id,
    required this.nombreNegocio,
    required this.rncCedula,
    required this.moneda,
    required this.formatoFecha,
    required this.impuestoPorcentaje,
    required this.idioma,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nombre_negocio'] = Variable<String>(nombreNegocio);
    map['rnc_cedula'] = Variable<String>(rncCedula);
    map['moneda'] = Variable<String>(moneda);
    map['formato_fecha'] = Variable<String>(formatoFecha);
    map['impuesto_porcentaje'] = Variable<double>(impuestoPorcentaje);
    map['idioma'] = Variable<String>(idioma);
    return map;
  }

  ConfiguracionTableCompanion toCompanion(bool nullToAbsent) {
    return ConfiguracionTableCompanion(
      id: Value(id),
      nombreNegocio: Value(nombreNegocio),
      rncCedula: Value(rncCedula),
      moneda: Value(moneda),
      formatoFecha: Value(formatoFecha),
      impuestoPorcentaje: Value(impuestoPorcentaje),
      idioma: Value(idioma),
    );
  }

  factory ConfiguracionTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConfiguracionTableData(
      id: serializer.fromJson<int>(json['id']),
      nombreNegocio: serializer.fromJson<String>(json['nombreNegocio']),
      rncCedula: serializer.fromJson<String>(json['rncCedula']),
      moneda: serializer.fromJson<String>(json['moneda']),
      formatoFecha: serializer.fromJson<String>(json['formatoFecha']),
      impuestoPorcentaje: serializer.fromJson<double>(
        json['impuestoPorcentaje'],
      ),
      idioma: serializer.fromJson<String>(json['idioma']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nombreNegocio': serializer.toJson<String>(nombreNegocio),
      'rncCedula': serializer.toJson<String>(rncCedula),
      'moneda': serializer.toJson<String>(moneda),
      'formatoFecha': serializer.toJson<String>(formatoFecha),
      'impuestoPorcentaje': serializer.toJson<double>(impuestoPorcentaje),
      'idioma': serializer.toJson<String>(idioma),
    };
  }

  ConfiguracionTableData copyWith({
    int? id,
    String? nombreNegocio,
    String? rncCedula,
    String? moneda,
    String? formatoFecha,
    double? impuestoPorcentaje,
    String? idioma,
  }) => ConfiguracionTableData(
    id: id ?? this.id,
    nombreNegocio: nombreNegocio ?? this.nombreNegocio,
    rncCedula: rncCedula ?? this.rncCedula,
    moneda: moneda ?? this.moneda,
    formatoFecha: formatoFecha ?? this.formatoFecha,
    impuestoPorcentaje: impuestoPorcentaje ?? this.impuestoPorcentaje,
    idioma: idioma ?? this.idioma,
  );
  ConfiguracionTableData copyWithCompanion(ConfiguracionTableCompanion data) {
    return ConfiguracionTableData(
      id: data.id.present ? data.id.value : this.id,
      nombreNegocio: data.nombreNegocio.present
          ? data.nombreNegocio.value
          : this.nombreNegocio,
      rncCedula: data.rncCedula.present ? data.rncCedula.value : this.rncCedula,
      moneda: data.moneda.present ? data.moneda.value : this.moneda,
      formatoFecha: data.formatoFecha.present
          ? data.formatoFecha.value
          : this.formatoFecha,
      impuestoPorcentaje: data.impuestoPorcentaje.present
          ? data.impuestoPorcentaje.value
          : this.impuestoPorcentaje,
      idioma: data.idioma.present ? data.idioma.value : this.idioma,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConfiguracionTableData(')
          ..write('id: $id, ')
          ..write('nombreNegocio: $nombreNegocio, ')
          ..write('rncCedula: $rncCedula, ')
          ..write('moneda: $moneda, ')
          ..write('formatoFecha: $formatoFecha, ')
          ..write('impuestoPorcentaje: $impuestoPorcentaje, ')
          ..write('idioma: $idioma')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nombreNegocio,
    rncCedula,
    moneda,
    formatoFecha,
    impuestoPorcentaje,
    idioma,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConfiguracionTableData &&
          other.id == this.id &&
          other.nombreNegocio == this.nombreNegocio &&
          other.rncCedula == this.rncCedula &&
          other.moneda == this.moneda &&
          other.formatoFecha == this.formatoFecha &&
          other.impuestoPorcentaje == this.impuestoPorcentaje &&
          other.idioma == this.idioma);
}

class ConfiguracionTableCompanion
    extends UpdateCompanion<ConfiguracionTableData> {
  final Value<int> id;
  final Value<String> nombreNegocio;
  final Value<String> rncCedula;
  final Value<String> moneda;
  final Value<String> formatoFecha;
  final Value<double> impuestoPorcentaje;
  final Value<String> idioma;
  const ConfiguracionTableCompanion({
    this.id = const Value.absent(),
    this.nombreNegocio = const Value.absent(),
    this.rncCedula = const Value.absent(),
    this.moneda = const Value.absent(),
    this.formatoFecha = const Value.absent(),
    this.impuestoPorcentaje = const Value.absent(),
    this.idioma = const Value.absent(),
  });
  ConfiguracionTableCompanion.insert({
    this.id = const Value.absent(),
    required String nombreNegocio,
    required String rncCedula,
    required String moneda,
    required String formatoFecha,
    required double impuestoPorcentaje,
    required String idioma,
  }) : nombreNegocio = Value(nombreNegocio),
       rncCedula = Value(rncCedula),
       moneda = Value(moneda),
       formatoFecha = Value(formatoFecha),
       impuestoPorcentaje = Value(impuestoPorcentaje),
       idioma = Value(idioma);
  static Insertable<ConfiguracionTableData> custom({
    Expression<int>? id,
    Expression<String>? nombreNegocio,
    Expression<String>? rncCedula,
    Expression<String>? moneda,
    Expression<String>? formatoFecha,
    Expression<double>? impuestoPorcentaje,
    Expression<String>? idioma,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombreNegocio != null) 'nombre_negocio': nombreNegocio,
      if (rncCedula != null) 'rnc_cedula': rncCedula,
      if (moneda != null) 'moneda': moneda,
      if (formatoFecha != null) 'formato_fecha': formatoFecha,
      if (impuestoPorcentaje != null) 'impuesto_porcentaje': impuestoPorcentaje,
      if (idioma != null) 'idioma': idioma,
    });
  }

  ConfiguracionTableCompanion copyWith({
    Value<int>? id,
    Value<String>? nombreNegocio,
    Value<String>? rncCedula,
    Value<String>? moneda,
    Value<String>? formatoFecha,
    Value<double>? impuestoPorcentaje,
    Value<String>? idioma,
  }) {
    return ConfiguracionTableCompanion(
      id: id ?? this.id,
      nombreNegocio: nombreNegocio ?? this.nombreNegocio,
      rncCedula: rncCedula ?? this.rncCedula,
      moneda: moneda ?? this.moneda,
      formatoFecha: formatoFecha ?? this.formatoFecha,
      impuestoPorcentaje: impuestoPorcentaje ?? this.impuestoPorcentaje,
      idioma: idioma ?? this.idioma,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nombreNegocio.present) {
      map['nombre_negocio'] = Variable<String>(nombreNegocio.value);
    }
    if (rncCedula.present) {
      map['rnc_cedula'] = Variable<String>(rncCedula.value);
    }
    if (moneda.present) {
      map['moneda'] = Variable<String>(moneda.value);
    }
    if (formatoFecha.present) {
      map['formato_fecha'] = Variable<String>(formatoFecha.value);
    }
    if (impuestoPorcentaje.present) {
      map['impuesto_porcentaje'] = Variable<double>(impuestoPorcentaje.value);
    }
    if (idioma.present) {
      map['idioma'] = Variable<String>(idioma.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConfiguracionTableCompanion(')
          ..write('id: $id, ')
          ..write('nombreNegocio: $nombreNegocio, ')
          ..write('rncCedula: $rncCedula, ')
          ..write('moneda: $moneda, ')
          ..write('formatoFecha: $formatoFecha, ')
          ..write('impuestoPorcentaje: $impuestoPorcentaje, ')
          ..write('idioma: $idioma')
          ..write(')'))
        .toString();
  }
}

class $ProductosTableTable extends ProductosTable
    with TableInfo<$ProductosTableTable, ProductosTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductosTableTable(this.attachedDatabase, [this._alias]);
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'UNIQUE',
  );
  static const VerificationMeta _codigoBarrasMeta = const VerificationMeta(
    'codigoBarras',
  );
  @override
  late final GeneratedColumn<String> codigoBarras = GeneratedColumn<String>(
    'codigo_barras',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'UNIQUE',
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descripcionMeta = const VerificationMeta(
    'descripcion',
  );
  @override
  late final GeneratedColumn<String> descripcion = GeneratedColumn<String>(
    'descripcion',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _precioCompraMeta = const VerificationMeta(
    'precioCompra',
  );
  @override
  late final GeneratedColumn<double> precioCompra = GeneratedColumn<double>(
    'precio_compra',
    aliasedName,
    false,
    check: () => ComparableExpr(precioCompra).isBiggerOrEqualValue(0.0),
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
    check: () => ComparableExpr(precioVenta).isBiggerOrEqualValue(0.0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stockMeta = const VerificationMeta('stock');
  @override
  late final GeneratedColumn<double> stock = GeneratedColumn<double>(
    'stock',
    aliasedName,
    false,
    check: () => ComparableExpr(stock).isBiggerOrEqualValue(0.0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stockMinimoMeta = const VerificationMeta(
    'stockMinimo',
  );
  @override
  late final GeneratedColumn<double> stockMinimo = GeneratedColumn<double>(
    'stock_minimo',
    aliasedName,
    false,
    check: () => ComparableExpr(stockMinimo).isBiggerOrEqualValue(0.0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
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
  static const VerificationMeta _unidadMedidaIdMeta = const VerificationMeta(
    'unidadMedidaId',
  );
  @override
  late final GeneratedColumn<int> unidadMedidaId = GeneratedColumn<int>(
    'unidad_medida_id',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    codigo,
    codigoBarras,
    nombre,
    descripcion,
    precioCompra,
    precioVenta,
    stock,
    stockMinimo,
    categoriaId,
    marcaId,
    unidadMedidaId,
    activo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'productos_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductosTableData> instance, {
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
    if (data.containsKey('codigo_barras')) {
      context.handle(
        _codigoBarrasMeta,
        codigoBarras.isAcceptableOrUnknown(
          data['codigo_barras']!,
          _codigoBarrasMeta,
        ),
      );
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('descripcion')) {
      context.handle(
        _descripcionMeta,
        descripcion.isAcceptableOrUnknown(
          data['descripcion']!,
          _descripcionMeta,
        ),
      );
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
    if (data.containsKey('stock')) {
      context.handle(
        _stockMeta,
        stock.isAcceptableOrUnknown(data['stock']!, _stockMeta),
      );
    } else if (isInserting) {
      context.missing(_stockMeta);
    }
    if (data.containsKey('stock_minimo')) {
      context.handle(
        _stockMinimoMeta,
        stockMinimo.isAcceptableOrUnknown(
          data['stock_minimo']!,
          _stockMinimoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stockMinimoMeta);
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
    if (data.containsKey('unidad_medida_id')) {
      context.handle(
        _unidadMedidaIdMeta,
        unidadMedidaId.isAcceptableOrUnknown(
          data['unidad_medida_id']!,
          _unidadMedidaIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unidadMedidaIdMeta);
    }
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductosTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductosTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      codigo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo'],
      )!,
      codigoBarras: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo_barras'],
      ),
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      descripcion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descripcion'],
      ),
      precioCompra: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}precio_compra'],
      )!,
      precioVenta: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}precio_venta'],
      )!,
      stock: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stock'],
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
      unidadMedidaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unidad_medida_id'],
      )!,
      activo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activo'],
      )!,
    );
  }

  @override
  $ProductosTableTable createAlias(String alias) {
    return $ProductosTableTable(attachedDatabase, alias);
  }
}

class ProductosTableData extends DataClass
    implements Insertable<ProductosTableData> {
  final int id;
  final String codigo;
  final String? codigoBarras;
  final String nombre;
  final String? descripcion;
  final double precioCompra;
  final double precioVenta;
  final double stock;
  final double stockMinimo;
  final int categoriaId;
  final int marcaId;
  final int unidadMedidaId;
  final bool activo;
  const ProductosTableData({
    required this.id,
    required this.codigo,
    this.codigoBarras,
    required this.nombre,
    this.descripcion,
    required this.precioCompra,
    required this.precioVenta,
    required this.stock,
    required this.stockMinimo,
    required this.categoriaId,
    required this.marcaId,
    required this.unidadMedidaId,
    required this.activo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['codigo'] = Variable<String>(codigo);
    if (!nullToAbsent || codigoBarras != null) {
      map['codigo_barras'] = Variable<String>(codigoBarras);
    }
    map['nombre'] = Variable<String>(nombre);
    if (!nullToAbsent || descripcion != null) {
      map['descripcion'] = Variable<String>(descripcion);
    }
    map['precio_compra'] = Variable<double>(precioCompra);
    map['precio_venta'] = Variable<double>(precioVenta);
    map['stock'] = Variable<double>(stock);
    map['stock_minimo'] = Variable<double>(stockMinimo);
    map['categoria_id'] = Variable<int>(categoriaId);
    map['marca_id'] = Variable<int>(marcaId);
    map['unidad_medida_id'] = Variable<int>(unidadMedidaId);
    map['activo'] = Variable<bool>(activo);
    return map;
  }

  ProductosTableCompanion toCompanion(bool nullToAbsent) {
    return ProductosTableCompanion(
      id: Value(id),
      codigo: Value(codigo),
      codigoBarras: codigoBarras == null && nullToAbsent
          ? const Value.absent()
          : Value(codigoBarras),
      nombre: Value(nombre),
      descripcion: descripcion == null && nullToAbsent
          ? const Value.absent()
          : Value(descripcion),
      precioCompra: Value(precioCompra),
      precioVenta: Value(precioVenta),
      stock: Value(stock),
      stockMinimo: Value(stockMinimo),
      categoriaId: Value(categoriaId),
      marcaId: Value(marcaId),
      unidadMedidaId: Value(unidadMedidaId),
      activo: Value(activo),
    );
  }

  factory ProductosTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductosTableData(
      id: serializer.fromJson<int>(json['id']),
      codigo: serializer.fromJson<String>(json['codigo']),
      codigoBarras: serializer.fromJson<String?>(json['codigoBarras']),
      nombre: serializer.fromJson<String>(json['nombre']),
      descripcion: serializer.fromJson<String?>(json['descripcion']),
      precioCompra: serializer.fromJson<double>(json['precioCompra']),
      precioVenta: serializer.fromJson<double>(json['precioVenta']),
      stock: serializer.fromJson<double>(json['stock']),
      stockMinimo: serializer.fromJson<double>(json['stockMinimo']),
      categoriaId: serializer.fromJson<int>(json['categoriaId']),
      marcaId: serializer.fromJson<int>(json['marcaId']),
      unidadMedidaId: serializer.fromJson<int>(json['unidadMedidaId']),
      activo: serializer.fromJson<bool>(json['activo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'codigo': serializer.toJson<String>(codigo),
      'codigoBarras': serializer.toJson<String?>(codigoBarras),
      'nombre': serializer.toJson<String>(nombre),
      'descripcion': serializer.toJson<String?>(descripcion),
      'precioCompra': serializer.toJson<double>(precioCompra),
      'precioVenta': serializer.toJson<double>(precioVenta),
      'stock': serializer.toJson<double>(stock),
      'stockMinimo': serializer.toJson<double>(stockMinimo),
      'categoriaId': serializer.toJson<int>(categoriaId),
      'marcaId': serializer.toJson<int>(marcaId),
      'unidadMedidaId': serializer.toJson<int>(unidadMedidaId),
      'activo': serializer.toJson<bool>(activo),
    };
  }

  ProductosTableData copyWith({
    int? id,
    String? codigo,
    Value<String?> codigoBarras = const Value.absent(),
    String? nombre,
    Value<String?> descripcion = const Value.absent(),
    double? precioCompra,
    double? precioVenta,
    double? stock,
    double? stockMinimo,
    int? categoriaId,
    int? marcaId,
    int? unidadMedidaId,
    bool? activo,
  }) => ProductosTableData(
    id: id ?? this.id,
    codigo: codigo ?? this.codigo,
    codigoBarras: codigoBarras.present ? codigoBarras.value : this.codigoBarras,
    nombre: nombre ?? this.nombre,
    descripcion: descripcion.present ? descripcion.value : this.descripcion,
    precioCompra: precioCompra ?? this.precioCompra,
    precioVenta: precioVenta ?? this.precioVenta,
    stock: stock ?? this.stock,
    stockMinimo: stockMinimo ?? this.stockMinimo,
    categoriaId: categoriaId ?? this.categoriaId,
    marcaId: marcaId ?? this.marcaId,
    unidadMedidaId: unidadMedidaId ?? this.unidadMedidaId,
    activo: activo ?? this.activo,
  );
  ProductosTableData copyWithCompanion(ProductosTableCompanion data) {
    return ProductosTableData(
      id: data.id.present ? data.id.value : this.id,
      codigo: data.codigo.present ? data.codigo.value : this.codigo,
      codigoBarras: data.codigoBarras.present
          ? data.codigoBarras.value
          : this.codigoBarras,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      descripcion: data.descripcion.present
          ? data.descripcion.value
          : this.descripcion,
      precioCompra: data.precioCompra.present
          ? data.precioCompra.value
          : this.precioCompra,
      precioVenta: data.precioVenta.present
          ? data.precioVenta.value
          : this.precioVenta,
      stock: data.stock.present ? data.stock.value : this.stock,
      stockMinimo: data.stockMinimo.present
          ? data.stockMinimo.value
          : this.stockMinimo,
      categoriaId: data.categoriaId.present
          ? data.categoriaId.value
          : this.categoriaId,
      marcaId: data.marcaId.present ? data.marcaId.value : this.marcaId,
      unidadMedidaId: data.unidadMedidaId.present
          ? data.unidadMedidaId.value
          : this.unidadMedidaId,
      activo: data.activo.present ? data.activo.value : this.activo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductosTableData(')
          ..write('id: $id, ')
          ..write('codigo: $codigo, ')
          ..write('codigoBarras: $codigoBarras, ')
          ..write('nombre: $nombre, ')
          ..write('descripcion: $descripcion, ')
          ..write('precioCompra: $precioCompra, ')
          ..write('precioVenta: $precioVenta, ')
          ..write('stock: $stock, ')
          ..write('stockMinimo: $stockMinimo, ')
          ..write('categoriaId: $categoriaId, ')
          ..write('marcaId: $marcaId, ')
          ..write('unidadMedidaId: $unidadMedidaId, ')
          ..write('activo: $activo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    codigo,
    codigoBarras,
    nombre,
    descripcion,
    precioCompra,
    precioVenta,
    stock,
    stockMinimo,
    categoriaId,
    marcaId,
    unidadMedidaId,
    activo,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductosTableData &&
          other.id == this.id &&
          other.codigo == this.codigo &&
          other.codigoBarras == this.codigoBarras &&
          other.nombre == this.nombre &&
          other.descripcion == this.descripcion &&
          other.precioCompra == this.precioCompra &&
          other.precioVenta == this.precioVenta &&
          other.stock == this.stock &&
          other.stockMinimo == this.stockMinimo &&
          other.categoriaId == this.categoriaId &&
          other.marcaId == this.marcaId &&
          other.unidadMedidaId == this.unidadMedidaId &&
          other.activo == this.activo);
}

class ProductosTableCompanion extends UpdateCompanion<ProductosTableData> {
  final Value<int> id;
  final Value<String> codigo;
  final Value<String?> codigoBarras;
  final Value<String> nombre;
  final Value<String?> descripcion;
  final Value<double> precioCompra;
  final Value<double> precioVenta;
  final Value<double> stock;
  final Value<double> stockMinimo;
  final Value<int> categoriaId;
  final Value<int> marcaId;
  final Value<int> unidadMedidaId;
  final Value<bool> activo;
  const ProductosTableCompanion({
    this.id = const Value.absent(),
    this.codigo = const Value.absent(),
    this.codigoBarras = const Value.absent(),
    this.nombre = const Value.absent(),
    this.descripcion = const Value.absent(),
    this.precioCompra = const Value.absent(),
    this.precioVenta = const Value.absent(),
    this.stock = const Value.absent(),
    this.stockMinimo = const Value.absent(),
    this.categoriaId = const Value.absent(),
    this.marcaId = const Value.absent(),
    this.unidadMedidaId = const Value.absent(),
    this.activo = const Value.absent(),
  });
  ProductosTableCompanion.insert({
    this.id = const Value.absent(),
    required String codigo,
    this.codigoBarras = const Value.absent(),
    required String nombre,
    this.descripcion = const Value.absent(),
    required double precioCompra,
    required double precioVenta,
    required double stock,
    required double stockMinimo,
    required int categoriaId,
    required int marcaId,
    required int unidadMedidaId,
    this.activo = const Value.absent(),
  }) : codigo = Value(codigo),
       nombre = Value(nombre),
       precioCompra = Value(precioCompra),
       precioVenta = Value(precioVenta),
       stock = Value(stock),
       stockMinimo = Value(stockMinimo),
       categoriaId = Value(categoriaId),
       marcaId = Value(marcaId),
       unidadMedidaId = Value(unidadMedidaId);
  static Insertable<ProductosTableData> custom({
    Expression<int>? id,
    Expression<String>? codigo,
    Expression<String>? codigoBarras,
    Expression<String>? nombre,
    Expression<String>? descripcion,
    Expression<double>? precioCompra,
    Expression<double>? precioVenta,
    Expression<double>? stock,
    Expression<double>? stockMinimo,
    Expression<int>? categoriaId,
    Expression<int>? marcaId,
    Expression<int>? unidadMedidaId,
    Expression<bool>? activo,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (codigo != null) 'codigo': codigo,
      if (codigoBarras != null) 'codigo_barras': codigoBarras,
      if (nombre != null) 'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      if (precioCompra != null) 'precio_compra': precioCompra,
      if (precioVenta != null) 'precio_venta': precioVenta,
      if (stock != null) 'stock': stock,
      if (stockMinimo != null) 'stock_minimo': stockMinimo,
      if (categoriaId != null) 'categoria_id': categoriaId,
      if (marcaId != null) 'marca_id': marcaId,
      if (unidadMedidaId != null) 'unidad_medida_id': unidadMedidaId,
      if (activo != null) 'activo': activo,
    });
  }

  ProductosTableCompanion copyWith({
    Value<int>? id,
    Value<String>? codigo,
    Value<String?>? codigoBarras,
    Value<String>? nombre,
    Value<String?>? descripcion,
    Value<double>? precioCompra,
    Value<double>? precioVenta,
    Value<double>? stock,
    Value<double>? stockMinimo,
    Value<int>? categoriaId,
    Value<int>? marcaId,
    Value<int>? unidadMedidaId,
    Value<bool>? activo,
  }) {
    return ProductosTableCompanion(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precioCompra: precioCompra ?? this.precioCompra,
      precioVenta: precioVenta ?? this.precioVenta,
      stock: stock ?? this.stock,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      categoriaId: categoriaId ?? this.categoriaId,
      marcaId: marcaId ?? this.marcaId,
      unidadMedidaId: unidadMedidaId ?? this.unidadMedidaId,
      activo: activo ?? this.activo,
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
    if (codigoBarras.present) {
      map['codigo_barras'] = Variable<String>(codigoBarras.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (descripcion.present) {
      map['descripcion'] = Variable<String>(descripcion.value);
    }
    if (precioCompra.present) {
      map['precio_compra'] = Variable<double>(precioCompra.value);
    }
    if (precioVenta.present) {
      map['precio_venta'] = Variable<double>(precioVenta.value);
    }
    if (stock.present) {
      map['stock'] = Variable<double>(stock.value);
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
    if (unidadMedidaId.present) {
      map['unidad_medida_id'] = Variable<int>(unidadMedidaId.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductosTableCompanion(')
          ..write('id: $id, ')
          ..write('codigo: $codigo, ')
          ..write('codigoBarras: $codigoBarras, ')
          ..write('nombre: $nombre, ')
          ..write('descripcion: $descripcion, ')
          ..write('precioCompra: $precioCompra, ')
          ..write('precioVenta: $precioVenta, ')
          ..write('stock: $stock, ')
          ..write('stockMinimo: $stockMinimo, ')
          ..write('categoriaId: $categoriaId, ')
          ..write('marcaId: $marcaId, ')
          ..write('unidadMedidaId: $unidadMedidaId, ')
          ..write('activo: $activo')
          ..write(')'))
        .toString();
  }
}

class $EntradasTableTable extends EntradasTable
    with TableInfo<$EntradasTableTable, EntradasTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntradasTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _cantidadMeta = const VerificationMeta(
    'cantidad',
  );
  @override
  late final GeneratedColumn<double> cantidad = GeneratedColumn<double>(
    'cantidad',
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usuarioMeta = const VerificationMeta(
    'usuario',
  );
  @override
  late final GeneratedColumn<String> usuario = GeneratedColumn<String>(
    'usuario',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<DateTime> fecha = GeneratedColumn<DateTime>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productoId,
    cantidad,
    motivo,
    usuario,
    fecha,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entradas_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntradasTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('producto_id')) {
      context.handle(
        _productoIdMeta,
        productoId.isAcceptableOrUnknown(data['producto_id']!, _productoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productoIdMeta);
    }
    if (data.containsKey('cantidad')) {
      context.handle(
        _cantidadMeta,
        cantidad.isAcceptableOrUnknown(data['cantidad']!, _cantidadMeta),
      );
    } else if (isInserting) {
      context.missing(_cantidadMeta);
    }
    if (data.containsKey('motivo')) {
      context.handle(
        _motivoMeta,
        motivo.isAcceptableOrUnknown(data['motivo']!, _motivoMeta),
      );
    } else if (isInserting) {
      context.missing(_motivoMeta);
    }
    if (data.containsKey('usuario')) {
      context.handle(
        _usuarioMeta,
        usuario.isAcceptableOrUnknown(data['usuario']!, _usuarioMeta),
      );
    } else if (isInserting) {
      context.missing(_usuarioMeta);
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EntradasTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntradasTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      productoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}producto_id'],
      )!,
      cantidad: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cantidad'],
      )!,
      motivo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}motivo'],
      )!,
      usuario: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}usuario'],
      )!,
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha'],
      )!,
    );
  }

  @override
  $EntradasTableTable createAlias(String alias) {
    return $EntradasTableTable(attachedDatabase, alias);
  }
}

class EntradasTableData extends DataClass
    implements Insertable<EntradasTableData> {
  final int id;
  final int productoId;
  final double cantidad;
  final String motivo;
  final String usuario;
  final DateTime fecha;
  const EntradasTableData({
    required this.id,
    required this.productoId,
    required this.cantidad,
    required this.motivo,
    required this.usuario,
    required this.fecha,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['producto_id'] = Variable<int>(productoId);
    map['cantidad'] = Variable<double>(cantidad);
    map['motivo'] = Variable<String>(motivo);
    map['usuario'] = Variable<String>(usuario);
    map['fecha'] = Variable<DateTime>(fecha);
    return map;
  }

  EntradasTableCompanion toCompanion(bool nullToAbsent) {
    return EntradasTableCompanion(
      id: Value(id),
      productoId: Value(productoId),
      cantidad: Value(cantidad),
      motivo: Value(motivo),
      usuario: Value(usuario),
      fecha: Value(fecha),
    );
  }

  factory EntradasTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntradasTableData(
      id: serializer.fromJson<int>(json['id']),
      productoId: serializer.fromJson<int>(json['productoId']),
      cantidad: serializer.fromJson<double>(json['cantidad']),
      motivo: serializer.fromJson<String>(json['motivo']),
      usuario: serializer.fromJson<String>(json['usuario']),
      fecha: serializer.fromJson<DateTime>(json['fecha']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'productoId': serializer.toJson<int>(productoId),
      'cantidad': serializer.toJson<double>(cantidad),
      'motivo': serializer.toJson<String>(motivo),
      'usuario': serializer.toJson<String>(usuario),
      'fecha': serializer.toJson<DateTime>(fecha),
    };
  }

  EntradasTableData copyWith({
    int? id,
    int? productoId,
    double? cantidad,
    String? motivo,
    String? usuario,
    DateTime? fecha,
  }) => EntradasTableData(
    id: id ?? this.id,
    productoId: productoId ?? this.productoId,
    cantidad: cantidad ?? this.cantidad,
    motivo: motivo ?? this.motivo,
    usuario: usuario ?? this.usuario,
    fecha: fecha ?? this.fecha,
  );
  EntradasTableData copyWithCompanion(EntradasTableCompanion data) {
    return EntradasTableData(
      id: data.id.present ? data.id.value : this.id,
      productoId: data.productoId.present
          ? data.productoId.value
          : this.productoId,
      cantidad: data.cantidad.present ? data.cantidad.value : this.cantidad,
      motivo: data.motivo.present ? data.motivo.value : this.motivo,
      usuario: data.usuario.present ? data.usuario.value : this.usuario,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntradasTableData(')
          ..write('id: $id, ')
          ..write('productoId: $productoId, ')
          ..write('cantidad: $cantidad, ')
          ..write('motivo: $motivo, ')
          ..write('usuario: $usuario, ')
          ..write('fecha: $fecha')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, productoId, cantidad, motivo, usuario, fecha);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntradasTableData &&
          other.id == this.id &&
          other.productoId == this.productoId &&
          other.cantidad == this.cantidad &&
          other.motivo == this.motivo &&
          other.usuario == this.usuario &&
          other.fecha == this.fecha);
}

class EntradasTableCompanion extends UpdateCompanion<EntradasTableData> {
  final Value<int> id;
  final Value<int> productoId;
  final Value<double> cantidad;
  final Value<String> motivo;
  final Value<String> usuario;
  final Value<DateTime> fecha;
  const EntradasTableCompanion({
    this.id = const Value.absent(),
    this.productoId = const Value.absent(),
    this.cantidad = const Value.absent(),
    this.motivo = const Value.absent(),
    this.usuario = const Value.absent(),
    this.fecha = const Value.absent(),
  });
  EntradasTableCompanion.insert({
    this.id = const Value.absent(),
    required int productoId,
    required double cantidad,
    required String motivo,
    required String usuario,
    required DateTime fecha,
  }) : productoId = Value(productoId),
       cantidad = Value(cantidad),
       motivo = Value(motivo),
       usuario = Value(usuario),
       fecha = Value(fecha);
  static Insertable<EntradasTableData> custom({
    Expression<int>? id,
    Expression<int>? productoId,
    Expression<double>? cantidad,
    Expression<String>? motivo,
    Expression<String>? usuario,
    Expression<DateTime>? fecha,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productoId != null) 'producto_id': productoId,
      if (cantidad != null) 'cantidad': cantidad,
      if (motivo != null) 'motivo': motivo,
      if (usuario != null) 'usuario': usuario,
      if (fecha != null) 'fecha': fecha,
    });
  }

  EntradasTableCompanion copyWith({
    Value<int>? id,
    Value<int>? productoId,
    Value<double>? cantidad,
    Value<String>? motivo,
    Value<String>? usuario,
    Value<DateTime>? fecha,
  }) {
    return EntradasTableCompanion(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      cantidad: cantidad ?? this.cantidad,
      motivo: motivo ?? this.motivo,
      usuario: usuario ?? this.usuario,
      fecha: fecha ?? this.fecha,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (productoId.present) {
      map['producto_id'] = Variable<int>(productoId.value);
    }
    if (cantidad.present) {
      map['cantidad'] = Variable<double>(cantidad.value);
    }
    if (motivo.present) {
      map['motivo'] = Variable<String>(motivo.value);
    }
    if (usuario.present) {
      map['usuario'] = Variable<String>(usuario.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<DateTime>(fecha.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntradasTableCompanion(')
          ..write('id: $id, ')
          ..write('productoId: $productoId, ')
          ..write('cantidad: $cantidad, ')
          ..write('motivo: $motivo, ')
          ..write('usuario: $usuario, ')
          ..write('fecha: $fecha')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ClientesTableTable clientesTable = $ClientesTableTable(this);
  late final $ConfiguracionTableTable configuracionTable =
      $ConfiguracionTableTable(this);
  late final $ProductosTableTable productosTable = $ProductosTableTable(this);
  late final $EntradasTableTable entradasTable = $EntradasTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    clientesTable,
    configuracionTable,
    productosTable,
    entradasTable,
  ];
}

typedef $$ClientesTableTableCreateCompanionBuilder =
    ClientesTableCompanion Function({
      Value<int> id,
      required String codigo,
      required String nombre,
      required String rncCedula,
      required String telefono,
      required String correo,
      required String direccion,
      Value<bool> activo,
    });
typedef $$ClientesTableTableUpdateCompanionBuilder =
    ClientesTableCompanion Function({
      Value<int> id,
      Value<String> codigo,
      Value<String> nombre,
      Value<String> rncCedula,
      Value<String> telefono,
      Value<String> correo,
      Value<String> direccion,
      Value<bool> activo,
    });

class $$ClientesTableTableFilterComposer
    extends Composer<_$AppDatabase, $ClientesTableTable> {
  $$ClientesTableTableFilterComposer({
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

  ColumnFilters<String> get rncCedula => $composableBuilder(
    column: $table.rncCedula,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get telefono => $composableBuilder(
    column: $table.telefono,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correo => $composableBuilder(
    column: $table.correo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direccion => $composableBuilder(
    column: $table.direccion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClientesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ClientesTableTable> {
  $$ClientesTableTableOrderingComposer({
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

  ColumnOrderings<String> get rncCedula => $composableBuilder(
    column: $table.rncCedula,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get telefono => $composableBuilder(
    column: $table.telefono,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correo => $composableBuilder(
    column: $table.correo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direccion => $composableBuilder(
    column: $table.direccion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClientesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClientesTableTable> {
  $$ClientesTableTableAnnotationComposer({
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

  GeneratedColumn<String> get rncCedula =>
      $composableBuilder(column: $table.rncCedula, builder: (column) => column);

  GeneratedColumn<String> get telefono =>
      $composableBuilder(column: $table.telefono, builder: (column) => column);

  GeneratedColumn<String> get correo =>
      $composableBuilder(column: $table.correo, builder: (column) => column);

  GeneratedColumn<String> get direccion =>
      $composableBuilder(column: $table.direccion, builder: (column) => column);

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);
}

class $$ClientesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClientesTableTable,
          ClientesTableData,
          $$ClientesTableTableFilterComposer,
          $$ClientesTableTableOrderingComposer,
          $$ClientesTableTableAnnotationComposer,
          $$ClientesTableTableCreateCompanionBuilder,
          $$ClientesTableTableUpdateCompanionBuilder,
          (
            ClientesTableData,
            BaseReferences<
              _$AppDatabase,
              $ClientesTableTable,
              ClientesTableData
            >,
          ),
          ClientesTableData,
          PrefetchHooks Function()
        > {
  $$ClientesTableTableTableManager(_$AppDatabase db, $ClientesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClientesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClientesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClientesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> codigo = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String> rncCedula = const Value.absent(),
                Value<String> telefono = const Value.absent(),
                Value<String> correo = const Value.absent(),
                Value<String> direccion = const Value.absent(),
                Value<bool> activo = const Value.absent(),
              }) => ClientesTableCompanion(
                id: id,
                codigo: codigo,
                nombre: nombre,
                rncCedula: rncCedula,
                telefono: telefono,
                correo: correo,
                direccion: direccion,
                activo: activo,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String codigo,
                required String nombre,
                required String rncCedula,
                required String telefono,
                required String correo,
                required String direccion,
                Value<bool> activo = const Value.absent(),
              }) => ClientesTableCompanion.insert(
                id: id,
                codigo: codigo,
                nombre: nombre,
                rncCedula: rncCedula,
                telefono: telefono,
                correo: correo,
                direccion: direccion,
                activo: activo,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClientesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClientesTableTable,
      ClientesTableData,
      $$ClientesTableTableFilterComposer,
      $$ClientesTableTableOrderingComposer,
      $$ClientesTableTableAnnotationComposer,
      $$ClientesTableTableCreateCompanionBuilder,
      $$ClientesTableTableUpdateCompanionBuilder,
      (
        ClientesTableData,
        BaseReferences<_$AppDatabase, $ClientesTableTable, ClientesTableData>,
      ),
      ClientesTableData,
      PrefetchHooks Function()
    >;
typedef $$ConfiguracionTableTableCreateCompanionBuilder =
    ConfiguracionTableCompanion Function({
      Value<int> id,
      required String nombreNegocio,
      required String rncCedula,
      required String moneda,
      required String formatoFecha,
      required double impuestoPorcentaje,
      required String idioma,
    });
typedef $$ConfiguracionTableTableUpdateCompanionBuilder =
    ConfiguracionTableCompanion Function({
      Value<int> id,
      Value<String> nombreNegocio,
      Value<String> rncCedula,
      Value<String> moneda,
      Value<String> formatoFecha,
      Value<double> impuestoPorcentaje,
      Value<String> idioma,
    });

class $$ConfiguracionTableTableFilterComposer
    extends Composer<_$AppDatabase, $ConfiguracionTableTable> {
  $$ConfiguracionTableTableFilterComposer({
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

  ColumnFilters<String> get nombreNegocio => $composableBuilder(
    column: $table.nombreNegocio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rncCedula => $composableBuilder(
    column: $table.rncCedula,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get moneda => $composableBuilder(
    column: $table.moneda,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get formatoFecha => $composableBuilder(
    column: $table.formatoFecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get impuestoPorcentaje => $composableBuilder(
    column: $table.impuestoPorcentaje,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idioma => $composableBuilder(
    column: $table.idioma,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConfiguracionTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ConfiguracionTableTable> {
  $$ConfiguracionTableTableOrderingComposer({
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

  ColumnOrderings<String> get nombreNegocio => $composableBuilder(
    column: $table.nombreNegocio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rncCedula => $composableBuilder(
    column: $table.rncCedula,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get moneda => $composableBuilder(
    column: $table.moneda,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get formatoFecha => $composableBuilder(
    column: $table.formatoFecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get impuestoPorcentaje => $composableBuilder(
    column: $table.impuestoPorcentaje,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idioma => $composableBuilder(
    column: $table.idioma,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConfiguracionTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConfiguracionTableTable> {
  $$ConfiguracionTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombreNegocio => $composableBuilder(
    column: $table.nombreNegocio,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rncCedula =>
      $composableBuilder(column: $table.rncCedula, builder: (column) => column);

  GeneratedColumn<String> get moneda =>
      $composableBuilder(column: $table.moneda, builder: (column) => column);

  GeneratedColumn<String> get formatoFecha => $composableBuilder(
    column: $table.formatoFecha,
    builder: (column) => column,
  );

  GeneratedColumn<double> get impuestoPorcentaje => $composableBuilder(
    column: $table.impuestoPorcentaje,
    builder: (column) => column,
  );

  GeneratedColumn<String> get idioma =>
      $composableBuilder(column: $table.idioma, builder: (column) => column);
}

class $$ConfiguracionTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConfiguracionTableTable,
          ConfiguracionTableData,
          $$ConfiguracionTableTableFilterComposer,
          $$ConfiguracionTableTableOrderingComposer,
          $$ConfiguracionTableTableAnnotationComposer,
          $$ConfiguracionTableTableCreateCompanionBuilder,
          $$ConfiguracionTableTableUpdateCompanionBuilder,
          (
            ConfiguracionTableData,
            BaseReferences<
              _$AppDatabase,
              $ConfiguracionTableTable,
              ConfiguracionTableData
            >,
          ),
          ConfiguracionTableData,
          PrefetchHooks Function()
        > {
  $$ConfiguracionTableTableTableManager(
    _$AppDatabase db,
    $ConfiguracionTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConfiguracionTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConfiguracionTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConfiguracionTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nombreNegocio = const Value.absent(),
                Value<String> rncCedula = const Value.absent(),
                Value<String> moneda = const Value.absent(),
                Value<String> formatoFecha = const Value.absent(),
                Value<double> impuestoPorcentaje = const Value.absent(),
                Value<String> idioma = const Value.absent(),
              }) => ConfiguracionTableCompanion(
                id: id,
                nombreNegocio: nombreNegocio,
                rncCedula: rncCedula,
                moneda: moneda,
                formatoFecha: formatoFecha,
                impuestoPorcentaje: impuestoPorcentaje,
                idioma: idioma,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nombreNegocio,
                required String rncCedula,
                required String moneda,
                required String formatoFecha,
                required double impuestoPorcentaje,
                required String idioma,
              }) => ConfiguracionTableCompanion.insert(
                id: id,
                nombreNegocio: nombreNegocio,
                rncCedula: rncCedula,
                moneda: moneda,
                formatoFecha: formatoFecha,
                impuestoPorcentaje: impuestoPorcentaje,
                idioma: idioma,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConfiguracionTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConfiguracionTableTable,
      ConfiguracionTableData,
      $$ConfiguracionTableTableFilterComposer,
      $$ConfiguracionTableTableOrderingComposer,
      $$ConfiguracionTableTableAnnotationComposer,
      $$ConfiguracionTableTableCreateCompanionBuilder,
      $$ConfiguracionTableTableUpdateCompanionBuilder,
      (
        ConfiguracionTableData,
        BaseReferences<
          _$AppDatabase,
          $ConfiguracionTableTable,
          ConfiguracionTableData
        >,
      ),
      ConfiguracionTableData,
      PrefetchHooks Function()
    >;
typedef $$ProductosTableTableCreateCompanionBuilder =
    ProductosTableCompanion Function({
      Value<int> id,
      required String codigo,
      Value<String?> codigoBarras,
      required String nombre,
      Value<String?> descripcion,
      required double precioCompra,
      required double precioVenta,
      required double stock,
      required double stockMinimo,
      required int categoriaId,
      required int marcaId,
      required int unidadMedidaId,
      Value<bool> activo,
    });
typedef $$ProductosTableTableUpdateCompanionBuilder =
    ProductosTableCompanion Function({
      Value<int> id,
      Value<String> codigo,
      Value<String?> codigoBarras,
      Value<String> nombre,
      Value<String?> descripcion,
      Value<double> precioCompra,
      Value<double> precioVenta,
      Value<double> stock,
      Value<double> stockMinimo,
      Value<int> categoriaId,
      Value<int> marcaId,
      Value<int> unidadMedidaId,
      Value<bool> activo,
    });

class $$ProductosTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProductosTableTable> {
  $$ProductosTableTableFilterComposer({
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

  ColumnFilters<String> get codigoBarras => $composableBuilder(
    column: $table.codigoBarras,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
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

  ColumnFilters<double> get stock => $composableBuilder(
    column: $table.stock,
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

  ColumnFilters<int> get unidadMedidaId => $composableBuilder(
    column: $table.unidadMedidaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductosTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductosTableTable> {
  $$ProductosTableTableOrderingComposer({
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

  ColumnOrderings<String> get codigoBarras => $composableBuilder(
    column: $table.codigoBarras,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
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

  ColumnOrderings<double> get stock => $composableBuilder(
    column: $table.stock,
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

  ColumnOrderings<int> get unidadMedidaId => $composableBuilder(
    column: $table.unidadMedidaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductosTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductosTableTable> {
  $$ProductosTableTableAnnotationComposer({
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

  GeneratedColumn<String> get codigoBarras => $composableBuilder(
    column: $table.codigoBarras,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => column,
  );

  GeneratedColumn<double> get precioCompra => $composableBuilder(
    column: $table.precioCompra,
    builder: (column) => column,
  );

  GeneratedColumn<double> get precioVenta => $composableBuilder(
    column: $table.precioVenta,
    builder: (column) => column,
  );

  GeneratedColumn<double> get stock =>
      $composableBuilder(column: $table.stock, builder: (column) => column);

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

  GeneratedColumn<int> get unidadMedidaId => $composableBuilder(
    column: $table.unidadMedidaId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);
}

class $$ProductosTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductosTableTable,
          ProductosTableData,
          $$ProductosTableTableFilterComposer,
          $$ProductosTableTableOrderingComposer,
          $$ProductosTableTableAnnotationComposer,
          $$ProductosTableTableCreateCompanionBuilder,
          $$ProductosTableTableUpdateCompanionBuilder,
          (
            ProductosTableData,
            BaseReferences<
              _$AppDatabase,
              $ProductosTableTable,
              ProductosTableData
            >,
          ),
          ProductosTableData,
          PrefetchHooks Function()
        > {
  $$ProductosTableTableTableManager(
    _$AppDatabase db,
    $ProductosTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductosTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductosTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductosTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> codigo = const Value.absent(),
                Value<String?> codigoBarras = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String?> descripcion = const Value.absent(),
                Value<double> precioCompra = const Value.absent(),
                Value<double> precioVenta = const Value.absent(),
                Value<double> stock = const Value.absent(),
                Value<double> stockMinimo = const Value.absent(),
                Value<int> categoriaId = const Value.absent(),
                Value<int> marcaId = const Value.absent(),
                Value<int> unidadMedidaId = const Value.absent(),
                Value<bool> activo = const Value.absent(),
              }) => ProductosTableCompanion(
                id: id,
                codigo: codigo,
                codigoBarras: codigoBarras,
                nombre: nombre,
                descripcion: descripcion,
                precioCompra: precioCompra,
                precioVenta: precioVenta,
                stock: stock,
                stockMinimo: stockMinimo,
                categoriaId: categoriaId,
                marcaId: marcaId,
                unidadMedidaId: unidadMedidaId,
                activo: activo,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String codigo,
                Value<String?> codigoBarras = const Value.absent(),
                required String nombre,
                Value<String?> descripcion = const Value.absent(),
                required double precioCompra,
                required double precioVenta,
                required double stock,
                required double stockMinimo,
                required int categoriaId,
                required int marcaId,
                required int unidadMedidaId,
                Value<bool> activo = const Value.absent(),
              }) => ProductosTableCompanion.insert(
                id: id,
                codigo: codigo,
                codigoBarras: codigoBarras,
                nombre: nombre,
                descripcion: descripcion,
                precioCompra: precioCompra,
                precioVenta: precioVenta,
                stock: stock,
                stockMinimo: stockMinimo,
                categoriaId: categoriaId,
                marcaId: marcaId,
                unidadMedidaId: unidadMedidaId,
                activo: activo,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductosTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductosTableTable,
      ProductosTableData,
      $$ProductosTableTableFilterComposer,
      $$ProductosTableTableOrderingComposer,
      $$ProductosTableTableAnnotationComposer,
      $$ProductosTableTableCreateCompanionBuilder,
      $$ProductosTableTableUpdateCompanionBuilder,
      (
        ProductosTableData,
        BaseReferences<_$AppDatabase, $ProductosTableTable, ProductosTableData>,
      ),
      ProductosTableData,
      PrefetchHooks Function()
    >;
typedef $$EntradasTableTableCreateCompanionBuilder =
    EntradasTableCompanion Function({
      Value<int> id,
      required int productoId,
      required double cantidad,
      required String motivo,
      required String usuario,
      required DateTime fecha,
    });
typedef $$EntradasTableTableUpdateCompanionBuilder =
    EntradasTableCompanion Function({
      Value<int> id,
      Value<int> productoId,
      Value<double> cantidad,
      Value<String> motivo,
      Value<String> usuario,
      Value<DateTime> fecha,
    });

class $$EntradasTableTableFilterComposer
    extends Composer<_$AppDatabase, $EntradasTableTable> {
  $$EntradasTableTableFilterComposer({
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

  ColumnFilters<int> get productoId => $composableBuilder(
    column: $table.productoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cantidad => $composableBuilder(
    column: $table.cantidad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get motivo => $composableBuilder(
    column: $table.motivo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get usuario => $composableBuilder(
    column: $table.usuario,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EntradasTableTableOrderingComposer
    extends Composer<_$AppDatabase, $EntradasTableTable> {
  $$EntradasTableTableOrderingComposer({
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

  ColumnOrderings<int> get productoId => $composableBuilder(
    column: $table.productoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cantidad => $composableBuilder(
    column: $table.cantidad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motivo => $composableBuilder(
    column: $table.motivo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get usuario => $composableBuilder(
    column: $table.usuario,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EntradasTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntradasTableTable> {
  $$EntradasTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get productoId => $composableBuilder(
    column: $table.productoId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cantidad =>
      $composableBuilder(column: $table.cantidad, builder: (column) => column);

  GeneratedColumn<String> get motivo =>
      $composableBuilder(column: $table.motivo, builder: (column) => column);

  GeneratedColumn<String> get usuario =>
      $composableBuilder(column: $table.usuario, builder: (column) => column);

  GeneratedColumn<DateTime> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);
}

class $$EntradasTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntradasTableTable,
          EntradasTableData,
          $$EntradasTableTableFilterComposer,
          $$EntradasTableTableOrderingComposer,
          $$EntradasTableTableAnnotationComposer,
          $$EntradasTableTableCreateCompanionBuilder,
          $$EntradasTableTableUpdateCompanionBuilder,
          (
            EntradasTableData,
            BaseReferences<
              _$AppDatabase,
              $EntradasTableTable,
              EntradasTableData
            >,
          ),
          EntradasTableData,
          PrefetchHooks Function()
        > {
  $$EntradasTableTableTableManager(_$AppDatabase db, $EntradasTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntradasTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntradasTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntradasTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> productoId = const Value.absent(),
                Value<double> cantidad = const Value.absent(),
                Value<String> motivo = const Value.absent(),
                Value<String> usuario = const Value.absent(),
                Value<DateTime> fecha = const Value.absent(),
              }) => EntradasTableCompanion(
                id: id,
                productoId: productoId,
                cantidad: cantidad,
                motivo: motivo,
                usuario: usuario,
                fecha: fecha,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int productoId,
                required double cantidad,
                required String motivo,
                required String usuario,
                required DateTime fecha,
              }) => EntradasTableCompanion.insert(
                id: id,
                productoId: productoId,
                cantidad: cantidad,
                motivo: motivo,
                usuario: usuario,
                fecha: fecha,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EntradasTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntradasTableTable,
      EntradasTableData,
      $$EntradasTableTableFilterComposer,
      $$EntradasTableTableOrderingComposer,
      $$EntradasTableTableAnnotationComposer,
      $$EntradasTableTableCreateCompanionBuilder,
      $$EntradasTableTableUpdateCompanionBuilder,
      (
        EntradasTableData,
        BaseReferences<_$AppDatabase, $EntradasTableTable, EntradasTableData>,
      ),
      EntradasTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ClientesTableTableTableManager get clientesTable =>
      $$ClientesTableTableTableManager(_db, _db.clientesTable);
  $$ConfiguracionTableTableTableManager get configuracionTable =>
      $$ConfiguracionTableTableTableManager(_db, _db.configuracionTable);
  $$ProductosTableTableTableManager get productosTable =>
      $$ProductosTableTableTableManager(_db, _db.productosTable);
  $$EntradasTableTableTableManager get entradasTable =>
      $$EntradasTableTableTableManager(_db, _db.entradasTable);
}
