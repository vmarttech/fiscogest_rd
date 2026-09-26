import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/kardex_provider.dart';
import 'package:fiscogest_rd/features/inventario/presentation/pages/nuevo_producto_page.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_dialog.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';

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
  String _filtroEstado = 'todos';

  bool _puedeVerCostos() => true;
  bool _puedeEliminar() => true;

  void _irANuevoProducto() {
    unawaited(context.pushNamed(NuevoProductoPage.routeName));
  }

  void _editarProducto(Producto producto) {
    unawaited(context.pushNamed(NuevoProductoPage.routeName, extra: producto));
  }

  Future<void> _confirmarEliminar(Producto producto) async {
    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AppDialog(
        title: 'Eliminar Producto',
        message: '¿Eliminar "${producto.nombre}"? Esta acción no se puede deshacer.',
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
      await ref.read(productoControllerProvider.notifier).eliminar(producto.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto eliminado correctamente')),
        );
      }
    }
  }

  Widget _construirVistaActual() {
    return switch (_vistaActual) {
      0 => _buildSeccionProductos(),
      1 => _buildSeccionKardex(),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    return AppScaffold(
      title: 'Inventario',
      subtitle: 'Gestión de productos y existencias',
      // ✅ Barra superior UNIFICADA — igual a todas las demás pantallas
      actions: [
        if (!isMobile)
          AppButton(
            text: 'Nuevo Producto',
            icon: Icons.add,
            onPressed: _irANuevoProducto,
          ),
      ],
      // ✅ FAB SOLO en móvil — sin duplicidad
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: _irANuevoProducto,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 4,
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeArea(
        bottom: true,
        child: _construirVistaActual(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SECCIÓN PRODUCTOS
  // ─────────────────────────────────────────────
  Widget _buildSeccionProductos() {
    final isMobile = AppBreakpoints.isMobile(context);
    final puedeVerCostos = _puedeVerCostos();
    final puedeEliminar = _puedeEliminar();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 8,
        isMobile ? 12 : 16,
        isMobile ? 16 : 8,
        12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Buscador + Filtros
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  hint: 'Buscar por código, nombre...',
                  onChanged: (v) => setState(() => _filtroProductos = v),
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 12),
                _FilterChip(
                  label: 'Todos',
                  selected: _filtroEstado == 'todos',
                  onTap: () => setState(() => _filtroEstado = 'todos'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'En Stock',
                  selected: _filtroEstado == 'en_stock',
                  color: AppColors.success,
                  onTap: () => setState(() => _filtroEstado = 'en_stock'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Bajo',
                  selected: _filtroEstado == 'bajo',
                  color: AppColors.warning,
                  onTap: () => setState(() => _filtroEstado = 'bajo'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Agotado',
                  selected: _filtroEstado == 'agotado',
                  color: AppColors.error,
                  onTap: () => setState(() => _filtroEstado = 'agotado'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ref.watch(productoControllerProvider).when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(
                child: Text('Error: $e', style: AppTypography.bodyMedium.copyWith(color: AppColors.error)),
              ),
              data: (productos) {
                final filtrados = productos.where((p) {
                  final matchTexto = p.codigo.toLowerCase().contains(_filtroProductos.toLowerCase()) ||
                      p.nombre.toLowerCase().contains(_filtroProductos.toLowerCase());
                  if (!matchTexto) return false;
                  final stock = p.stock ?? 0;
                  return switch (_filtroEstado) {
                    'en_stock' => stock > 10,
                    'bajo' => stock > 0 && stock <= 10,
                    'agotado' => stock <= 0,
                    _ => true,
                  };
                }).toList();

                if (filtrados.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Column(
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.grey300),
                          const SizedBox(height: 12),
                          Text(
                            'No se encontraron productos',
                            style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isMobile
                                ? 'Presiona el botón + para registrar el primero'
                                : 'Usa "Nuevo Producto" en la barra superior para registrar el primero',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (isMobile) {
                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: filtrados.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _ProductoCardMobile(
                      producto: filtrados[i],
                      puedeVerCostos: puedeVerCostos,
                      puedeEliminar: puedeEliminar,
                      onEditar: () => _editarProducto(filtrados[i]),
                      onEliminar: () => _confirmarEliminar(filtrados[i]),
                    ),
                  );
                }

                return _buildTablaDesktop(filtrados, puedeVerCostos, puedeEliminar);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablaDesktop(
    List<Producto> productos,
    bool puedeVerCostos,
    bool puedeEliminar,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey900.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('PRODUCTO', style: _headerStyle)),
                Expanded(flex: 2, child: Text('CÓDIGO', style: _headerStyle)),
                Expanded(
                  flex: 1,
                  child: Text(
                    'STOCK',
                    style: _headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'ESTADO',
                    style: _headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (puedeVerCostos) ...[
                  Expanded(
                    flex: 1,
                    child: Text(
                      'COSTO',
                      style: _headerStyle,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'VENTA',
                      style: _headerStyle,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
                SizedBox(
                  width: 100,
                  child: Text(
                    'ACCIONES',
                    style: _headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: productos.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.border),
              itemBuilder: (_, i) {
                final p = productos[i];
                final stock = p.stock ?? 0;
                final (statusText, statusColor) = _getStatus(stock);
                return Material(
                  color: i.isEven
                      ? AppColors.white
                      : AppColors.grey50.withValues(alpha: 0.55),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            p.nombre,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            p.codigo,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            stock.toStringAsFixed(
                              stock.truncateToDouble() == stock ? 0 : 2,
                            ),
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                statusText,
                                style: AppTypography.labelSmall.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (puedeVerCostos) ...[
                          Expanded(
                            flex: 1,
                            child: Text(
                              '\$${p.precioCompra.toStringAsFixed(2)}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.success,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              '\$${p.precioVenta.toStringAsFixed(2)}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                        SizedBox(
                          width: 100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                color: AppColors.primary,
                                onPressed: () => _editarProducto(p),
                                tooltip: 'Editar',
                              ),
                              if (puedeEliminar)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                  ),
                                  color: AppColors.error,
                                  onPressed: () => _confirmarEliminar(p),
                                  tooltip: 'Eliminar',
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  (String, Color) _getStatus(double stock) {
    if (stock <= 0) return ('Agotado', AppColors.error);
    if (stock <= 10) return ('Bajo', AppColors.warning);
    return ('En Stock', AppColors.success);
  }

  TextStyle get _headerStyle => AppTypography.labelSmall.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      );

  // ─────────────────────────────────────────────
  // SECCIÓN KÁRDEX
  // ─────────────────────────────────────────────
  Widget _buildSeccionKardex() {
    final isMobile = AppBreakpoints.isMobile(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 24,
        isMobile ? 16 : 20,
        isMobile ? 16 : 24,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _vistaActual = 0),
              ),
              const SizedBox(width: 8),
              Text(
                'Kárdex',
                style: AppTypography.h2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppTextField(
            hint: 'Buscar por ID de producto...',
            onChanged: (v) => setState(() => _filtroKardex = v),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ref.watch(kardexPorProductoProvider(int.tryParse(_filtroKardex) ?? 0)).when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(
                child: Text('Error: $e', style: AppTypography.bodyMedium.copyWith(color: AppColors.error)),
              ),
              data: (movimientos) {
                if (movimientos.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay movimientos registrados.',
                      style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: movimientos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final mov = movimientos[i];
                    return AppCard(
                      padding: AppSpacing.allM,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Producto ID: ${mov.productoId}',
                            style: AppTypography.h4.copyWith(color: AppColors.textPrimary, fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Cantidad: ${mov.cantidad}  •  Saldo: ${mov.saldoNuevo}',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                          ),
                          Text(
                            'Costo: \$${mov.costoUnitario.toStringAsFixed(2)}  •  Total: \$${mov.totalMovimiento.toStringAsFixed(2)}',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                          if (mov.fechaMovimiento != null)
                            Text(
                              'Fecha: ${mov.fechaMovimiento}',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
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

// ─────────────────────────────────────────────
// WIDGETS AUXILIARES
// ─────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? activeColor.withValues(alpha: 0.12) : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: selected ? activeColor : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ProductoCardMobile extends StatelessWidget {
  const _ProductoCardMobile({
    required this.producto,
    required this.puedeVerCostos,
    required this.puedeEliminar,
    required this.onEditar,
    required this.onEliminar,
  });
  final Producto producto;
  final bool puedeVerCostos;
  final bool puedeEliminar;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final stock = producto.stock ?? 0;
    final (statusText, statusColor) = stock <= 0
        ? ('Agotado', AppColors.error)
        : stock <= 10
            ? ('Bajo', AppColors.warning)
            : ('En Stock', AppColors.success);

    return AppCard(
      padding: AppSpacing.allM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: AppTypography.h4.copyWith(color: AppColors.textPrimary, fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Código: ${producto.codigo}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: AppTypography.labelSmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Stock: ${stock.toStringAsFixed(2)}',
                style: AppTypography.labelLarge.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (puedeVerCostos) ...[
                Text(
                  'C: \$${producto.precioCompra.toStringAsFixed(2)}',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.success),
                ),
                const SizedBox(width: 12),
                Text(
                  'V: \$${producto.precioVenta.toStringAsFixed(2)}',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                text: 'Editar',
                icon: Icons.edit_outlined,
                height: 36,
                onPressed: onEditar,
              ),
              if (puedeEliminar) ...[
                const SizedBox(width: 8),
                AppButton(
                  text: 'Eliminar',
                  icon: Icons.delete_outline,
                  height: 36,
                  onPressed: onEliminar,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
