import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/lista_precios.dart';
import 'package:fiscogest_rd/features/ventas/domain/usecases/calcular_precio_desde_margen.dart';
import 'package:fiscogest_rd/features/ventas/domain/usecases/calcular_margen.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_lista_precios_repository.dart';
import 'package:fiscogest_rd/features/ventas/data/repositories/lista_precios_repository_impl.dart';

final calcularPrecioDesdeMargenProvider = Provider<CalcularPrecioDesdeMargen>(
  (ref) => const CalcularPrecioDesdeMargen(),
);

final calcularMargenProvider = Provider<CalcularMargen>(
  (ref) => const CalcularMargen(),
);

final listaPreciosRepositoryProvider = Provider<IListaPreciosRepository>(
  (ref) => ListaPreciosRepositoryImpl(AppDatabase()),
);

final listaPreciosPorProductoProvider =
    FutureProvider.family<ListaPrecios?, int>((ref, productoId) async {
      final repo = ref.watch(listaPreciosRepositoryProvider);
      return repo.obtenerPorProductoId(productoId);
    });
