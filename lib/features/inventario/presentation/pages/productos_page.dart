import 'dart:async';
import 'package:drift/drift.dart' hide Column;
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
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
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';

final indicadoresReposicionProvider =
    FutureProvider.autoDispose<
      Map<int, ({double vendidos30Dias, double compraPendiente})>
    >((ref) async {
      final db = ref.watch(databaseProvider);
      final desde =
          DateTime.now()
              .subtract(const Duration(days: 30))
              .millisecondsSinceEpoch ~/
          1000;
      final filas = await db
          .customSelect(
            '''
        SELECT
          p.id AS producto_id,
          COALESCE((
            SELECT SUM(d.cantidad)
            FROM ventas_detalle_table d
            INNER JOIN ventas_table v ON v.id = d.venta_id
            WHERE d.producto_id = p.id
              AND v.fecha >= ?
              AND v.estado_documento IN ('facturado', 'enCredito')
          ), 0) AS vendidos_30_dias,
          COALESCE((
            SELECT SUM(dc.cantidad)
            FROM detalle_compra_table dc
            INNER JOIN compras_table c ON c.id = dc.compra_id
            WHERE dc.producto_id = p.id
              AND c.estado NOT IN ('borrador', 'recibida', 'anulada')
          ), 0) AS compra_pendiente
        FROM productos_table p
        ''',
            variables: [Variable.withInt(desde)],
          )
          .get();
      return {
        for (final fila in filas)
          (fila.data['producto_id'] as num).toInt(): (
            vendidos30Dias:
                (fila.data['vendidos_30_dias'] as num?)?.toDouble() ?? 0,
            compraPendiente:
                (fila.data['compra_pendiente'] as num?)?.toDouble() ?? 0,
          ),
      };
    });

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
        FiscoGestNotifications.show(
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
      body: SafeArea(bottom: true, child: _construirVistaActual()),
    );
  }

  // ─────────────────────────────────────────────
  // SECCIÓN PRODUCTOS
  // ─────────────────────────────────────────────
  Widget _buildSeccionProductos() {
    final isMobile = AppBreakpoints.isMobile(context);
    final puedeVerCostos = _puedeVerCostos();
    final puedeEliminar = _puedeEliminar();

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 24,
        isMobile ? 12 : 20,
        isMobile ? 16 : 24,
        24,
      ),
      child: ListView(
        children: [
          // Buscador + Filtros
          if (isMobile) ...[
            AppTextField(
              hint: 'Buscar por código, nombre...',
              onChanged: (v) => setState(() => _filtroProductos = v),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
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
              ),
            ),
          ] else
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.grey900.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 440,
                      child: AppTextField(
                        height: 48,
                        prefixIcon: Icons.search_rounded,
                        hint: 'Buscar por código o nombre...',
                        onChanged: (v) =>
                            setState(() => _filtroProductos = v),
                      ),
                    ),
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
                ),
              ),
            ),
          SizedBox(height: isMobile ? 14 : 20),
          
            ref
                .watch(productoControllerProvider)
                .when(
                  loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => Padding(padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'Error: $e',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  data: (productos) {
                    final filtrados = productos.where((p) {
                      final matchTexto =
                          p.codigo.toLowerCase().contains(
                            _filtroProductos.toLowerCase(),
                          ) ||
                          p.nombre.toLowerCase().contains(
                            _filtroProductos.toLowerCase(),
                          );
                      if (!matchTexto) return false;
                      final stock = p.stock ?? 0;
                      return switch (_filtroEstado) {
                        'en_stock' => stock > (p.stockMinimo ?? 10),
                        'bajo' => stock > 0 && stock <= (p.stockMinimo ?? 10),
                        'agotado' => stock <= 0,
                        _ => true,
                      };
                    }).toList();

                    if (filtrados.isEmpty) {
                      return Padding(padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.inventory_2_outlined,
                                size: 48,
                                color: AppColors.grey300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No se encontraron productos',
                                style: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isMobile
                                    ? 'Presiona el botón + para registrar el primero'
                                    : 'Usa "Nuevo Producto" en la barra superior para registrar el primero',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (isMobile) {
                      return ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), 
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

                    return Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        
                        child: _buildTablaDesktop(
                          filtrados,
                          puedeVerCostos,
                          puedeEliminar,
                        ),
                      ),
                    );
                  },
                )
          ,
        ],
      ),
    )));
  }

  Widget _buildTablaDesktop(
    List<Producto> productos,
    bool puedeVerCostos,
    bool puedeEliminar,
  ) {
    final indicadores = ref.watch(indicadoresReposicionProvider).valueOrNull;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _inventoryHeaderCell('PRODUCTO', AppColors.primary),
                ),
                Expanded(
                  flex: 2,
                  child: _inventoryHeaderCell('CÓDIGO', AppColors.info),
                ),
                Expanded(
                  flex: 1,
                  child: _inventoryHeaderCell(
                    'STOCK',
                    AppColors.warning,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: _inventoryHeaderCell(
                    'ESTADO',
                    AppColors.success,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (puedeVerCostos) ...[
                  Expanded(
                    flex: 1,
                    child: _inventoryHeaderCell(
                      'COSTO',
                      AppColors.secondary,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: _inventoryHeaderCell(
                      'VENTA',
                      AppColors.info,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
                SizedBox(
                  width: 100,
                  child: _inventoryHeaderCell(
                    'ACCIONES',
                    AppColors.grey600,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          
            ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), 
              itemCount: productos.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.border),
              itemBuilder: (_, i) {
                final p = productos[i];
                final stock = p.stock ?? 0;
                final minimo = p.stockMinimo ?? 10;
                final indicadoresProducto = p.id == null
                    ? null
                    : indicadores?[p.id!];
                final vendidos30Dias = indicadoresProducto?.vendidos30Dias ?? 0;
                final compraPendiente =
                    indicadoresProducto?.compraPendiente ?? 0;
                var objetivoReposicion = vendidos30Dias + minimo;
                if (objetivoReposicion < minimo) {
                  objetivoReposicion = minimo;
                }
                if (p.stockMaximo != null &&
                    p.stockMaximo! >= minimo &&
                    objetivoReposicion > p.stockMaximo!) {
                  objetivoReposicion = p.stockMaximo!;
                }
                final cantidadSugerida =
                    (objetivoReposicion - stock - compraPendiente).clamp(
                      0.0,
                      double.infinity,
                    );
                final (statusText, statusColor) = _getStatus(stock, minimo);
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
                              fontWeight: FontWeight.w600,
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
                              color: AppColors.grey700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  stock.toStringAsFixed(
                                    stock.truncateToDouble() == stock ? 0 : 2,
                                  ),
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: statusColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              if (indicadores != null && cantidadSugerida > 0)
                                Tooltip(
                                  message:
                                      'Sugerencia con ventas de 30 días y compras pendientes; respeta el stock máximo configurado.',
                                  child: Text(
                                    'Reponer ${cantidadSugerida.toStringAsFixed(cantidadSugerida.truncateToDouble() == cantidadSugerida ? 0 : 2)}',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.warning,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
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
                              formatRd(p.precioCompra),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              formatRd(p.precioVenta),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                        SizedBox(
                          width: 96,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                color: AppColors.primary,
                                onPressed: () => _editarProducto(p),
                                tooltip: 'Editar',
                              ),
                              if (puedeEliminar)
                                IconButton(
                                  visualDensity: VisualDensity.compact,
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
            )
          ,
        ],
      ),
    );
  }

  (String, Color) _getStatus(double stock, double stockMinimo) {
    if (stock <= 0) return ('Agotado', AppColors.error);
    if (stock <= stockMinimo) return ('Bajo', AppColors.warning);
    return ('En Stock', AppColors.success);
  }

  Widget _inventoryHeaderCell(
    String label,
    Color color, {
    TextAlign textAlign = TextAlign.left,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        textAlign: textAlign,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          fontSize: 11,
        ),
      ),
    );
  }

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
            child: ref
                .watch(
                  kardexPorProductoProvider(int.tryParse(_filtroKardex) ?? 0),
                )
                .when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Error: $e',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  data: (movimientos) {
                    if (movimientos.isEmpty) {
                      return Center(
                        child: Text(
                          'No hay movimientos registrados.',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
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
                                style: AppTypography.h4.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Cantidad: ${mov.cantidad}  •  Saldo: ${mov.saldoNuevo}',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                'Costo: ${formatRd(mov.costoUnitario)}  •  Total: ${formatRd(mov.totalMovimiento)}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (mov.fechaMovimiento != null)
                                Text(
                                  'Fecha: ${mov.fechaMovimiento}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
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
          color: selected ? activeColor.withValues(alpha: 0.14) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? activeColor.withValues(alpha: 0.45)
                : AppColors.border,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: selected ? activeColor : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      producto.codigo,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Stock: ${stock.toStringAsFixed(stock.truncateToDouble() == stock ? 0 : 2)}',
                style: AppTypography.labelLarge.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (puedeVerCostos) ...[
                Text(
                  'C: ${formatRd(producto.precioCompra)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.success,
                  ),
                ),
                Text(
                  'V: ${formatRd(producto.precioVenta)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Iconos: no desbordan como AppButton con texto
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEditar,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.35),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (puedeEliminar) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEliminar,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Eliminar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.35),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
