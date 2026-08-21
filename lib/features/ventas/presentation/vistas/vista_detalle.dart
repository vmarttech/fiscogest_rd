import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/ventas_navegacion_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/formulario_venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/panel_carrito.dart';

/// Vista de detalle: carrito + formulario + totales + confirmación
/// ✅ Imports limpios + const aplicado donde corresponde
class VistaDetalle extends ConsumerStatefulWidget {
  const VistaDetalle({super.key});

  @override
  ConsumerState<VistaDetalle> createState() => _VistaDetalleState();
}

class _VistaDetalleState extends ConsumerState<VistaDetalle> {
  void _alSeleccionarCliente() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selector de clientes se integrará aquí')),
    );
  }

  void _alSeleccionarFormaPago() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selector de pago se integrará aquí')),
    );
  }

  Future<void> _confirmarVenta() async {
    final valido = ref.read(registrarVentaProvider.notifier).validarAntesDeGuardar();
    if (!valido) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete cliente, forma de pago y productos'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Guardando operación...'),
        backgroundColor: AppColors.success,
      ),
    );

    ref.read(registrarVentaProvider.notifier).vaciarVenta();
    ref.read(ventasNavegacionProvider.notifier).volverAlInicio();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(registrarVentaProvider);

    return SingleChildScrollView(
      padding: AppSpacing.allM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
                onPressed: () => ref
                    .read(ventasNavegacionProvider.notifier)
                    .cambiarVista(VistaActual.inventario),
              ),
              const Expanded(
                child: Text(
                  'Detalle de Operación',
                  style: AppTypography.h4,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          const PanelCarrito(),
          const SizedBox(height: AppSpacing.m),
          FormularioVenta(
            alSeleccionarCliente: _alSeleccionarCliente,
            alSeleccionarFormaPago: _alSeleccionarFormaPago,
          ),
          const SizedBox(height: AppSpacing.l),
          ElevatedButton.icon(
            onPressed: estado.detalles.isNotEmpty ? _confirmarVenta : null,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Confirmar Operación'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
