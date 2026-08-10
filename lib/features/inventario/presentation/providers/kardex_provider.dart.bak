import 'package:fiscogest_rd/features/inventario/presentation/providers/inventario_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';
import 'package:fiscogest_rd/features/inventario/domain/usecases/registrar_movimiento_kardex.dart';
import 'package:fiscogest_rd/features/inventario/domain/usecases/registrar_transferencia.dart';

final registrarMovimientoKardexProvider = Provider<RegistrarMovimientoKardex>((ref) {
  return RegistrarMovimientoKardex(ref.watch(kardexRepositoryProvider));
});

final registrarTransferenciaProvider = Provider<RegistrarTransferencia>((ref) {
  return RegistrarTransferencia(ref.watch(kardexRepositoryProvider));
});

final kardexPorProductoProvider = FutureProvider.family<List<Kardex>, String>((ref, productoIdStr) async {
  final repo = ref.watch(kardexRepositoryProvider);
  if (productoIdStr.trim().isEmpty) return repo.obtenerTodoElHistorial();
  return repo.obtenerHistorialPorProducto(productoIdStr);
});
