import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/compra/confirmar_compra_usecase.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/compra/registrar_compra_usecase.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/compra/listar_compras_usecase.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/inventario_providers.dart';

final confirmarCompraUseCaseProvider = Provider<ConfirmarCompraUseCase>((ref) {
  final compraRepository = ref.watch(compraRepositoryProvider);
  final inventarioRepository = ref.watch(inventarioRepositoryProvider);
  final productoRepository = ref.watch(productoRepositoryProvider);
  final proveedorRepository = ref.watch(proveedorRepositoryProvider);
  final kardexRepository = ref.watch(kardexRepositoryProvider);

  return ConfirmarCompraUseCase(
    compraRepository,
    inventarioRepository,
    productoRepository,
    proveedorRepository,
    kardexRepository,
  );
});

final registrarCompraUseCaseProvider = Provider<RegistrarCompraUseCase>((ref) {
  final repo = ref.watch(compraRepositoryProvider);
  return RegistrarCompraUseCase(repo);
});

final listarComprasUseCaseProvider = Provider<ListarComprasUseCase>((ref) {
  final repo = ref.watch(compraRepositoryProvider);
  return ListarComprasUseCase(repo);
});
