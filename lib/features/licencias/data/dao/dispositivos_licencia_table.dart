import 'package:drift/drift.dart';

/// Dispositivos vinculados a la licencia (offline-first).
///
/// Mapeo previsto Supabase `dispositivos_licencia`:
///   id uuid PK, negocio_id uuid, fingerprint text unique,
///   alias text, plataforma text, tipo text, activo bool,
///   registrado_en timestamptz, ultimo_uso timestamptz,
///   updated_at timestamptz
class DispositivosLicenciaTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// UUID remoto (Supabase). Null hasta la primera sync.
  TextColumn get remoteId => text().nullable()();

  /// Negocio/cuenta en nube (futuro). Localmente puede quedar null.
  TextColumn get negocioId => text().nullable()();

  /// Huella estable del equipo (uuid persistido en disco).
  TextColumn get fingerprint => text()();

  TextColumn get alias => text().withDefault(const Constant('Este equipo'))();

  /// android | ios | linux | windows | macos | web
  TextColumn get plataforma => text()();

  /// pc | movil | tablet | otro
  TextColumn get tipo => text().withDefault(const Constant('pc'))();

  BoolColumn get activo => boolean().withDefault(const Constant(true))();

  TextColumn get registradoEn => text()();
  TextColumn get ultimoUso => text()();

  /// ISO última sync exitosa a Supabase (null = pendiente).
  TextColumn get sincronizadoEn => text().nullable()();

  BoolColumn get pendienteSync =>
      boolean().withDefault(const Constant(true))();
}
