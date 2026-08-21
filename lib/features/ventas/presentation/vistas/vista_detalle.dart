import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/features/clientes/presentation/widgets/seleccionar_cliente_dialog.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/ventas_navegacion_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/formulario_venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/panel_carrito.dart';

/// Vista de detalle — LÓGICA DE GUARDADO REAL CONECTADA
/// ✅ Construye entidad Venta desde RegistrarVentaState
/// ✅ Llama caso de uso RegistrarVenta real
/// ✅ Maneja éxito y error de forma explícita
class VistaDetalle extends ConsumerStatefulWidget {
  const VistaDetalle({super.key});

  @override
  ConsumerState<VistaDetalle> createState() => _VistaDetalleState();
}

class _VistaDetalleState extends ConsumerState<VistaDetalle> {
  bool _guardando = false;

  Future<void> _alSeleccionarCliente() async {
    final cliente = await SeleccionarClienteDialog.mostrar(context);
    if (cliente != null && cliente.id != null) {
      ref.read(registrarVentaProvider.notifier).seleccionarCliente(cliente.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cliente seleccionado: ${cliente.nombre}')),
        );
      }
    }
  }

  void _alSeleccionarFormaPago() {
    showDialog<FormaPago>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forma de Pago'),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: FormaPago.values.map((forma) {
            final etiqueta = switch (forma) {
              FormaPago.efectivo => 'Efectivo',
              FormaPago.tarjeta => 'Tarjeta',
              FormaPago.transferencia => 'Transferencia',
              FormaPago.credito => 'Crédito',
              FormaPago.cheque => 'Cheque',
            };
            return ListTile(
              title: Text(etiqueta),
              onTap: () => Navigator.pop(ctx, forma),
            );
          }).toList(),
        ),
      ),
    ).then((seleccion) {
      if (seleccion != null) {
        final etiqueta = seleccion.name;
        final esCredito = seleccion == FormaPago.credito;
        ref
            .read(registrarVentaProvider.notifier)
            .cambiarFormaPago(etiqueta, esCredito);
      }
    });
  }

  String _generarNumeroVenta(DateTime fecha) {
    return '${fecha.year}${fecha.month.toString().padLeft(2,'0')}${fecha.day.toString().padLeft(2,'0')}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
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

    setState(() => _guardando = true);

    try {
      final estado = ref.read(registrarVentaProvider);
      final fecha = DateTime.now();

      final venta = Venta(
        numero: _generarNumeroVenta(fecha),
        clienteId: estado.clienteId,
        fecha: fecha,
        detalles: estado.detalles,
        subtotal: estado.subtotal,
        itbis: estado.itbis,
        total: estado.total,
        tipoPago: estado.tipoPago,
        esCredito: estado.esCredito,
        usuarioId: estado.usuarioId,
        createdAt: fecha,
      );

      final casoUso = ref.read(registrarVentaUseCaseProvider);
      final resultado = await casoUso(venta);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Venta guardada — N° ${resultado.numero}'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      ref.read(registrarVentaProvider.notifier).vaciarVenta();
      ref.read(ventasNavegacionProvider.notifier).volverAlInicio();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar: $error'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
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
                onPressed: _guardando ? null : () => ref
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
            onPressed: !_guardando && estado.detalles.isNotEmpty ? _confirmarVenta : null,
            icon: _guardando
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_outline),
            label: Text(_guardando ? 'Guardando...' : 'Confirmar Operación'),
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
