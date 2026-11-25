import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/sync/supabase/licencia_sync_policy.dart';
import 'package:fiscogest_rd/features/licencias/domain/licencia_limites_guard.dart';
import 'package:fiscogest_rd/features/licencias/domain/licencia_service.dart';
import 'package:fiscogest_rd/features/licencias/domain/planes_precios.dart';
import 'package:fiscogest_rd/features/licencias/domain/device_fingerprint.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  Future<void> activarGratis() async {
    final now = DateTime.now().toIso8601String();
    await db
        .into(db.licenciasTable)
        .insert(
          LicenciasTableCompanion.insert(
            plan: 'gratis',
            vigenciaTipo: 'permanente_limitada',
            fechaInicio: now,
            maxDispositivos: const Value(1),
            maxCajas: const Value(1),
            estado: 'activa',
            actualizadoEn: now,
          ),
        );
  }

  test('plan Gratis usa los límites mensuales acordados', () {
    final limites = limitesDe('gratis');
    expect(limites.maxVentasMes, 15);
    expect(limites.maxProductos, 20);
    expect(limites.maxClientes, 30);
  });

  test(
    'no concede una prueba local si no existe una licencia remota',
    () async {
      expect(await LicenciaService(db).ensureLicenciaInicial(), isNull);
      expect(await db.select(db.licenciasTable).get(), isEmpty);
    },
  );

  test(
    'cuenta productos registrados por mes y bloquea el registro 21',
    () async {
      await activarGratis();
      final guard = LicenciaLimitesGuard(db);
      for (var i = 0; i < 20; i++) {
        await guard.registrarProductoNuevo();
      }
      await expectLater(
        guard.registrarProductoNuevo(),
        throwsA(isA<LimitePlanException>()),
      );
      expect((await guard.resumenUsoGratis())['productos'], 20);
    },
  );

  test('cuenta clientes por mes y bloquea el registro 31', () async {
    await activarGratis();
    final guard = LicenciaLimitesGuard(db);
    for (var i = 0; i < 30; i++) {
      await guard.registrarClienteNuevo();
    }
    await expectLater(
      guard.registrarClienteNuevo(),
      throwsA(isA<LimitePlanException>()),
    );
    expect((await guard.resumenUsoGratis())['clientes'], 30);
  });

  test('permite 15 ventas del mes y bloquea la número 16', () async {
    await activarGratis();
    final ahora = DateTime.now();
    for (var i = 0; i < 15; i++) {
      await db
          .into(db.ventasTable)
          .insert(
            VentasTableCompanion.insert(
              clienteId: 0,
              fecha: ahora,
              formaPago: 'contado',
              numeroCotizacion: 'TEST-$i',
              estadoDocumento: 'facturado',
              usuarioId: 1,
              fechaRegistro: ahora,
            ),
          );
    }
    final guard = LicenciaLimitesGuard(db);
    expect((await guard.resumenUsoGratis())['ventas'], 15);
    await expectLater(
      guard.assertPuedeRegistrarVenta(),
      throwsA(isA<LimitePlanException>()),
    );
  });

  test('el uso local vuelve a cero al cambiar el mes', () async {
    await activarGratis();
    final ahora = DateTime.now();
    final anterior = DateTime(ahora.year, ahora.month - 1, 1);
    final periodoAnterior =
        '${anterior.year.toString().padLeft(4, '0')}-${anterior.month.toString().padLeft(2, '0')}';
    await db.customStatement(
      'INSERT INTO licencia_consumos_mensuales (recurso, periodo, cantidad) VALUES (?, ?, ?)',
      ['productos', periodoAnterior, 20],
    );
    expect((await LicenciaLimitesGuard(db).resumenUsoGratis())['productos'], 0);
  });

  test(
    'usa una identidad local cuando el sistema no ofrece una persistente',
    () async {
      final primera = await DeviceFingerprint.obtenerResultado();
      final segunda = await DeviceFingerprint.obtenerResultado();
      expect(segunda.fingerprint, primera.fingerprint);
      expect(primera.fingerprint, isNotEmpty);
      expect(primera.persistenteTrasReinstalar, isFalse);
      expect(
        (await SharedPreferences.getInstance()).getString(
          'fiscogest_device_id_v2',
        ),
        isNotNull,
      );
    },
  );

  test('el plan Gratis no sincroniza información operativa', () async {
    await activarGratis();
    expect(
      await LicenciaSyncPolicy.puedeSincronizarDatosOperativos(db),
      isFalse,
    );
  });

  test(
    'una prueba histórica vencida exige registro y conserva su fila',
    () async {
      final inicio = DateTime.now().subtract(const Duration(days: 40));
      final fin = inicio.add(const Duration(days: 30));
      await db
          .into(db.licenciasTable)
          .insert(
            LicenciasTableCompanion.insert(
              plan: 'demo',
              vigenciaTipo: 'prueba',
              fechaInicio: inicio.toIso8601String(),
              fechaFin: Value(fin.toIso8601String()),
              estado: 'activa',
              actualizadoEn: inicio.toIso8601String(),
            ),
          );

      final lic = await LicenciaService(db).obtenerActual();
      expect(lic?.estado, 'registro_requerido');
      expect(await db.select(db.licenciasTable).get(), hasLength(1));
    },
  );

  test('la prueba vence tras 30 días y 3 días de gracia', () async {
    Future<void> insertarPrueba(int diasDesdeInicio) async {
      final inicio = DateTime.now().subtract(Duration(days: diasDesdeInicio));
      final fin = inicio.add(const Duration(days: 30));
      await db
          .into(db.licenciasTable)
          .insert(
            LicenciasTableCompanion.insert(
              plan: 'demo',
              vigenciaTipo: 'prueba',
              fechaInicio: inicio.toIso8601String(),
              fechaFin: Value(fin.toIso8601String()),
              estado: 'activa',
              actualizadoEn: inicio.toIso8601String(),
            ),
          );
    }

    await insertarPrueba(29);
    expect((await LicenciaService(db).obtenerActual())?.estado, 'activa');
    await db.delete(db.licenciasTable).go();

    await insertarPrueba(31);
    expect((await LicenciaService(db).obtenerActual())?.estado, 'gracia');
    await db.delete(db.licenciasTable).go();

    await insertarPrueba(34);
    expect(
      (await LicenciaService(db).obtenerActual())?.estado,
      'registro_requerido',
    );
  });

  test(
    'una suscripción vencida conserva la transición existente a Gratis',
    () async {
      final inicio = DateTime.now().subtract(const Duration(days: 40));
      final fin = inicio.add(const Duration(days: 30));
      await db
          .into(db.licenciasTable)
          .insert(
            LicenciasTableCompanion.insert(
              plan: 'basico',
              vigenciaTipo: 'mensual',
              fechaInicio: inicio.toIso8601String(),
              fechaFin: Value(fin.toIso8601String()),
              estado: 'activa',
              actualizadoEn: inicio.toIso8601String(),
            ),
          );

      final licencia = await LicenciaService(db).obtenerActual();
      expect(licencia?.plan, 'gratis');
      expect(licencia?.estado, 'activa');
    },
  );
}
