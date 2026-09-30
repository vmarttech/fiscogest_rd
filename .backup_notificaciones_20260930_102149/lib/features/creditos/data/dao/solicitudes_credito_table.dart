import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_table.dart';

/// Expediente del solicitante ligado 1:1 a la cotización (venta_id).
@DataClassName('SolicitudCreditoData')
class SolicitudesCreditoTable extends Table {
  IntColumn get id => integer().autoIncrement().named('id')();

  IntColumn get ventaId => integer()
      .named('venta_id')
      .references(VentasTable, #id)
      .unique()();

  TextColumn get nombreCompleto =>
      text().named('nombre_completo').withDefault(const Constant(''))();
  TextColumn get cedula =>
      text().named('cedula').withDefault(const Constant(''))();
  DateTimeColumn get fechaNacimiento =>
      dateTime().named('fecha_nacimiento').nullable()();
  TextColumn get estadoCivil =>
      text().named('estado_civil').withDefault(const Constant(''))();

  TextColumn get telefono =>
      text().named('telefono').withDefault(const Constant(''))();
  TextColumn get celular =>
      text().named('celular').withDefault(const Constant(''))();
  TextColumn get email =>
      text().named('email').withDefault(const Constant(''))();

  TextColumn get direccion =>
      text().named('direccion').withDefault(const Constant(''))();
  TextColumn get sector =>
      text().named('sector').withDefault(const Constant(''))();
  TextColumn get ciudad =>
      text().named('ciudad').withDefault(const Constant(''))();
  TextColumn get tiempoResidencia =>
      text().named('tiempo_residencia').withDefault(const Constant(''))();

  TextColumn get empresa =>
      text().named('empresa').withDefault(const Constant(''))();
  TextColumn get cargo =>
      text().named('cargo').withDefault(const Constant(''))();
  TextColumn get telefonoTrabajo =>
      text().named('telefono_trabajo').withDefault(const Constant(''))();
  RealColumn get ingresoMensual =>
      real().named('ingreso_mensual').withDefault(const Constant(0.0))();
  TextColumn get tiempoLaborando =>
      text().named('tiempo_laborando').withDefault(const Constant(''))();

  TextColumn get tipoVivienda =>
      text().named('tipo_vivienda').withDefault(const Constant(''))();
  IntColumn get dependientes =>
      integer().named('dependientes').withDefault(const Constant(0))();
  TextColumn get notasAnalista =>
      text().named('notas_analista').withDefault(const Constant(''))();

  IntColumn get usuarioId =>
      integer().named('usuario_id').withDefault(const Constant(1))();
  DateTimeColumn get creadoEn =>
      dateTime().named('creado_en').withDefault(currentDateAndTime)();
  DateTimeColumn get actualizadoEn =>
      dateTime().named('actualizado_en').withDefault(currentDateAndTime)();
}
