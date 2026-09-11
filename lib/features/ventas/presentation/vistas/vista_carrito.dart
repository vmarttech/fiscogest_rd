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
    final numero = NumberFormat('#,##0.00', 'es_DO').format(valor);
    return 'RD\$ $numero';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ PATRÓN RESPONSIVO
    final anchoPantalla = MediaQuery.of(context).size.width;
    final esPantallaPequena = anchoPantalla < 600;

    final paddingSuperior = esPantallaPequena
        ? const EdgeInsets.fromLTRB(12, 12, 12, 6)
        : const EdgeInsets.fromLTRB(16, 16, 16, 8);
    final paddingLista = esPantallaPequena
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    final paddingInferior = esPantallaPequena
        ? const EdgeInsets.all(12)
        : const EdgeInsets.all(16);
    final paddingBotonPago = esPantallaPequena
        ? const EdgeInsets.symmetric(vertical: 12)
        : const EdgeInsets.symmetric(vertical: 16);
    final fontSizeBotonPago = esPantallaPequena ? 13.0 : 16.0;
    final tamanoIconoBotonPago = esPantallaPequena ? 18.0 : 22.0;
    final fontSizeTitulo = esPantallaPequena
        ? AppTypography.labelLarge
        : AppTypography.h4;
    final tamanoIconoVaciar = esPantallaPequena ? 16.0 : 18.0;
    final espaciadoDespuesDivisor = esPantallaPequena ? 4.0 : 8.0;
    final espaciadoAntesTotal = esPantallaPequena ? 12.0 : 20.0;

    final venta = ref.watch(registrarVentaProvider);
    final modo = ref.watch(
      ventasNavegacionProvider.select((e) => e.modoOperacion),
    );

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
          padding: paddingSuperior, // ✅ AHORA ADAPTATIVO
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo,
                style: fontSizeTitulo.copyWith(
                  color: colorPrincipal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    ref.read(registrarVentaProvider.notifier).vaciarVenta(),
                icon: Icon(
                  Icons.delete_outline,
                  size: tamanoIconoVaciar,
                ), // ✅ AHORA ADAPTATIVO
                label: const Text('Vaciar'),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: paddingLista, // ✅ AHORA ADAPTATIVO
            itemCount: venta.detalles.length,
            itemBuilder: (context, i) =>
                _FilaProducto(linea: venta.detalles[i], indice: i),
          ),
        ),
        const Divider(height: 1),
        Container(
          width: double.infinity,
          padding: paddingInferior, // ✅ AHORA ADAPTATIVO
          color: AppColors.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FilaTotal(
                etiqueta: 'Subtotal',
                valor: formatearMonto(venta.subtotal),
              ),
              SizedBox(height: espaciadoDespuesDivisor), // ✅ AHORA ADAPTATIVO
              _FilaTotal(etiqueta: 'ITBIS', valor: formatearMonto(venta.itbis)),
              if (venta.montoDescuento > 0) ...[
                SizedBox(height: espaciadoDespuesDivisor), // ✅ AHORA ADAPTATIVO
                _FilaTotal(
                  etiqueta: 'Descuento',
                  valor: '- ${formatearMonto(venta.montoDescuento)}',
                ),
              ],
              SizedBox(
                height: espaciadoDespuesDivisor * 2,
              ), // ✅ AHORA ADAPTATIVO
              const Divider(),
              SizedBox(height: espaciadoDespuesDivisor), // ✅ AHORA ADAPTATIVO
              _FilaTotal(
                etiqueta: 'TOTAL',
                valor: formatearMonto(venta.total),
                resaltado: true,
              ),
              SizedBox(height: espaciadoAntesTotal), // ✅ AHORA ADAPTATIVO
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref
                        .read(ventasNavegacionProvider.notifier)
                        .cambiarVista(VistaActual.inicio);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorPrincipal,
                    foregroundColor: Colors.white,
                    padding: paddingBotonPago, // ✅ AHORA ADAPTATIVO
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    Icons.payment,
                    size: tamanoIconoBotonPago,
                  ), // ✅ AHORA ADAPTATIVO
                  label: Text(
                    'SELECCIONAR FORMA DE PAGO',
                    style: TextStyle(
                      fontSize: fontSizeBotonPago, // ✅ AHORA ADAPTATIVO
                      fontWeight: FontWeight.bold,
                    ),
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

class _CarritoVacio extends ConsumerWidget {
  const _CarritoVacio();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ PATRÓN RESPONSIVO
    final anchoPantalla = MediaQuery.of(context).size.width;
    final esPantallaPequena = anchoPantalla < 600;

    final paddingContenedor = esPantallaPequena
        ? const EdgeInsets.all(20)
        : const EdgeInsets.all(32);
    final tamanoIcono = esPantallaPequena ? 48.0 : 72.0;
    final espaciadoDespuesIcono = esPantallaPequena ? 12.0 : 16.0;
    final espaciadoEntreTextos = esPantallaPequena ? 6.0 : 8.0;
    final espaciadoAntesBoton = esPantallaPequena ? 20.0 : 32.0;
    final paddingBoton = esPantallaPequena
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
    final estiloTitulo = esPantallaPequena
        ? AppTypography.labelMedium
        : AppTypography.labelLarge;
    final estiloSubtitulo = esPantallaPequena
        ? AppTypography.labelSmall
        : AppTypography.bodyMedium;

    return Center(
      child: SingleChildScrollView(
        padding: paddingContenedor, // ✅ AHORA ADAPTATIVO
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: tamanoIcono, // ✅ AHORA ADAPTATIVO
              color: AppColors.grey400,
            ),
            SizedBox(height: espaciadoDespuesIcono), // ✅ AHORA ADAPTATIVO
            Text(
              'No hay productos agregados',
              style: estiloTitulo, // ✅ AHORA ADAPTATIVO
              textAlign: TextAlign.center,
            ),
            SizedBox(height: espaciadoEntreTextos), // ✅ AHORA ADAPTATIVO
            Text(
              'Busca y agrega productos desde el catálogo',
              style: estiloSubtitulo, // ✅ AHORA ADAPTATIVO
              textAlign: TextAlign.center,
            ),
            SizedBox(height: espaciadoAntesBoton), // ✅ AHORA ADAPTATIVO
            FilledButton.icon(
              onPressed: () => ref
                  .read(ventasNavegacionProvider.notifier)
                  .cambiarVista(VistaActual.inventario),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('AGREGAR PRODUCTOS'),
              style: FilledButton.styleFrom(
                padding: paddingBoton,
              ), // ✅ AHORA ADAPTATIVO
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
    // ✅ PATRÓN RESPONSIVO
    final anchoPantalla = MediaQuery.of(context).size.width;
    final esPantallaPequena = anchoPantalla < 600;

    final margenTarjeta = esPantallaPequena
        ? const EdgeInsets.symmetric(vertical: 4)
        : const EdgeInsets.symmetric(vertical: 6);
    final paddingTarjeta = esPantallaPequena
        ? const EdgeInsets.all(8)
        : const EdgeInsets.all(12);
    final tamanoIconosCantidad = esPantallaPequena ? 18.0 : 20.0;
    final tamanoIconoEliminar = esPantallaPequena ? 16.0 : 18.0;
    final anchoCantidad = esPantallaPequena ? 24.0 : 28.0;
    final anchoBotonEliminar = esPantallaPequena ? 24.0 : 28.0;
    final minSizeBotones = esPantallaPequena ? 32.0 : 36.0;
    final espaciadoEntreCantidadYPrecio = esPantallaPequena ? 4.0 : 8.0;
    final espaciadoAntesEliminar = esPantallaPequena ? 2.0 : 4.0;
    final estiloNombre = esPantallaPequena
        ? AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)
        : AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600);
    final estiloPrecioUnit = esPantallaPequena
        ? AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)
        : AppTypography.bodySmall.copyWith(color: AppColors.textSecondary);
    final estiloSubtotal = esPantallaPequena
        ? AppTypography.bodyMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          )
        : AppTypography.labelMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          );

    final subtotalMostrar = linea.subtotalLinea ?? linea.subtotal;

    return Card(
      elevation: 1,
      margin: margenTarjeta, // ✅ AHORA ADAPTATIVO
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: paddingTarjeta, // ✅ AHORA ADAPTATIVO
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    linea.nombreProducto ?? 'Producto',
                    style: estiloNombre, // ✅ AHORA ADAPTATIVO
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatearMonto(linea.precioUnitario)} c/u',
                    style: estiloPrecioUnit, // ✅ AHORA ADAPTATIVO
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => ref
                      .read(registrarVentaProvider.notifier)
                      .cambiarCantidad(indice, linea.cantidad - 1),
                  icon: Icon(
                    Icons.remove_circle_outline,
                    size: tamanoIconosCantidad, // ✅ AHORA ADAPTATIVO
                    color: AppColors.primary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: minSizeBotones, // ✅ AHORA ADAPTATIVO
                    minHeight: minSizeBotones,
                  ),
                ),
                SizedBox(
                  width: anchoCantidad, // ✅ AHORA ADAPTATIVO
                  child: Text(
                    '${linea.cantidad}',
                    textAlign: TextAlign.center,
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => ref
                      .read(registrarVentaProvider.notifier)
                      .cambiarCantidad(indice, linea.cantidad + 1),
                  icon: Icon(
                    Icons.add_circle_outline,
                    size: tamanoIconosCantidad, // ✅ AHORA ADAPTATIVO
                    color: AppColors.primary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: minSizeBotones, // ✅ AHORA ADAPTATIVO
                    minHeight: minSizeBotones,
                  ),
                ),
              ],
            ),
            SizedBox(
              width: espaciadoEntreCantidadYPrecio,
            ), // ✅ AHORA ADAPTATIVO
            Expanded(
              flex: 2,
              child: Text(
                formatearMonto(subtotalMostrar),
                textAlign: TextAlign.right,
                style: estiloSubtotal, // ✅ AHORA ADAPTATIVO
              ),
            ),
            SizedBox(width: espaciadoAntesEliminar), // ✅ AHORA ADAPTATIVO
            SizedBox(
              width: anchoBotonEliminar, // ✅ AHORA ADAPTATIVO
              height: anchoBotonEliminar,
              child: IconButton(
                onPressed: () => ref
                    .read(registrarVentaProvider.notifier)
                    .eliminarProducto(indice),
                icon: Icon(
                  Icons.close,
                  size: tamanoIconoEliminar, // ✅ AHORA ADAPTATIVO
                  color: AppColors.error,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatearMonto(double valor) =>
      'RD\$${NumberFormat('#,##0.00', 'es_DO').format(valor)}';
}

class _FilaTotal extends StatelessWidget {
  const _FilaTotal({
    required this.etiqueta,
    required this.valor,
    this.resaltado = false,
  });
  final String etiqueta;
  final String valor;
  final bool resaltado;

  @override
  Widget build(BuildContext context) {
    // ✅ PATRÓN RESPONSIVO
    final anchoPantalla = MediaQuery.of(context).size.width;
    final esPantallaPequena = anchoPantalla < 600;

    final fontSizeResaltado = esPantallaPequena ? 15.0 : 18.0;
    final fontSizeNormal = esPantallaPequena ? 12.0 : 14.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          etiqueta,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: resaltado ? FontWeight.bold : FontWeight.normal,
            fontSize: resaltado
                ? fontSizeResaltado
                : fontSizeNormal, // ✅ AHORA ADAPTATIVO
            color: resaltado ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        Text(
          valor,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: resaltado ? FontWeight.bold : FontWeight.w500,
            fontSize: resaltado
                ? fontSizeResaltado
                : fontSizeNormal, // ✅ AHORA ADAPTATIVO
            color: resaltado ? AppColors.primary : null,
          ),
        ),
      ],
    );
  }
}
