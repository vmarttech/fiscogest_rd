import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/kardex_provider.dart';
import 'package:fiscogest_rd/features/inventario/presentation/pages/nuevo_producto_page.dart';
import 'package:fiscogest_rd/features/categorias/presentation/pages/categorias_page.dart';
import 'package:fiscogest_rd/features/marcas/presentation/pages/marcas_page.dart';
import 'package:fiscogest_rd/features/unidades/presentation/pages/unidades_page.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_sizes.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_dialog.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';

class ProductosPage extends ConsumerStatefulWidget {
  const ProductosPage({super.key});
  static const String routeName = 'inventario';
  @override
  ConsumerState<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends ConsumerState<ProductosPage> {
  int _vistaActual = 0;
  String _filtroProductos = '';
  String _filtroKardex = '';

  bool _puedeVerCostos() {
    final rol = ref.watch(rolUsuarioProvider);
    return rol == RolUsuario.compras || rol == RolUsuario.administracion;
  }

  bool _puedeEliminar() {
    final rol = ref.watch(rolUsuarioProvider);
    return rol == RolUsuario.compras || rol == RolUsuario.administracion;
  }

  void _abrirMenuOpciones(BuildContext context) async {
    final seleccionado = await showMenu<int>(
      context: context,
      position: const RelativeRect.fromLTRB(200, 500, 16, 0),
      color: const Color(0xFF1E293B),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          value: 0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_box_outlined,
                color: Color(0xFF3B82F6),
                size: 20,
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                'Nuevo Producto',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 1,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                color: Color(0xFF10B981),
                size: 20,
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                'Kárdex',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 2,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.category_outlined,
                color: Color(0xFFF59E0B),
                size: 20,
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                'Categorías',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 3,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.branding_watermark_outlined,
                color: Color(0xFF8B5CF6),
                size: 20,
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                'Marcas',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 4,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.straighten_outlined,
                color: Color(0xFFEC4899),
                size: 20,
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                'Unidades',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 5,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.settings_outlined, color: Colors.grey, size: 20),
              const SizedBox(width: AppSpacing.s),
              Text(
                'Ajustes de Inventario',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    if (seleccionado == null || !context.mounted) return;
    switch (seleccionado) {
      case 0:
        unawaited(context.pushNamed(NuevoProductoPage.routeName));
        break;
      case 1:
        setState(() => _vistaActual = 1);
        break;
      case 2:
        unawaited(context.pushNamed(CategoriasPage.routeName));
        break;
      case 3:
        unawaited(context.pushNamed(MarcasPage.routeName));
        break;
      case 4:
        unawaited(context.pushNamed(UnidadesPage.routeName));
        break;
      case 5:
        unawaited(context.pushNamed('lista-ajustes'));
        break;
    }
  }

  Future<void> _confirmarEliminar(Producto producto) async {
    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AppDialog(
        title: 'Eliminar Producto',
        message:
            '¿Eliminar "${producto.nombre}"? Esta acción no se puede deshacer.',
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado == true && producto.id != null) {
      await ref
          .read(productoControllerProvider.notifier)
          .eliminar(producto.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto eliminado correctamente')),
        );
      }
    }
  }

  void _editarProducto(Producto producto) {
    unawaited(context.pushNamed(NuevoProductoPage.routeName, extra: producto));
  }

  Widget _construirVistaActual() {
    return switch (_vistaActual) {
      0 => _buildSeccionProductos(),
      1 => _buildSeccionKardex(),
      2 => const CategoriasPage(),
      3 => const MarcasPage(),
      4 => const UnidadesPage(),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        bottom: true,
        child: Stack(
          children: [
            _construirVistaActual(),
            Positioned(
              bottom: AppSpacing.m + MediaQuery.of(context).padding.bottom,
              right: AppSpacing.m,
              child: FloatingActionButton.extended(
                onPressed: () => _abrirMenuOpciones(context),
                icon: const Icon(Icons.menu, size: AppSizes.iconMd),
                label: const Text('Opciones', style: TextStyle(fontSize: 12)),
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionProductos() {
    final puedeVerCostos = _puedeVerCostos();
    final puedeEliminar = _puedeEliminar();
    const basePadding = AppLayout.pantallaPadding as EdgeInsets;
    final padding = basePadding.copyWith(
      top: MediaQuery.of(context).padding.top + AppSpacing.s,
    );

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            hint: 'Buscar por código, nombre...',
            onChanged: (String v) => setState(() => _filtroProductos = v),
          ),
          AppLayout.vM,
          Expanded(
            child: ref
                .watch(productoControllerProvider)
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (Object e, StackTrace? _) => Center(
                    child: Text(
                      'Error: $e',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  data: (List<Producto> productos) {
                    final List<Producto> filtrados = productos
                        .where(
                          (Producto p) =>
                              p.codigo.toLowerCase().contains(
                                _filtroProductos.toLowerCase(),
                              ) ||
                              p.nombre.toLowerCase().contains(
                                _filtroProductos.toLowerCase(),
                              ),
                        )
                        .toList();
                    if (filtrados.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Text(
                            'El inventario está listo para registrar elementos.',
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: filtrados.length,
                      separatorBuilder: (_, __) => AppLayout.vM,
                      itemBuilder: (_, int i) {
                        final Producto prod = filtrados[i];
                        final double stockSeguro = prod.stock ?? 0;
                        return AppCard(
                          padding: AppSpacing.allM,
                          elevation: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF3B82F6,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.inventory_2_outlined,
                                      color: Color(0xFF3B82F6),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.m),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          prod.nombre,
                                          style: AppTypography.h4.copyWith(
                                            color: const Color(0xFF0F172A),
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          'Código: ${prod.codigo}',
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                color: AppColors.textSecondary,
                                                fontSize: 13,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Stock: ${stockSeguro.toStringAsFixed(2)}',
                                        style: AppTypography.labelLarge
                                            .copyWith(
                                              color: stockSeguro > 0
                                                  ? const Color(0xFF10B981)
                                                  : AppColors.error,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                      ),
                                      if (puedeVerCostos)
                                        Text(
                                          'Compra: \$${prod.precioCompra.toStringAsFixed(2)}',
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                color: const Color(0xFF10B981),
                                                fontSize: 12,
                                              ),
                                        ),
                                      Text(
                                        'Venta: \$${prod.precioVenta.toStringAsFixed(2)}',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: const Color(0xFFEF4444),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              AppLayout.vM,
                              Align(
                                alignment: Alignment.centerRight,
                                child: Row(
                                  children: [
                                    AppButton(
                                      text: 'Editar',
                                      icon: Icons.edit_outlined,
                                      height: 36,
                                      onPressed: () => _editarProducto(prod),
                                    ),
                                    const SizedBox(width: AppSpacing.s),
                                    if (puedeEliminar)
                                      AppButton(
                                        text: 'Eliminar',
                                        icon: Icons.delete_outline,
                                        height: 36,
                                        onPressed: () =>
                                            _confirmarEliminar(prod),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionKardex() {
    const basePadding = AppLayout.pantallaPadding as EdgeInsets;
    final padding = basePadding.copyWith(
      top: MediaQuery.of(context).padding.top + AppSpacing.s,
    );

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            hint: 'Buscar por ID de producto...',
            onChanged: (String v) => setState(() => _filtroKardex = v),
          ),
          AppLayout.vM,
          Expanded(
            child: ref
                .watch(
                  kardexPorProductoProvider(int.tryParse(_filtroKardex) ?? 0),
                )
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (Object e, StackTrace? _) => Center(
                    child: Text(
                      'Error: $e',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  data: (List<Kardex> movimientos) {
                    if (movimientos.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Text(
                            'No hay movimientos registrados.',
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: movimientos.length,
                      separatorBuilder: (_, __) => AppLayout.vM,
                      itemBuilder: (_, int i) {
                        final Kardex mov = movimientos[i];
                        return AppCard(
                          padding: AppSpacing.allM,
                          elevation: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Producto ID: ${mov.productoId}',
                                style: AppTypography.h4.copyWith(
                                  color: const Color(0xFF0F172A),
                                  fontSize: 15,
                                ),
                              ),
                              AppLayout.vXs,
                              Text(
                                'Cantidad: ${mov.cantidad} • Saldo: ${mov.saldoNuevo}',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Costo: \$${mov.costoUnitario.toStringAsFixed(2)} • Total: \$${mov.totalMovimiento.toStringAsFixed(2)}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              if (mov.fechaMovimiento != null)
                                Text(
                                  'Fecha: ${mov.fechaMovimiento}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
