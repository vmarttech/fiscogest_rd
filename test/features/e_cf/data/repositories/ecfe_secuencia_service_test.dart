import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/e_cf/data/repositories/ecfe_secuencia_service.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/tipo_ecf.dart';

void main() {
  late AppDatabase db;
  late EcfeSecuenciaService service;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());

    // Abre SQLite y ejecuta la creación del esquema.
    await db.customSelect('SELECT 1').get();

    service = EcfeSecuenciaService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('EcfeSecuenciaService', () {
    test('no crea secuencias predeterminadas', () async {
      await service.asegurarTiposBase();

      expect(await service.listar(), isEmpty);
    });

    test('rechaza rangos inválidos', () async {
      await expectLater(
        service.guardar(
          tipoEcf: 31,
          secuenciaActual: 0,
          secuenciaDesde: 0,
          secuenciaHasta: 100,
          activo: true,
        ),
        throwsA(isA<ArgumentError>()),
      );

      await expectLater(
        service.guardar(
          tipoEcf: 31,
          secuenciaActual: 0,
          secuenciaDesde: 10,
          secuenciaHasta: 5,
          activo: true,
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(await service.listar(), isEmpty);
    });

    test('rechaza contador fuera del rango autorizado', () async {
      await expectLater(
        service.guardar(
          tipoEcf: 31,
          secuenciaActual: 11,
          secuenciaDesde: 1,
          secuenciaHasta: 10,
          activo: true,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('falla si no existe una secuencia activa', () async {
      await expectLater(
        service.siguiente(TipoEcf.facturaCreditoFiscal),
        throwsA(isA<StateError>()),
      );
    });

    test('reserva el siguiente e-NCF con formato correcto', () async {
      await service.guardar(
        tipoEcf: 31,
        secuenciaActual: 0,
        secuenciaDesde: 1,
        secuenciaHasta: 10,
        activo: true,
      );

      final primero =
          await service.siguiente(TipoEcf.facturaCreditoFiscal);
      final segundo =
          await service.siguiente(TipoEcf.facturaCreditoFiscal);

      expect(primero.encf, 'E310000000001');
      expect(segundo.encf, 'E310000000002');
      expect(primero.vencimiento, isNull);

      final registros = await service.listar();
      expect(registros.single.secuenciaActual, 2);
    });

    test('respeta el inicio autorizado aunque el contador sea cero', () async {
      await service.guardar(
        tipoEcf: 32,
        secuenciaActual: 24,
        secuenciaDesde: 25,
        secuenciaHasta: 30,
        activo: true,
      );

      final resultado = await service.siguiente(TipoEcf.facturaConsumo);

      expect(resultado.encf, 'E320000000025');
    });

    test('rechaza una secuencia agotada', () async {
      await service.guardar(
        tipoEcf: 31,
        secuenciaActual: 10,
        secuenciaDesde: 1,
        secuenciaHasta: 10,
        activo: true,
      );

      await expectLater(
        service.siguiente(TipoEcf.facturaCreditoFiscal),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'mensaje',
            contains('agotada'),
          ),
        ),
      );
    });

    test('rechaza una secuencia vencida', () async {
      final hoy = DateTime.now();
      final ayer = DateTime(hoy.year, hoy.month, hoy.day - 1);

      await service.guardar(
        tipoEcf: 31,
        secuenciaActual: 0,
        secuenciaDesde: 1,
        secuenciaHasta: 10,
        fechaVencimiento: ayer,
        activo: true,
      );

      await expectLater(
        service.siguiente(TipoEcf.facturaCreditoFiscal),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'mensaje',
            contains('vencida'),
          ),
        ),
      );
    });

    test('permite una sola secuencia activa por tipo e-CF', () async {
      await service.guardar(
        tipoEcf: 31,
        secuenciaActual: 0,
        secuenciaDesde: 1,
        secuenciaHasta: 100,
        activo: true,
      );

      await service.guardar(
        tipoEcf: 31,
        secuenciaActual: 100,
        secuenciaDesde: 101,
        secuenciaHasta: 200,
        activo: true,
      );

      final registros = await service.listar();

      expect(registros, hasLength(2));
      expect(registros.where((r) => r.activo), hasLength(1));
      expect(
        registros.singleWhere((r) => r.activo).secuenciaDesde,
        101,
      );
    });

    test('reservas simultáneas no producen e-NCF duplicados', () async {
      const cantidad = 20;

      await service.guardar(
        tipoEcf: 31,
        secuenciaActual: 0,
        secuenciaDesde: 1,
        secuenciaHasta: 100,
        activo: true,
      );

      final resultados = await Future.wait(
        List.generate(
          cantidad,
          (_) => service.siguiente(TipoEcf.facturaCreditoFiscal),
        ),
      );

      final numeros = resultados
          .map((r) => int.parse(r.encf.substring(3)))
          .toList();

      expect(numeros.toSet(), hasLength(cantidad));

      final ordenados = [...numeros]..sort();
      expect(ordenados, List.generate(cantidad, (i) => i + 1));

      final registros = await service.listar();
      expect(registros.single.secuenciaActual, cantidad);
    });
  });

  group('EcfeSecuenciaService.esEncfFormal', () {
    test('acepta e-NCF formales', () {
      expect(
        EcfeSecuenciaService.esEncfFormal('E310000000001'),
        isTrue,
      );
      expect(
        EcfeSecuenciaService.esEncfFormal('E320000000001'),
        isTrue,
      );
    });

    test('rechaza formatos incorrectos', () {
      expect(EcfeSecuenciaService.esEncfFormal(null), isFalse);
      expect(EcfeSecuenciaService.esEncfFormal(''), isFalse);
      expect(EcfeSecuenciaService.esEncfFormal('B010000000001'), isFalse);
      expect(EcfeSecuenciaService.esEncfFormal('E31001'), isFalse);
      expect(EcfeSecuenciaService.esEncfFormal('E990000000001'), isFalse);
    });
  });
}
