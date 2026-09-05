import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_entity.dart';
import 'package:fiscogest_rd/features/clientes/presentation/widgets/seleccionar_cliente_dialog.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/ventas_navegacion_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_usecase_provider.dart';

class VistaInicioVacia extends ConsumerStatefulWidget {
  const VistaInicioVacia({super.key});

  @override
  ConsumerState<VistaInicioVacia> createState() => _VistaInicioVaciaState();
}

class _VistaInicioVaciaState extends ConsumerState<VistaInicioVacia> {
  static final NumberFormat _formatoMonto = NumberFormat.currency(
    locale: 'es_DO',
    symbol: 'RD\$ ',
    decimalDigits: 2,
    customPattern: '¤ #,##0.00',
  );
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(registrarVentaProvider.notifier).establecerConsumidorFinal();
    });
  }

  Future<void> _cambiarCliente() async {
    final ClienteEntity? cliente = await SeleccionarClienteDialog.mostrar(context);
    if (cliente != null && mounted) {
      ref.read(registrarVentaProvider.notifier).seleccionarCliente(cliente.id ?? 0, cliente.nombre);
    }
  }

  Future<void> _cobrar() async {
    final estado = ref.read(registrarVentaProvider);
    final valido = ref.read(registrarVentaProvider.notifier).validarAntesDeGuardar();

    if (!valido) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Agregue productos y seleccione forma de pago')),
        );
      }
      return;
    }

    const formasPago = ['Efectivo', 'Tarjeta', 'Crédito', 'Transferencia', 'Cheque'];

    final formaSeleccionada = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forma de Pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: ${_formatoMonto.format(estado.total)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 16),
            ...formasPago.map((forma) => ListTile(
              title: Text(forma),
              onTap: () => Navigator.pop(context, forma.toLowerCase()),
            )),
          ],
        ),
      ),
    );

    if (formaSeleccionada == null) return;

    ref.read(registrarVentaProvider.notifier).cambiarFormaPago(formaSeleccionada);
    final estadoFinal = ref.read(registrarVentaProvider);

    setState(() => _guardando = true);

    try {
      final ventaGuardada = await ref.read(registrarVentaUseCaseProvider).ejecutar(estadoFinal);

      if (ventaGuardada.id == null) {
        throw Exception('El repositorio no devolvió ID de venta');
      }

      if (mounted) {
        ref.read(registrarVentaProvider.notifier).vaciarVenta();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Venta #${ventaGuardada.numero} registrada — ${_formatoMonto.format(ventaGuardada.total)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final modo = ref.watch(ventasNavegacionProvider.select((e) => e.modoOperacion));
    final estado = ref.watch(registrarVentaProvider);

    final titulo = switch (modo) {
      ModoOperacion.venta => 'NUEVA VENTA',
      ModoOperacion.cotizacion => 'NUEVA COTIZACIÓN',
      ModoOperacion.apartado => 'NUEVO APARTADO',
      ModoOperacion.cobrar => 'CUENTAS POR COBRAR',
    };

    final colorPrimario = switch (modo) {
      ModoOperacion.venta => AppColors.primary,
      ModoOperacion.cotizacion => AppColors.info,
      ModoOperacion.apartado => AppColors.success,
      ModoOperacion.cobrar => AppColors.warning,
    };

    final nombreCliente = estado.clienteNombre?.isNotEmpty == true
        ? estado.clienteNombre!
        : 'Consumidor Final';

    final tieneProductos = estado.detalles.isNotEmpty;
    final montoTotal = _formatoMonto.format(estado.total);
    final tieneDescuento = estado.montoDescuento > 0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  titulo,
                  style: AppTypography.h4.copyWith(color: colorPrimario, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => ref.read(ventasNavegacionProvider.notifier).cambiarVista(VistaActual.historial),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('Historial'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),

            SizedBox(
              width: 420,
              child: GestureDetector(
                onTap: () => ref.read(ventasNavegacionProvider.notifier).cambiarVista(VistaActual.inventario),
                child: const AbsorbPointer(
                  child: AppTextField(
                    hint: 'Buscar producto, código o escanear',
                    prefixIcon: Icons.search,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            const Divider(),
            const SizedBox(height: AppSpacing.m),

            if (!tieneProductos)
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.point_of_sale_outlined, size: 56, color: AppColors.grey400),
                    SizedBox(height: AppSpacing.m),
                    Text('La venta está vacía', style: AppTypography.labelLarge),
                    SizedBox(height: AppSpacing.s),
                    Text('Busca un producto para comenzar', style: AppTypography.bodyMedium),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: estado.detalles.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final linea = estado.detalles[index];
                  final nombre = linea.nombreProducto ?? 'Producto';
                  final precioUnit = linea.precioUnitario;
                  final subtotalLinea = _formatoMonto.format(linea.subtotal);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nombre, style: AppTypography.labelMedium),
                              Text(
                                'Precio aplicado: ${_formatoMonto.format(precioUnit)}',
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: AppColors.grey600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: IconButton.filled(
                                padding: EdgeInsets.zero,
                                iconSize: 16,
                                onPressed: _guardando ? null : () => ref
                                    .read(registrarVentaProvider.notifier)
                                    .cambiarCantidad(index, linea.cantidad - 1),
                                icon: const Icon(Icons.remove),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  foregroundColor: AppColors.primary,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 36,
                              child: Text('${linea.cantidad}',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold)),
                            ),
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: IconButton.filled(
                                padding: EdgeInsets.zero,
                                iconSize: 16,
                                onPressed: _guardando ? null : () => ref
                                    .read(registrarVentaProvider.notifier)
                                    .cambiarCantidad(index, linea.cantidad + 1),
                                icon: const Icon(Icons.add),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  foregroundColor: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 4,
                          child: Text(subtotalLinea,
                              textAlign: TextAlign.right,
                              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: AppSpacing.m),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.l),

            AppButton(
              text: '+ AGREGAR PRODUCTO',
              icon: Icons.add,
              onPressed: _guardando ? null : () => ref
                  .read(ventasNavegacionProvider.notifier)
                  .cambiarVista(VistaActual.inventario),
            ),

            const SizedBox(height: AppSpacing.l),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(nombreCliente, style: AppTypography.labelMedium),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 26,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      backgroundColor: colorPrimario,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      textStyle: const TextStyle(fontSize: 11),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _guardando ? null : _cambiarCliente,
                    child: const Text('Cambiar'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            if (tieneProductos)
              SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Subtotal: ${_formatoMonto.format(estado.subtotal)}', style: AppTypography.labelMedium),
                    if (tieneDescuento) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Descuento${estado.descuentoNombre?.isNotEmpty == true ? " (${estado.descuentoNombre})" : ""}: -${_formatoMonto.format(estado.montoDescuento)}',
                        style: AppTypography.labelMedium.copyWith(color: Colors.red.shade700),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text('ITBIS (18%): ${_formatoMonto.format(estado.itbis)}', style: AppTypography.labelMedium),
                    const SizedBox(height: 8),
                    Text('TOTAL: $montoTotal',
                        style: AppTypography.h4.copyWith(fontWeight: FontWeight.w900, color: colorPrimario)),
                  ],
                ),
              ),

            const SizedBox(height: AppSpacing.m),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                      backgroundColor: colorPrimario,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.grey200,
                      disabledForegroundColor: AppColors.grey400,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: tieneProductos && !_guardando ? _cobrar : null,
                    child: _guardando
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                tieneProductos ? 'COBRAR' : 'AGREGUE PRODUCTOS',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                              ),
                              const SizedBox(height: 4),
                              Text(montoTotal, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, height: 1.1)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
