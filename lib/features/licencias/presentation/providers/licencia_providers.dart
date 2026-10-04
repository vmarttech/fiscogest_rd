import 'package:fiscogest_rd/features/licencias/domain/dispositivo_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/licencias/domain/licencia_service.dart';
import 'package:fiscogest_rd/features/licencias/domain/licencia_estado.dart';

final licenciaServiceProvider = Provider<LicenciaService>((ref) {
  final db = ref.watch(databaseProvider);
  return LicenciaService(db);
});

final licenciaActualProvider = FutureProvider<LicenciaInfo?>((ref) async {
  final svc = ref.watch(licenciaServiceProvider);
  await svc.ensureLicenciaInicial();
  await svc.expirarPedidosVencidos();
  return svc.obtenerActual();
});

final dispositivoServiceProvider = Provider<DispositivoService>((ref) {
  return DispositivoService(ref.watch(databaseProvider));
});

final dispositivosListaProvider =
    FutureProvider.autoDispose<List<DispositivoInfo>>((ref) async {
  final svc = ref.watch(dispositivoServiceProvider);
  await svc.ensureDispositivoRegistrado();
  return svc.listar();
});
