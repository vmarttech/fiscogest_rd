import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/creditos/data/dao/parametros_credito_table.dart';

part 'parametros_credito_dao.g.dart';

@DriftAccessor(tables: [ParametrosCreditoTable])
class ParametrosCreditoDao extends DatabaseAccessor<AppDatabase>
    with _$ParametrosCreditoDaoMixin {
  ParametrosCreditoDao(super.db);

  Future<ParametroCreditoData?> obtener() async {
    return (select(parametrosCreditoTable)..limit(1)).getSingleOrNull();
  }

  Future<ParametroCreditoData> obtenerOCrear() async {
    final actual = await obtener();
    if (actual != null) return actual;
    final id = await into(
      parametrosCreditoTable,
    ).insert(ParametrosCreditoTableCompanion.insert());
    return (select(
      parametrosCreditoTable,
    )..where((t) => t.id.equals(id))).getSingle();
  }

  Future<void> guardar({
    required double tasaMensualDefault,
    required int cuotasDefault,
    required int plazoMaxMeses,
    required int diasGracia,
    required double moraPorcentaje,
    double capacidadPagoPorcentaje = 0.30,
    required String plantillaSolicitud,
    required String plantillaContrato,
  }) async {
    final actual = await obtenerOCrear();
    await (update(
      parametrosCreditoTable,
    )..where((t) => t.id.equals(actual.id))).write(
      ParametrosCreditoTableCompanion(
        tasaMensualDefault: Value(tasaMensualDefault),
        cuotasDefault: Value(cuotasDefault),
        plazoMaxMeses: Value(plazoMaxMeses),
        diasGracia: Value(diasGracia),
        moraPorcentaje: Value(moraPorcentaje),
        capacidadPagoPorcentaje: Value(capacidadPagoPorcentaje),
        plantillaSolicitud: Value(plantillaSolicitud),
        plantillaContrato: Value(plantillaContrato),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
  }
}
