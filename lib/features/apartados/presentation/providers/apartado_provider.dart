import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/apartados/domain/repositories/i_apartado_repository.dart';
import 'package:fiscogest_rd/features/apartados/data/repositories/apartado_repository_impl.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/apartados_dao.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/apartado.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_provider.dart';
import 'package:fiscogest_rd/providers/producto_provider.dart';

final apartadoRepositoryProvider = Provider<IApartadoRepository>((ref) {
  final AppDatabase db = ref.read(databaseProvider);
  final ApartadosDao apartadosDao = ApartadosDao(db);
  return ApartadoRepositoryImpl(apartadosDao: apartadosDao);
});

class ApartadoNotifier extends StateNotifier<AsyncValue<List<Apartado>>> {
  ApartadoNotifier(this.ref) : super(const AsyncValue.loading()) {
    _cargarTodos();
  }

  final Ref ref;

  Future<void> _cargarTodos() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final IApartadoRepository repo = ref.read(apartadoRepositoryProvider);
      final List<Map<String, dynamic>> listaMap = await repo.listarApartados();
      return listaMap
          .map(
            (Map<String, dynamic> m) => Apartado(
              id: m['id'] as int?,
              numero: m['numero'] as String? ?? '',
              clienteId: m['clienteId'] as int? ?? 0,
              productos: const [],
              montoTotal: (m['montoTotal'] as num? ?? 0).toDouble(),
              montoAbonado: (m['montoAbonado'] as num? ?? 0).toDouble(),
              saldoPendiente: (m['saldoPendiente'] as num? ?? 0).toDouble(),
              fechaApartado:
                  DateTime.tryParse(m['fechaApartado'] as String? ?? '') ??
                  DateTime.now(),
              fechaLimitePago: m['fechaLimitePago'] != null
                  ? DateTime.tryParse(m['fechaLimitePago'] as String)
                  : null,
              estado: m['estado'] as String? ?? 'Activo',
              createdAt: m['createdAt'] != null
                  ? DateTime.tryParse(m['createdAt'] as String)
                  : null,
            ),
          )
          .toList();
    });
  }

  Future<int> crearApartadoDesdeVenta(RegistrarVentaState venta) async {
    state = const AsyncValue.loading();
    try {
      final IApartadoRepository repo = ref.read(apartadoRepositoryProvider);
      final ProductoNotifier productoNotifier = ref.read(productoProvider.notifier);

      final List<Map<String, dynamic>> productos = venta.detalles.map((DetalleVenta detalle) {
        return <String, dynamic>{
          'productoId': detalle.productoId,
          'cantidad': detalle.cantidad,
          'precioUnitario': detalle.precioUnitario,
          'subtotal': detalle.subtotal,
        };
      }).toList();

      for (final DetalleVenta detalle in venta.detalles) {
        await productoNotifier.reservarStock(
          detalle.productoId,
          detalle.cantidad.toDouble(),
        );
      }

      final double anticipo = venta.esCredito ? 0.0 : venta.total;

      final int nuevoId = await repo.registrarApartado(
        fecha: DateTime.now(),
        clienteId: venta.clienteId ?? 0,
        usuarioId: venta.usuarioId,
        productos: productos,
        total: venta.total,
        anticipo: anticipo,
        validoHasta: DateTime.now().add(const Duration(days: 30)),
      );

      await _cargarTodos();
      return nuevoId;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> cancelarApartado(int apartadoId, String motivo) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final IApartadoRepository repo = ref.read(apartadoRepositoryProvider);
      final Map<String, dynamic>? apartadoMap = await repo.obtenerPorId(apartadoId);
      if (apartadoMap != null) {
        final List<dynamic>? productos = apartadoMap['productos'] as List<dynamic>?;
        final ProductoNotifier productoNotifier = ref.read(productoProvider.notifier);
        for (final dynamic p in productos ?? <dynamic>[]) {
          final dynamic productoId = p['productoId'];
          final int cantidadEntera = p['cantidad'] as int? ?? 0;
          final double cantidad = cantidadEntera.toDouble();
          if (productoId != null) {
            final int prodId = productoId as int;
            await productoNotifier.liberarStockReservado(prodId, cantidad);
          }
        }
      }
      await repo.cancelarApartado(apartadoId, motivo);
      await _cargarTodos();
      return state.value ?? <Apartado>[];
    });
  }

  Future<void> registrarAbono(int apartadoId, double monto) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final IApartadoRepository repo = ref.read(apartadoRepositoryProvider);
      await repo.registrarAbono(apartadoId, monto);
      await _cargarTodos();
      return state.value ?? <Apartado>[];
    });
  }
}

final apartadoNotifierProvider =
    StateNotifierProvider<ApartadoNotifier, AsyncValue<List<Apartado>>>((Ref ref) {
  return ApartadoNotifier(ref);
});
