
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/gastronomia/data/services/gastronomia_service.dart';
import 'package:fiscogest_rd/features/gastronomia/domain/entities/gastronomia_entities.dart';

final gastronomiaServiceProvider = Provider<GastronomiaService>((ref) {
  final db = ref.watch(databaseProvider);
  return GastronomiaService(db);
});

final sectoresDeliveryProvider = FutureProvider<List<SectorDelivery>>((ref) =>
    ref.read(gastronomiaServiceProvider).sectores());

final repartidoresProvider = FutureProvider<List<Repartidor>>((ref) =>
    ref.read(gastronomiaServiceProvider).repartidores());

final pedidosGastroPendientesProvider = FutureProvider((ref) =>
    ref.read(gastronomiaServiceProvider).pedidosPendientes());

final extrasGlobalesProvider = FutureProvider<List<ExtraGastronomico>>((ref) =>
    ref.read(gastronomiaServiceProvider).extrasGlobales());

class CarritoGastroNotifier extends StateNotifier<List<LineaCarritoGastro>> {
  CarritoGastroNotifier() : super([]);
  void agregar(LineaCarritoGastro l) => state = [...state, l];
  void quitar(int i) => state = [...state.sublist(0, i), ...state.sublist(i + 1)];
  void cambiarCantidad(int i, double delta) {
    final s = [...state];
    s[i] = LineaCarritoGastro(
        productoId: s[i].productoId, nombre: s[i].nombre,
        precioUnitario: s[i].precioUnitario,
        cantidad: (s[i].cantidad + delta).clamp(1, 999).toDouble(),
        extras: s[i].extras, notas: s[i].notas);
    state = s;
  }
  void limpiar() => state = [];
  double get subtotal => state.fold(0, (s, l) => s + l.subtotal);
}

final carritoGastroProvider =
    StateNotifierProvider<CarritoGastroNotifier, List<LineaCarritoGastro>>(
        (ref) => CarritoGastroNotifier());

final resumenRepartidoresProvider = FutureProvider<List<ResumenRepartidor>>((ref) =>
    ref.read(gastronomiaServiceProvider).resumenRepartidores());

final pedidosGastroHistorialProvider = FutureProvider.family((ref, String? estado) => ref.read(gastronomiaServiceProvider).pedidosHistorial(estado: estado));

final topPlatosProvider = FutureProvider((ref) => ref.read(gastronomiaServiceProvider).topPlatos());
final ventasPorHoraProvider = FutureProvider((ref) => ref.read(gastronomiaServiceProvider).ventasPorHora());
