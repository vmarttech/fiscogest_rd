import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/ventas_navegacion_provider.dart';

class VistaCarrito extends ConsumerWidget {
  const VistaCarrito({super.key});

  String formatearMonto(double valor) {
    return NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2).format(valor);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venta = ref.watch(registrarVentaProvider);
    final modo = ref.watch(ventasNavegacionProvider.select((e) => e.modoOperacion));

    final titulo = switch (modo) {
      ModoOperacion.venta => 'CARRITO DE VENTA',
      ModoOperacion.cotizacion => 'CARRITO DE COTIZACIÓN',
      ModoOperacion.apartado => 'CARRITO DE APARTADO',
      ModoOperacion.cobrar => 'CUENTAS POR COBRAR',
    };

    final colorPrincipal = switch (modo) {
      ModoOperacion.venta => AppColors.primary,
      ModoOperacion.cotizacion => AppColors.info,
      ModoOperacion.apartado => AppColors.warning,
      ModoOperacion.cobrar => AppColors.error,
    };

    if (venta.detalles.isEmpty) {
      return const _CarritoVacio();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo,
                style: AppTypography.h4.copyWith(color: colorPrincipal, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => ref.read(registrarVentaProvider.notifier).vaciarVenta(),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Vaciar'),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: venta.detalles.length,
            itemBuilder: (context, i) => _FilaProducto(
              linea: venta.detalles[i],
              indice: i,
            ),
          ),
        ),
        const Divider(height: 1),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FilaTotal(etiqueta: 'Subtotal', valor: formatearMonto(venta.subtotal)),
              const SizedBox(height: 4),
              _FilaTotal(etiqueta: 'ITBIS', valor: formatearMonto(venta.itbis)),
              if (venta.montoDescuento > 0) ...[
                const SizedBox(height: 4),
                _FilaTotal(etiqueta: 'Descuento', valor: '- ${formatearMonto(venta.montoDescuento)}'),
              ],
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              _FilaTotal(etiqueta: 'TOTAL', valor: formatearMonto(venta.total), resaltado: true),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(ventasNavegacionProvider.notifier).cambiarVista(VistaActual.inicio);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorPrincipal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.payment, size: 22),
                  label: const Text('SELECCIONAR FORMA DE PAGO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CarritoVacio extends ConsumerWidget {
  const _CarritoVacio();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 72, color: AppColors.grey400),
            const SizedBox(height: 16),
            const Text('No hay productos agregados', style: AppTypography.labelLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('Busca y agrega productos desde el catálogo', style: AppTypography.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => ref.read(ventasNavegacionProvider.notifier).cambiarVista(VistaActual.inventario),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('AGREGAR PRODUCTOS'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaProducto extends ConsumerWidget {
  const _FilaProducto({required this.linea, required this.indice});
  final DetalleVenta linea;
  final int indice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtotalMostrar = linea.subtotalLinea ?? linea.subtotal;
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(linea.nombreProducto ?? 'Producto', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${formatearMonto(linea.precioUnitario)} c/u', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => ref.read(registrarVentaProvider.notifier).cambiarCantidad(indice, linea.cantidad - 1),
                  icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppColors.primary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                SizedBox(width: 28, child: Text('${linea.cantidad}', textAlign: TextAlign.center, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold))),
                IconButton(
                  onPressed: () => ref.read(registrarVentaProvider.notifier).cambiarCantidad(indice, linea.cantidad + 1),
                  icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.primary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: Text(formatearMonto(subtotalMostrar), textAlign: TextAlign.right, style: AppTypography.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold))),
            const SizedBox(width: 4),
            SizedBox(width: 28, height: 28, child: IconButton(
              onPressed: () => ref.read(registrarVentaProvider.notifier).eliminarProducto(indice),
              icon: const Icon(Icons.close, size: 18, color: AppColors.error),
              padding: EdgeInsets.zero,
            )),
          ],
        ),
      ),
    );
  }

  String formatearMonto(double valor) => NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2).format(valor);
}

class _FilaTotal extends StatelessWidget {
  const _FilaTotal({required this.etiqueta, required this.valor, this.resaltado = false});
  final String etiqueta;
  final String valor;
  final bool resaltado;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(etiqueta, style: AppTypography.bodyMedium.copyWith(fontWeight: resaltado ? FontWeight.bold : FontWeight.normal, fontSize: resaltado ? 18 : 14, color: resaltado ? AppColors.primary : AppColors.textSecondary)),
        Text(valor, style: AppTypography.bodyMedium.copyWith(fontWeight: resaltado ? FontWeight.bold : FontWeight.w500, fontSize: resaltado ? 18 : 14, color: resaltado ? AppColors.primary : null)),
      ],
    );
  }
}
