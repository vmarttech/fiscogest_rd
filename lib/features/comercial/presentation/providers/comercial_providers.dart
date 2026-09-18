import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/oferta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

final ofertasActivasProvider = FutureProvider<List<Oferta>>((final ref) async {
  final repositorio = ref.watch(ventasRepositoryProvider);
  return repositorio.obtenerOfertasActivas();
});
