import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/datasources/promocion_datasource.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/promocion_repository_impl.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/promocion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const canalPathProvider = MethodChannel('plugins.flutter.io/path_provider');

  late Directory directorioTemporal;
  late AppDatabase db;
  late PromocionDatasource datasource;
  late PromocionRepositoryImpl repositorio;

  setUpAll(() async {
    directorioTemporal = await Directory.systemTemp.createTemp(
      'fiscogest_promociones_test_',
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canalPathProvider, (call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return directorioTemporal.path;
          }
          throw MissingPluginException('Método no simulado: ${call.method}');
        });

    db = AppDatabase();
    datasource = PromocionDatasource(db);
    repositorio = PromocionRepositoryImpl(datasource);
  });

  tearDownAll(() async {
    await db.close();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canalPathProvider, null);

    if (await directorioTemporal.exists()) {
      await directorioTemporal.delete(recursive: true);
    }
  });

  test(
    'persiste, recupera, actualiza y elimina asociaciones de promociones',
    () async {
      final creada = await repositorio.crear(
        const Promocion(
          id: 0,
          nombre: 'Promoción segmentada',
          descripcion: 'Prueba de persistencia',
          tipo: 'porcentaje',
          valor: 15,
          productoIds: [10, 20],
          categoriaIds: [3, 4],
        ),
      );

      expect(creada.id, greaterThan(0));

      final recuperada = await repositorio.obtenerPorId(creada.id);

      expect(recuperada, isNotNull);
      expect(recuperada!.productoIds, [10, 20]);
      expect(recuperada.categoriaIds, [3, 4]);

      final actualizada = await repositorio.actualizar(
        Promocion(
          id: creada.id,
          nombre: 'Promoción modificada',
          descripcion: 'Asociaciones reemplazadas',
          tipo: 'porcentaje',
          valor: 20,
          productoIds: const [30],
          categoriaIds: const [8],
        ),
      );

      expect(actualizada.nombre, 'Promoción modificada');

      final recuperadaActualizada = await repositorio.obtenerPorId(creada.id);

      expect(recuperadaActualizada, isNotNull);
      expect(recuperadaActualizada!.productoIds, [30]);
      expect(recuperadaActualizada.categoriaIds, [8]);
      expect(recuperadaActualizada.valor, 20);

      await repositorio.eliminar(creada.id);

      expect(await repositorio.obtenerPorId(creada.id), isNull);
      expect(await datasource.listarProductoIds(creada.id), isEmpty);
      expect(await datasource.listarCategoriaIds(creada.id), isEmpty);
    },
  );

  test('una promoción antigua sin relaciones continúa siendo global', () async {
    final id = await db.customInsert(
      '''
      INSERT INTO promociones_comerciales (
        nombre, descripcion, tipo, valor, activa
      ) VALUES (?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable.withString('Promoción antigua'),
        Variable.withString('Sin asociaciones históricas'),
        Variable.withString('porcentaje'),
        Variable.withReal(10),
        Variable.withInt(1),
      ],
    );

    final antigua = await repositorio.obtenerPorId(id);

    expect(antigua, isNotNull);
    expect(antigua!.productoIds, isEmpty);
    expect(antigua.categoriaIds, isEmpty);
    expect(antigua.aplicaAProducto(100), isTrue);
    expect(antigua.aplicaAProducto(200, idCategoria: 50), isTrue);
  });
}
