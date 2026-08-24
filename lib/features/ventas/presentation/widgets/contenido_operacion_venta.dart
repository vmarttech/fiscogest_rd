import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Enums — valores reales: inicio, inventario, detalle, historial
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
// Entidad Venta
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
// Providers — rutas y nombres reales
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_cargada_desde_historial_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/ventas_navegacion_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/listas_ventas_providers.dart';
// Widgets
import 'package:fiscogest_rd/features/ventas/presentation/widgets/mostrar_detalle_venta.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';

class ContenidoOperacionVenta extends ConsumerStatefulWidget {
  const ContenidoOperacionVenta({super.key});

  @override
  ConsumerState<ContenidoOperacionVenta> createState() => _ContenidoOperacionVentaState();
}

class _ContenidoOperacionVentaState extends ConsumerState<ContenidoOperacionVenta> {
  @override
  Widget build(BuildContext context) {
    final ventaCargada = ref.watch(ventaCargadaDesdeHistorialProvider);

    if (ventaCargada != null) {
      return MostrarDetalleVenta(venta: ventaCargada);
    }

    // Lee el enum desde el objeto de estado del provider
    final estadoNavegacion = ref.watch(ventasNavegacionProvider);
    switch (estadoNavegacion.vistaActual) {
      case VistaActual.inicio:
        return const VistaInicio();
      case VistaActual.inventario:
        return const VistaInventario();
      case VistaActual.detalle:
        return const VistaDetalle();
      case VistaActual.historial:
        return const VistaHistorial();
    }
  }
}

class VistaInicio extends StatelessWidget {
  const VistaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.point_of_sale, size: 80, color: AppColors.primary),
          SizedBox(height: AppSpacing.l),
          Text('Punto de Venta', style: AppTypography.h2),
          SizedBox(height: AppSpacing.m),
          Text('Seleccione una opción del menú', style: AppTypography.bodyLarge),
        ],
      ),
    );
  }
}

class VistaInventario extends StatelessWidget {
  const VistaInventario({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2, size: 64, color: AppColors.primary),
          SizedBox(height: AppSpacing.l),
          Text('Inventario', style: AppTypography.h3),
        ],
      ),
    );
  }
}

class VistaDetalle extends StatelessWidget {
  const VistaDetalle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description, size: 64, color: AppColors.primary),
          SizedBox(height: AppSpacing.l),
          Text('Detalle de Venta', style: AppTypography.h3),
        ],
      ),
    );
  }
}

class VistaHistorial extends ConsumerWidget {
  const VistaHistorial({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // FutureProvider usa: loading, error, data — nombres reales de Riverpod
    final estado = ref.watch(listaVentasProvider);

    return estado.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace? stackTrace) => Center(
        child: Padding(
          padding: AppSpacing.allL,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.m),
              Text('Error: $error', style: AppTypography.bodyMedium.copyWith(color: AppColors.error), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.m),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(listaVentasProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      data: (List<Venta> ventas) {
        if (ventas.isEmpty) {
          return const Center(child: Text('No hay transacciones registradas', style: AppTypography.bodyLarge));
        }
        return ListView.builder(
          padding: AppSpacing.allM,
          itemCount: ventas.length,
          itemBuilder: (BuildContext ctx, int i) => FilaTransaccion(venta: ventas[i]),
        );
      },
    );
  }
}

class FilaTransaccion extends ConsumerWidget {
  const FilaTransaccion({super.key, required this.venta});
  final Venta venta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      child: ListTile(
        title: Text('Transacción Nº ${venta.numero}', style: AppTypography.labelLarge),
        subtitle: Text('${venta.nombreCliente ?? "Cliente genérico"} • RD\$ ${venta.total.toStringAsFixed(2)}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Método real confirmado: establecerVenta, NO cargarVenta
          ref.read(ventaCargadaDesdeHistorialProvider.notifier).establecerVenta(venta);
        },
      ),
    );
  }
}
