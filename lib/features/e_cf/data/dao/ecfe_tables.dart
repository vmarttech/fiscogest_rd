import 'package:drift/drift.dart';

/// Config global del módulo e-CF (una fila típica).
class EcfeConfigTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  BoolColumn get habilitado => boolean().withDefault(const Constant(false))();

  /// deshabilitado | precertificacion | certificacion | produccion
  TextColumn get ambiente =>
      text().withDefault(const Constant('deshabilitado'))();
  TextColumn get rncEmisor => text().withDefault(const Constant(''))();
  TextColumn get razonSocialEmisor => text().withDefault(const Constant(''))();
  TextColumn get rutaCertificado => text().withDefault(const Constant(''))();
  TextColumn get aliasCertificado => text().withDefault(const Constant(''))();
  TextColumn get claveCertificado => text().withDefault(const Constant(''))();
  TextColumn get xsdVersion => text().withDefault(const Constant(''))();
  DateTimeColumn get actualizadoEn =>
      dateTime().withDefault(currentDateAndTime)();
}

class EcfeDocumentosTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Solo referencia; no FK estricta para no acoplar borrados de ventas.
  IntColumn get ventaId => integer().nullable()();
  IntColumn get tipoEcf => integer()();
  TextColumn get encf => text().nullable()();
  TextColumn get estado => text().withDefault(const Constant('borrador'))();
  TextColumn get trackId => text().nullable()();
  TextColumn get codigoRespuesta => text().nullable()();
  TextColumn get mensajeDgii => text().nullable()();
  TextColumn get ultimoError => text().nullable()();
  TextColumn get xmlSinFirma => text().nullable()();
  TextColumn get xmlFirmado => text().nullable()();

  /// Código de seguridad RI (6 chars). Persistido al firmar / consulta DGII.
  TextColumn get codigoSeguridad => text().nullable()();

  /// e-NCF del comprobante modificado (NC/ND).
  TextColumn get encfReferencia => text().nullable()();
  TextColumn get motivoAnulacion => text().nullable()();
  DateTimeColumn get creadoEn => dateTime()();
  DateTimeColumn get actualizadoEn => dateTime().nullable()();

  TextColumn get rncReceptor => text().nullable()();
  TextColumn get notaFiscalJson => text().nullable()();
}

class EcfeEventosTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get documentoId => integer()();
  TextColumn get paso => text()();
  TextColumn get detalle => text().nullable()();
  BoolColumn get ok => boolean().withDefault(const Constant(true))();
  DateTimeColumn get creadoEn => dateTime()();
}

class EcfeSecuenciasTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tipoEcf => integer()();
  IntColumn get secuenciaActual => integer().withDefault(const Constant(0))();
  IntColumn get secuenciaDesde => integer().withDefault(const Constant(1))();
  IntColumn get secuenciaHasta =>
      integer().withDefault(const Constant(9999999999))();
  DateTimeColumn get fechaVencimiento => dateTime().nullable()();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
}

/// Versiones de especificación e-CF (circulares / XSD) y checklist de adopción.
class EcfeSpecVersionTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get codigo => text()();
  TextColumn get nombre => text()();
  TextColumn get circularDgii => text().nullable()();
  TextColumn get xsdVersion => text().withDefault(const Constant(''))();
  TextColumn get notas => text().nullable()();
  BoolColumn get activaPrecert =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get activaCert => boolean().withDefault(const Constant(false))();
  BoolColumn get activaProduccion =>
      boolean().withDefault(const Constant(false))();
  TextColumn get checklistJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get creadoEn => dateTime()();
  DateTimeColumn get activadoEn => dateTime().nullable()();
}
