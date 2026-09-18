import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/detalle_compra.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart';

// Listado de compras
final listadoComprasProvider = FutureProvider.autoDispose<List<Compra>>((ref) async {
  final repositorio = ref.read(compraRepositoryProvider);
  return repositorio.listarCompras();
});

// Obtener compra por ID
final compraPorIdProvider = FutureProvider.family.autoDispose<Compra?, int>((ref, id) async {
  final repositorio = ref.read(compraRepositoryProvider);
  return repositorio.obtenerCompraPorId(id);
});

// Confirmar compra
final confirmarCompraUseCaseProvider = Provider<Future<void> Function(dynamic)>((ref) {
  return (compraId) async {
    final id = compraId is int ? compraId : int.tryParse(compraId.toString()) ?? 0;
    final repositorio = ref.read(compraRepositoryProvider);
    await repositorio.confirmarCompra(id);
    ref.invalidate(listadoComprasProvider);
  };
});

// Registrar compra — firma exacta con parámetros nombrados
final registrarCompraUseCaseProvider = Provider<
  Future<Compra> Function({
    required Compra compra,
    required List<DetalleCompra> detalles,
  })
>((ref) {
  return ({required compra, required detalles}) async {
    final repositorio = ref.read(compraRepositoryProvider);
    final resultado = await repositorio.registrarCompra(
      compra: compra,
      detalles: detalles,
    );
    ref.invalidate(listadoComprasProvider);
    return resultado;
  };
});
