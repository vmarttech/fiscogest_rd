import 'package:drift/drift.dart';

/// Configuración global del negocio (fila única id=1).
class ConfiguracionTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombreNegocio => text().withDefault(const Constant(''))();
  TextColumn get razonSocial => text().withDefault(const Constant(''))();
  TextColumn get rncCedula => text().withDefault(const Constant(''))();
  TextColumn get direccion => text().withDefault(const Constant(''))();
  TextColumn get telefono => text().withDefault(const Constant(''))();
  TextColumn get correo => text().withDefault(const Constant(''))();
  TextColumn get logoUrl => text().withDefault(const Constant(''))();
  TextColumn get moneda => text().withDefault(const Constant('DOP'))();
  TextColumn get zonaHoraria =>
      text().withDefault(const Constant('America/Santo_Domingo'))();
  TextColumn get formatoImpresion =>
      text().withDefault(const Constant('Ticket 80mm'))();
  TextColumn get formatoFecha =>
      text().withDefault(const Constant('DD/MM/YYYY'))();
  RealColumn get impuestoPorcentaje =>
      real().withDefault(const Constant(18.0))();
  TextColumn get idioma => text().withDefault(const Constant('Español'))();

  BoolColumn get docMostrarLogo =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get docMostrarRnc =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get docMostrarDireccion =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get docMostrarTelefono =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get docMostrarCorreo =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get docMostrarNcf =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get docMostrarCliente =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get docMostrarItbisDesglose =>
      boolean().withDefault(const Constant(true))();
  TextColumn get docPiePagina =>
      text().withDefault(const Constant('Gracias por su preferencia'))();
  TextColumn get prefijoContado =>
      text().withDefault(const Constant('C'))();
  TextColumn get prefijoCredito =>
      text().withDefault(const Constant('CR'))();

  TextColumn get cajaFormaPagoDefault =>
      text().withDefault(const Constant('efectivo'))();
  BoolColumn get cajaPermitirTarjeta =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get cajaPermitirTransferencia =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get cajaPermitirCheque =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get cajaExigirSesion =>
      boolean().withDefault(const Constant(false))();
}
