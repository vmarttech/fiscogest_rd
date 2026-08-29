import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:fiscogest_rd/features/clientes/presentation/widgets/seleccionar_cliente_dialog.dart';
import 'package:fiscogest_rd/features/inventario/presentation/pages/productos_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_dialog.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/oferta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/formulario_venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/panel_productos.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/panel_carrito.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';

class RegistrarVentaPage extends ConsumerStatefulWidget {
  const RegistrarVentaPage({super.key});
  static const String routeName = 'registrar-ventas';

  @override
  ConsumerState<RegistrarVentaPage> createState() => _RegistrarVentaPageState();
}

class _RegistrarVentaPageState extends ConsumerState<RegistrarVentaPage> {
  final TextEditingController _buscadorController = TextEditingController();
  String _ventaNumero = '';
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _ventaNumero = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
  }

  @override
  void dispose() {
    _buscadorController.dispose();
    super.dispose();
  }

  Oferta? _buscarOfertaAplicable(List<Oferta> ofertas, int productoId, double cantidad) {
    for (final oferta in ofertas) {
      if (oferta.productoId == productoId && cantidad >= oferta.cantidadMinima) {
        return oferta;
      }
    }
    return null;
  }

  Future<void> _buscarYAgregarProducto(String termino) async {
    final resultados = await ref
        .read(productoControllerProvider.notifier)
        .buscarPorNombre(termino);
    final ofertasActivas = await ref.watch(ofertasActivosProvider.future);
    final List<Oferta> listaOfertas = ofertasActivas.cast<Oferta>();

    if (resultados.isEmpty && mounted) {
      await AppDialog.show<void>(
        context,
        title: 'Producto no encontrado',
        message: 'No hay coincidencias. ¿Desea abrir el inventario completo?',
        actions: [
          AppButton(
            text: 'Cancelar',
            onPressed: () => Navigator.pop(context),
            width: 120,
          ),
          AppButton(
            text: 'Abrir Inventario',
            onPressed: () {
              Navigator.pop(context);
              context.pushNamed(ProductosPage.routeName);
            },
            width: 160,
          ),
        ],
      );
      return;
    }

    if (resultados.length == 1 && mounted) {
      final p = resultados.first;
      if ((p.stock ?? 0) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${p.nombre}" sin existencias disponibles'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      final oferta = _buscarOfertaAplicable(listaOfertas, p.id ?? 0, 1);
      final double precioUnitario = (oferta != null) ? oferta.precioOferta : p.precioVenta.toDouble();
      final double subtotal = precioUnitario * 1;
      final double? precioOriginal = (oferta != null) ? p.precioVenta.toDouble() : null;
      final String? ofertaId = (oferta != null) ? oferta.id.toString() : null;
      final String? ofertaNombre = (oferta != null) ? oferta.nombre : null;

      final linea = DetalleVenta(
        productoId: p.id ?? 0,
        nombreProducto: p.nombre,
        cantidad: 1,
        precioUnitario: precioUnitario,
        subtotal: subtotal,
        subtotalLinea: subtotal,
        ofertaId: ofertaId,
        ofertaNombre: ofertaNombre,
        precioOriginal: precioOriginal,
      );

      ref.read(registrarVentaProvider.notifier).agregarProducto(linea);
      _buscadorController.clear();

      if (oferta != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Oferta aplicada: ${oferta.nombre}'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } else if (mounted) {
      await AppDialog.show<void>(
        context,
        title: 'Seleccione Producto',
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: resultados.length + 1,
            itemBuilder: (ctx, i) {
              if (i == resultados.length) {
                return ListTile(
                  leading: const Icon(Icons.inventory_2, color: AppColors.primary),
                  title: const Text('Abrir Inventario completo', style: AppTypography.bodyMedium),
                  subtitle: const Text('Ver todos los productos', style: AppTypography.bodySmall),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.pushNamed(ProductosPage.routeName);
                  },
                );
              }

              final p = resultados[i];
              final oferta = _buscarOfertaAplicable(listaOfertas, p.id ?? 0, 1);
              final hayStock = (p.stock ?? 0) > 0;

              return ListTile(
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.nombre,
                        style: AppTypography.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!hayStock)
                      Container(
                        margin: const EdgeInsets.only(left: AppSpacing.s),
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.s),
                        ),
                        child: Text(
                          'SIN STOCK',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    if (oferta != null && hayStock)
                      Container(
                        margin: const EdgeInsets.only(left: AppSpacing.s),
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.s),
                        ),
                        child: Text(
                          'OFERTA',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  hayStock
                      ? (oferta != null
                          ? 'Oferta: RD\$ ${oferta.precioOferta.toStringAsFixed(2)} (antes RD\$ ${p.precioVenta.toStringAsFixed(2)}) — Stock: ${p.stock ?? 0}'
                          : 'RD\$ ${p.precioVenta.toStringAsFixed(2)} — Stock: ${p.stock ?? 0}')
                      : 'Sin existencias',
                  style: AppTypography.bodySmall,
                ),
                enabled: hayStock,
                onTap: hayStock
                    ? () {
                        final double precioUnitario = (oferta != null) ? oferta.precioOferta : p.precioVenta.toDouble();
                        final double subtotal = precioUnitario * 1;
                        final double? precioOriginal = (oferta != null) ? p.precioVenta.toDouble() : null;
                        final String? ofertaId = (oferta != null) ? oferta.id.toString() : null;
                        final String? ofertaNombre = (oferta != null) ? oferta.nombre : null;

                        final linea = DetalleVenta(
                          productoId: p.id ?? 0,
                          nombreProducto: p.nombre,
                          cantidad: 1,
                          precioUnitario: precioUnitario,
                          subtotal: subtotal,
                          subtotalLinea: subtotal,
                          ofertaId: ofertaId,
                          ofertaNombre: ofertaNombre,
                          precioOriginal: precioOriginal,
                        );

                        ref.read(registrarVentaProvider.notifier).agregarProducto(linea);
                        _buscadorController.clear();
                        Navigator.pop(ctx);

                        if (oferta != null && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Oferta aplicada: ${oferta.nombre}'),
                              backgroundColor: AppColors.warning,
                            ),
                          );
                        }
                      }
                    : null,
              );
            },
          ),
        ),
      );
    }
  }

  void _abrirSelectorFormaPago() {
    AppDialog.show<void>(
      context,
      title: 'Forma de Pago',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Efectivo', style: AppTypography.bodyMedium),
            onTap: () {
              ref.read(registrarVentaProvider.notifier).cambiarFormaPago('efectivo');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Tarjeta', style: AppTypography.bodyMedium),
            onTap: () {
              ref.read(registrarVentaProvider.notifier).cambiarFormaPago('tarjeta');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Transferencia', style: AppTypography.bodyMedium),
            onTap: () {
              ref.read(registrarVentaProvider.notifier).cambiarFormaPago('transferencia');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Crédito', style: AppTypography.bodyMedium),
            onTap: () {
              ref.read(registrarVentaProvider.notifier).cambiarFormaPago('credito');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Cheque', style: AppTypography.bodyMedium),
            onTap: () {
              ref.read(registrarVentaProvider.notifier).cambiarFormaPago('cheque');
              Navigator.pop(context);
            },
          ),
        ],
      ),
      actions: [],
    );
  }

  void _abrirSelectorCliente() {
    AppDialog.show<void>(
      context,
      title: 'Seleccionar Cliente',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Consumidor Final', style: AppTypography.bodyMedium),
            onTap: () {
              ref.read(registrarVentaProvider.notifier).seleccionarCliente(1, 'Consumidor Final');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Buscar Cliente...', style: AppTypography.bodyMedium),
            subtitle: const Text('Ver lista de clientes registrados', style: AppTypography.bodySmall),
            onTap: () async {
              Navigator.pop(context);
              final cliente = await SeleccionarClienteDialog.mostrar(context);
              if (cliente != null && context.mounted) {
                ref.read(registrarVentaProvider.notifier).seleccionarCliente(
                  cliente.id ?? 0,
                  cliente.nombre,
                );
              }
            },
          ),
        ],
      ),
      actions: [],
    );
  }

  void _limpiarVenta() {
    AppDialog.show<void>(
      context,
      title: 'Limpiar Venta',
      message: '¿Desea reiniciar la venta actual?',
      actions: [
        AppButton(
          text: 'Cancelar',
          onPressed: () => Navigator.pop(context),
          width: 120,
        ),
        AppButton(
          text: 'Aceptar',
          onPressed: () {
            ref.read(registrarVentaProvider.notifier).vaciarVenta();
            _buscadorController.clear();
            Navigator.pop(context);
          },
          width: 120,
        ),
      ],
    );
  }

  Future<void> _cobrarYRegistrarSalida() async {
    final estado = ref.read(registrarVentaProvider);
    if (!ref.read(registrarVentaProvider.notifier).validarAntesDeGuardar()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete los datos: Cliente, Forma de Pago y al menos un producto'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _cargando = true);
    try {
      final casoUso = ref.read(registrarVentaUseCaseProvider);
      final ventaGuardada = await casoUso.ejecutar(estado);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Venta registrada. Nº $_ventaNumero — ID: $ventaGuardada'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(registrarVentaProvider.notifier).vaciarVenta();
        _buscadorController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(registrarVentaProvider);
    return AppScaffold(
      padding: AppSpacing.hL.copyWith(top: AppSpacing.m, bottom: AppSpacing.l),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Nueva Venta',
                                style: AppTypography.h4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s),
                            Text(
                              'Nº $_ventaNumero',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      PanelProductos(
                        controlador: _buscadorController,
                        alBuscar: _buscarYAgregarProducto,
                      ),
                      const SizedBox(height: AppSpacing.m),
                      FormularioVenta(
                        alSeleccionarCliente: _abrirSelectorCliente,
                        alSeleccionarFormaPago: _abrirSelectorFormaPago,
                      ),
                      const SizedBox(height: AppSpacing.m),
                      const PanelCarrito(),
                      const SizedBox(height: AppSpacing.l),
                      LayoutBuilder(
                        builder: (context, rowConstraints) {
                          if (rowConstraints.maxWidth < 500) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppButton(
                                  text: 'Limpiar Venta',
                                  onPressed: _limpiarVenta,
                                  icon: Icons.refresh,
                                ),
                                const SizedBox(height: AppSpacing.s),
                                AppButton(
                                  text: _cargando ? 'Guardando...' : 'Registrar Venta',
                                  onPressed: _cargando ? null : _cobrarYRegistrarSalida,
                                  isLoading: _cargando,
                                  icon: Icons.save,
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  text: 'Limpiar Venta',
                                  onPressed: _limpiarVenta,
                                  icon: Icons.refresh,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.m),
                              Expanded(
                                child: AppButton(
                                  text: _cargando ? 'Guardando...' : 'Registrar Venta',
                                  onPressed: _cargando ? null : _cobrarYRegistrarSalida,
                                  isLoading: _cargando,
                                  icon: Icons.save,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
