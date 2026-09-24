import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/facturacion/data/dao/secuencias_ncf_dao.dart';
import 'package:fiscogest_rd/features/facturacion/domain/emitir_factura_service.dart';
import 'package:fiscogest_rd/features/facturacion/domain/emitir_nc_service.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/listas_ventas_providers.dart';

final secuenciasNcfDaoProvider = Provider<SecuenciasNcfDao>((ref) {
  final db = ref.watch(databaseProvider);
  return SecuenciasNcfDao(db);
});

final secuenciasNcfListProvider = FutureProvider.autoDispose((ref) async {
  final dao = ref.watch(secuenciasNcfDaoProvider);
  await dao.asegurarDefaults();
  return dao.listar();
});

final emitirFacturaServiceProvider = Provider<EmitirFacturaService>((ref) {
  return EmitirFacturaService(
    ventasRepo: ref.watch(ventasRepositoryProvider),
    secuenciasDao: ref.watch(secuenciasNcfDaoProvider),
  );
});

final documentosPendientesFacturaProvider =
    FutureProvider.autoDispose<List<Venta>>((ref) async {
  final repo = ref.watch(ventasRepositoryProvider);
  final list = await repo.listarCotizaciones();
  return list.where((v) {
    final sinNcf = (v.numeroFactura ?? '').trim().isEmpty;
    final listo = v.estadoDocumento == EstadoDocumento.cotizado ||
        v.estadoDocumento == EstadoDocumento.aprobado;
    return sinNcf && listo;
  }).toList();
});

final emitirNcServiceProvider = Provider<EmitirNcService>((ref) {
  return EmitirNcService(
    ventasRepo: ref.watch(ventasRepositoryProvider),
    secuenciasDao: ref.watch(secuenciasNcfDaoProvider),
  );
});
