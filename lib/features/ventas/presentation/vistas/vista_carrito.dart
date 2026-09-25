import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/ventas_navegacion_provider.dart';

class VistaCarrito extends ConsumerWidget {
  const VistaCarrito({super.key});

  String formatearMonto(double valor) {
    return 'RD\$ ${NumberFormat('#,##0.00', 'es_DO').format(valor)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = AppBreakpoints.isMobile(context);
    final venta = ref.watch(registrarVentaProvider);
    final modo = ref.watch(ventasNavegacionProvider.select((e) => e.modoOperacion));

    final titulo = switch (modo) {
      ModoOperacion.venta => 'Carrito de Venta',
      ModoOperacion.cotizacion => 'Carrito de Cotización',
      ModoOperacion.apartado => 'Carrito de Apartado',
      ModoOperacion.cobrar => 'Cuentas por Cobrar',
    };

    final colorPrincipal = switch (modo) {
      ModoOperacion.venta => AppColors.primary,
      ModoOperacion.cotizacion => AppColors.info,
      ModoOperacion.apartado => AppColors.warning,
      ModoOperacion.cobrar => AppColors.error,
    };

    if (venta.detalles.isEmpty) {
      return _CarritoVacio(colorPrincipal: colorPrincipal);
    }

    return Column(
      children: [
        // ── HEADER ──
        Container(
          padding: EdgeInsets.fromLTRB(isMobile ? 16 : 20, 14, isMobile ? 8 : 12, 12),
          color: AppColors.white,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorPrincipal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.shopping_cart_rounded, color: colorPrincipal, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: AppTypography.h4.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${venta.detalles.length} ${venta.detalles.length == 1 ? 'artículo' : 'artículos'}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => ref.read(registrarVentaProvider.notifier).vaciarVenta(),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: isMobile ? const SizedBox.shrink() : const Text('Vaciar'),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),

        // ── LISTA ──
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: venta.detalles.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16),
            itemBuilder: (context, i) => _FilaProducto(
              linea: venta.detalles[i],
              indice: i,
              colorPrincipal: colorPrincipal,
            ),
          ),
        ),

        // ── RESUMEN + BOTÓN ──
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(isMobile ? 16 : 20, 16, isMobile ? 16 : 20, isMobile ? 16 : 20),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: const Border(top: BorderSide(color: AppColors.border)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FilaTotal(etiqueta: 'Subtotal', valor: formatearMonto(venta.subtotal)),
              const SizedBox(height: 6),
              if (!(ref.watch(configuracionControllerProvider).valueOrNull?.modoSimplificado ?? false))
                _FilaTotal(etiqueta: 'ITBIS', valor: formatearMonto(venta.itbis)),
              if (venta.montoDescuento > 0) ...[
                const SizedBox(height: 6),
                _FilaTotal(
                  etiqueta: 'Descuento',
                  valor: '- ${formatearMonto(venta.montoDescuento)}',
                  color: AppColors.success,
                ),
              ],
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 10),
              _FilaTotal(
                etiqueta: 'TOTAL A PAGAR',
                valor: formatearMonto(venta.total),
                resaltado: true,
                colorPrincipal: colorPrincipal,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(ventasNavegacionProvider.notifier).cambiarVista(VistaActual.inicio);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorPrincipal,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment_rounded, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'SELECCIONAR FORMA DE PAGO',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
class _CarritoVacio extends ConsumerWidget {
  const _CarritoVacio({required this.colorPrincipal});
  final Color colorPrincipal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: colorPrincipal.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shopping_cart_outlined, size: 44, color: colorPrincipal.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 20),
            Text(
              'Carrito vacío',
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega productos desde el catálogo\npara iniciar la operación',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => ref.read(ventasNavegacionProvider.notifier).cambiarVista(VistaActual.inventario),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('AGREGAR PRODUCTOS'),
              style: FilledButton.styleFrom(
                backgroundColor: colorPrincipal,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _FilaProducto extends ConsumerWidget {
  const _FilaProducto({
    required this.linea,
    required this.indice,
    required this.colorPrincipal,
  });

  final DetalleVenta linea;
  final int indice;
  final Color colorPrincipal;

  String formatearMonto(double valor) =>
      'RD\$${NumberFormat('#,##0.00', 'es_DO').format(valor)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = AppBreakpoints.isMobile(context);
    final subtotal = linea.subtotalLinea ?? linea.subtotal;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 18, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Nombre + precio unitario
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  linea.nombreProducto ?? 'Producto',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${formatearMonto(linea.precioUnitario)} c/u',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          // Controles cantidad
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QtyBtn(
                  icon: Icons.remove,
                  onTap: () => ref.read(registrarVentaProvider.notifier).cambiarCantidad(indice, linea.cantidad - 1),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    '${linea.cantidad}',
                    textAlign: TextAlign.center,
                    style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                _QtyBtn(
                  icon: Icons.add,
                  onTap: () => ref.read(registrarVentaProvider.notifier).cambiarCantidad(indice, linea.cantidad + 1),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Subtotal
          SizedBox(
            width: isMobile ? 78 : 92,
            child: Text(
              formatearMonto(subtotal),
              textAlign: TextAlign.right,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: colorPrincipal,
                fontSize: 14,
              ),
            ),
          ),

          // Eliminar
          IconButton(
            onPressed: () => ref.read(registrarVentaProvider.notifier).eliminarProducto(indice),
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppColors.error,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _FilaTotal extends StatelessWidget {
  const _FilaTotal({
    required this.etiqueta,
    required this.valor,
    this.resaltado = false,
    this.color,
    this.colorPrincipal,
  });

  final String etiqueta;
  final String valor;
  final bool resaltado;
  final Color? color;
  final Color? colorPrincipal;

  @override
  Widget build(BuildContext context) {
    final c = color ?? (resaltado ? (colorPrincipal ?? AppColors.primary) : AppColors.textSecondary);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          etiqueta,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: resaltado ? FontWeight.bold : FontWeight.w500,
            fontSize: resaltado ? 15 : 13.5,
            color: c,
          ),
        ),
        Text(
          valor,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: resaltado ? 18 : 14,
            color: resaltado ? (colorPrincipal ?? AppColors.primary) : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
