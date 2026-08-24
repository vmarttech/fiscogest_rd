import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/descuento.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/oferta.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

final descuentosActivosProvider = FutureProvider<List<Descuento>>((ref) async {
  final IVentasRepository repositorio = ref.watch(ventasRepositoryProvider);
  return await repositorio.obtenerDescuentosActivos();
});

final ofertasActivosProvider = FutureProvider<List<Oferta>>((ref) async {
  final IVentasRepository repositorio = ref.watch(ventasRepositoryProvider);
  return await repositorio.obtenerOfertasActivas();
});
