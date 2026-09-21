import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/ventas_navegacion_provider.dart';

class VistaCarrito extends ConsumerWidget {
  const VistaCarrito({super.key});

  String formatearMonto(double valor) {
    final numero = NumberFormat('#,##0.00', 'es_DO').format(valor);
    return 'RD\$ $numero';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = AppBreakpoints.isMobile(context);
    final venta = ref.watch(registrarVentaProvider);
    final modo = ref.watch(
      ventasNavegacionProvider.select((e) => e.modoOperacion),
    );

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
        // ─── HEADER ───
        Container(
          padding: EdgeInsets.fromLTRB(isMobile ? 16 : 20, 14, isMobile ? 12 : 16, 12),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorPrincipal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.shopping_cart_rounded, color: colorPrincipal, size: 20),
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
                        fontSize: isMobile ? 15 : 16,
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
                label: Text(isMobile ? '' : 'Vaciar'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12),
                ),
              ),
            ],
          ),
        ),

        // ─── LISTA DE PRODUCTOS ───
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: 12,
            ),
            itemCount: venta.detalles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _FilaProducto(
              linea: venta.detalles[i],
              indice: i,
              colorPrincipal: colorPrincipal,
            ),
          ),
        ),

        // ─── RESUMEN + BOTÓN ───
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            isMobile ? 16 : 20,
            16,
            isMobile ? 16 : 20,
            isMobile ? 16 : 20,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: const Border(top: BorderSide(color: AppColors.border)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FilaTotal(etiqueta: 'Subtotal', valor: formatearMonto(venta.subtotal)),
              const SizedBox(height: 6),
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
              const Divider(height: 1),
              const SizedBox(height: 10),
              _FilaTotal(
                etiqueta: 'TOTAL',
                valor: formatearMonto(venta.total),
                resaltado: true,
                colorPrincipal: colorPrincipal,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: isMobile ? 48 : 52,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(ventasNavegacionProvider.notifier).cambiarVista(VistaActual.inicio);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorPrincipal,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.payment_rounded, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'SELECCIONAR FORMA DE PAGO',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
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
// CARRITO VACÍO
// ─────────────────────────────────────────────
class _CarritoVacio extends ConsumerWidget {

  const _CarritoVacio({required this.colorPrincipal});
  final Color colorPrincipal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = AppBreakpoints.isMobile(context);

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 24 : 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isMobile ? 80 : 96,
              height: isMobile ? 80 : 96,
              decoration: BoxDecoration(
                color: colorPrincipal.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: isMobile ? 40 : 48,
                color: colorPrincipal.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Carrito vacío',
              style: AppTypography.h3.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Busca y agrega productos desde el catálogo\npara comenzar la operación',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => ref
                  .read(ventasNavegacionProvider.notifier)
                  .cambiarVista(VistaActual.inventario),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text('AGREGAR PRODUCTOS'),
              style: FilledButton.styleFrom(
                backgroundColor: colorPrincipal,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 28,
                  vertical: isMobile ? 12 : 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FILA DE PRODUCTO
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
    final subtotalMostrar = linea.subtotalLinea ?? linea.subtotal;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.allL,
        border: Border.all(color: AppColors.border),
      ),
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
                    fontSize: isMobile ? 13.5 : 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatearMonto(linea.precioUnitario)} c/u',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Controles de cantidad
          Container(
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CantidadButton(
                  icon: Icons.remove,
                  onTap: () => ref
                      .read(registrarVentaProvider.notifier)
                      .cambiarCantidad(indice, linea.cantidad - 1),
                  color: colorPrincipal,
                ),
                SizedBox(
                  width: isMobile ? 28 : 32,
                  child: Text(
                    '${linea.cantidad}',
                    textAlign: TextAlign.center,
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _CantidadButton(
                  icon: Icons.add,
                  onTap: () => ref
                      .read(registrarVentaProvider.notifier)
                      .cambiarCantidad(indice, linea.cantidad + 1),
                  color: colorPrincipal,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Subtotal
          SizedBox(
            width: isMobile ? 72 : 88,
            child: Text(
              formatearMonto(subtotalMostrar),
              textAlign: TextAlign.right,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: colorPrincipal,
                fontSize: isMobile ? 13 : 14,
              ),
            ),
          ),

          // Eliminar
          IconButton(
            onPressed: () => ref
                .read(registrarVentaProvider.notifier)
                .eliminarProducto(indice),
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppColors.error,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Eliminar',
          ),
        ],
      ),
    );
  }
}

class _CantidadButton extends StatelessWidget {

  const _CantidadButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FILA DE TOTAL
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
    final isMobile = AppBreakpoints.isMobile(context);
    final effectiveColor = color ??
        (resaltado
            ? (colorPrincipal ?? AppColors.primary)
            : AppColors.textSecondary);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          etiqueta,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: resaltado ? FontWeight.bold : FontWeight.normal,
            fontSize: resaltado ? (isMobile ? 15 : 16) : (isMobile ? 13 : 14),
            color: effectiveColor,
          ),
        ),
        Text(
          valor,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: resaltado ? FontWeight.bold : FontWeight.w600,
            fontSize: resaltado ? (isMobile ? 16 : 18) : (isMobile ? 13 : 14),
            color: resaltado
                ? (colorPrincipal ?? AppColors.primary)
                : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
