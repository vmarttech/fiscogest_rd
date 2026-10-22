import 'dart:async';
import 'package:drift/drift.dart' hide Column;
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/scanner/barcode_scanner_page.dart';
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
  String _filtroEstado = 'todos'; // todos|en_stock|bajo|agotado|inactivo
  String _ordenProductos = 'nombre_asc';
  bool _soloActivos = true;
  /// Solo desktop: producto seleccionado en el listado.
  Producto? _productoSeleccionado;
  /// 'normal' | 'compacta'
  String _vistaLista = 'normal';

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
        setState(() {
          if (_productoSeleccionado?.id == producto.id) {
            _productoSeleccionado = null;
          }
        });
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
      // PC: sin barra de título (el layout de 3 columnas la sustituye).
      // Móvil: se mantiene título + FAB.
      title: isMobile ? 'Inventario' : null,
      subtitle: isMobile ? 'Gestión de productos y existencias' : null,
      showAppBar: isMobile,
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

    // ─── MÓVIL: sin cambios de estructura ───
    if (isMobile) {
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                AppTextField(
                  hint: 'Código, nombre o barras...',
                  prefixIcon: Icons.search_rounded,
                  suffixIcon: Icons.qr_code_scanner,
                  onSuffixTap: () async {
                    final codigo = await BarcodeScannerPage.abrir(
                      context,
                      titulo: 'Escanear producto',
                      subtitulo: 'Centre el código de barras',
                    );
                    if (!mounted || codigo == null) return;
                    setState(() => _filtroProductos = codigo.trim());
                  },
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
                const SizedBox(height: 10),
                _buildBarraOrdenYFiltros(),
                const SizedBox(height: 14),
                ref.watch(productoControllerProvider).when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          'Error: $e',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      data: (productos) {
                        final filtrados = _filtrarProductos(productos);
                        if (filtrados.isEmpty) {
                          return Padding(
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
                                  'Presiona el botón + para registrar el primero',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: filtrados.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) => _ProductoCardMobile(
                            producto: filtrados[i],
                            puedeVerCostos: puedeVerCostos,
                            puedeEliminar: puedeEliminar,
                            onEditar: () => _editarProducto(filtrados[i]),
                            onEliminar: () => _confirmarEliminar(filtrados[i]),
                          ),
                        );
                      },
                    ),
              ],
            ),
          ),
        ),
      );
    }

    // ─── DESKTOP: 3 columnas (filtros | listado | detalle) ───
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: ref.watch(productoControllerProvider).when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => Center(
              child: Text(
                'Error: $e',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
              ),
            ),
            data: (productos) {
              final filtrados = _filtrarProductos(productos);
              // Si el seleccionado ya no está en la lista, limpiar
              if (_productoSeleccionado != null &&
                  filtrados.every((p) => p.id != _productoSeleccionado!.id)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _productoSeleccionado = null);
                });
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Columna izquierda
                  SizedBox(
                    width: 260,
                    child: _PanelConfigInventario(
                      filtroEstado: _filtroEstado,
                      vistaLista: _vistaLista,
                      productos: productos,
                      onFiltro: (v) => setState(() => _filtroEstado = v),
                      onVista: (v) => setState(() => _vistaLista = v),
                      onNuevo: _irANuevoProducto,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Centro: listado
                  Expanded(
                    flex: 5,
                    child: _PanelListadoProductos(
                      productos: filtrados,
                      seleccionado: _productoSeleccionado,
                      vistaLista: _vistaLista,
                      puedeVerCostos: puedeVerCostos,
                      filtroTexto: _filtroProductos,
                      onBuscar: (v) => setState(() => _filtroProductos = v),
                      onSeleccionar: (p) =>
                          setState(() => _productoSeleccionado = p),
                      onEditar: _editarProducto,
                      onEliminar: _confirmarEliminar,
                      getStatus: _getStatus,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Derecha: detalle
                  SizedBox(
                    width: 280,
                    child: _PanelDetalleProducto(
                      producto: _productoSeleccionado,
                      puedeVerCostos: puedeVerCostos,
                      puedeEliminar: puedeEliminar,
                      onEditar: () {
                        final p = _productoSeleccionado;
                        if (p != null) _editarProducto(p);
                      },
                      onEliminar: () {
                        final p = _productoSeleccionado;
                        if (p != null) _confirmarEliminar(p);
                      },
                      getStatus: _getStatus,
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }


  Widget _buildBarraOrdenYFiltros() {
    const ordenes = <MapEntry<String, String>>[
      MapEntry('nombre_asc', 'Nombre A→Z'),
      MapEntry('nombre_desc', 'Nombre Z→A'),
      MapEntry('sku_asc', 'SKU A→Z'),
      MapEntry('sku_desc', 'SKU Z→A'),
      MapEntry('precio_asc', 'Precio ↑'),
      MapEntry('precio_desc', 'Precio ↓'),
      MapEntry('stock_desc', 'Stock mayor'),
      MapEntry('stock_asc', 'Stock menor'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FilterChip(
                label: _soloActivos ? 'Solo activos' : 'Con inactivos',
                selected: _soloActivos,
                onTap: () => setState(() => _soloActivos = !_soloActivos),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Inactivos',
                selected: _filtroEstado == 'inactivo',
                color: AppColors.textSecondary,
                onTap: () => setState(() {
                  _filtroEstado = 'inactivo';
                  _soloActivos = false;
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _ordenProductos,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Ordenar por',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(),
          ),
          items: [
            for (final e in ordenes)
              DropdownMenuItem(
                value: e.key,
                child: Text(e.value, style: const TextStyle(fontSize: 13)),
              ),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _ordenProductos = v);
          },
        ),
      ],
    );
  }

  List<Producto> _filtrarProductos(List<Producto> productos) {
    final q = _filtroProductos.trim().toLowerCase();
    final list = productos.where((p) {
      if (_soloActivos && !p.activo) return false;
      final matchTexto = q.isEmpty ||
          p.nombre.toLowerCase().contains(q) ||
          p.codigo.toLowerCase().contains(q) ||
          (p.codigoBarras ?? '').toLowerCase().contains(q);
      if (!matchTexto) return false;
      final stock = p.stock ?? 0;
      final min = p.stockMinimo ?? 10;
      return switch (_filtroEstado) {
        'en_stock' => stock > min,
        'bajo' => stock > 0 && stock <= min,
        'agotado' => stock <= 0,
        'inactivo' => !p.activo,
        _ => true,
      };
    }).toList();

    int cmpStr(String a, String b) =>
        a.toLowerCase().compareTo(b.toLowerCase());

    list.sort((a, b) {
      switch (_ordenProductos) {
        case 'nombre_desc':
          return cmpStr(b.nombre, a.nombre);
        case 'sku_asc':
          return cmpStr(a.codigo, b.codigo);
        case 'sku_desc':
          return cmpStr(b.codigo, a.codigo);
        case 'precio_asc':
          return a.precioVenta.compareTo(b.precioVenta);
        case 'precio_desc':
          return b.precioVenta.compareTo(a.precioVenta);
        case 'stock_asc':
          return (a.stock ?? 0).compareTo(b.stock ?? 0);
        case 'stock_desc':
          return (b.stock ?? 0).compareTo(a.stock ?? 0);
        case 'nombre_asc':
        default:
          return cmpStr(a.nombre, b.nombre);
      }
    });
    return list;
  }

  (String, Color) _getStatus(double stock, double stockMinimo) {
    if (stock <= 0) return ('Agotado', AppColors.error);
    if (stock <= stockMinimo) return ('Bajo', AppColors.warning);
    return ('En Stock', AppColors.success);
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

// ═══════════════════════════════════════════════
// DESKTOP: panel izquierdo
// ═══════════════════════════════════════════════
class _PanelConfigInventario extends StatelessWidget {
  const _PanelConfigInventario({
    required this.filtroEstado,
    required this.vistaLista,
    required this.productos,
    required this.onFiltro,
    required this.onVista,
    required this.onNuevo,
  });

  final String filtroEstado;
  final String vistaLista;
  final List<Producto> productos;
  final ValueChanged<String> onFiltro;
  final ValueChanged<String> onVista;
  final VoidCallback onNuevo;

  @override
  Widget build(BuildContext context) {
    final total = productos.length;
    double valorCosto = 0;
    double valorVenta = 0;
    for (final p in productos) {
      final s = p.stock ?? 0;
      valorCosto += s * (p.precioCompra);
      valorVenta += s * (p.precioVenta);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Configuración de inventario',
            style: AppTypography.h4.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Filtros rápidos',
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'En Stock',
                selected: filtroEstado == 'en_stock',
                color: AppColors.success,
                onTap: () => onFiltro(filtroEstado == 'en_stock' ? 'todos' : 'en_stock'),
              ),
              _FilterChip(
                label: 'Bajo',
                selected: filtroEstado == 'bajo',
                color: AppColors.warning,
                onTap: () => onFiltro(filtroEstado == 'bajo' ? 'todos' : 'bajo'),
              ),
              _FilterChip(
                label: 'Agotado',
                selected: filtroEstado == 'agotado',
                color: AppColors.error,
                onTap: () => onFiltro(filtroEstado == 'agotado' ? 'todos' : 'agotado'),
              ),
              const SizedBox(height: 8),
              _FilterChip(
                label: 'Inactivos',
                selected: filtroEstado == 'inactivo',
                color: AppColors.textSecondary,
                onTap: () => onFiltro(filtroEstado == 'inactivo' ? 'todos' : 'inactivo'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Vista de lista',
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _VistaToggle(
                  label: 'Normal',
                  selected: vistaLista == 'normal',
                  onTap: () => onVista('normal'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VistaToggle(
                  label: 'Compacta',
                  selected: vistaLista == 'compacta',
                  onTap: () => onVista('compacta'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Resumen de stock',
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _ResumenFila(label: 'Total Productos', value: '$total'),
          _ResumenFila(
            label: 'Total Valor (Costo)',
            value: formatRd(valorCosto),
          ),
          _ResumenFila(
            label: 'Total Valor (Venta)',
            value: formatRd(valorVenta),
          ),
          const SizedBox(height: 20),
          Text(
            'Gestión rápida',
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onNuevo,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('[F3] NUEVO PRODUCTO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VistaToggle extends StatelessWidget {
  const _VistaToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.12)
          : AppColors.grey50,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResumenFila extends StatelessWidget {
  const _ResumenFila({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// DESKTOP: panel central (listado)
// ═══════════════════════════════════════════════
class _PanelListadoProductos extends StatelessWidget {
  const _PanelListadoProductos({
    required this.productos,
    required this.seleccionado,
    required this.vistaLista,
    required this.puedeVerCostos,
    required this.filtroTexto,
    required this.onBuscar,
    required this.onSeleccionar,
    required this.onEditar,
    required this.onEliminar,
    required this.getStatus,
  });

  final List<Producto> productos;
  final Producto? seleccionado;
  final String vistaLista;
  final bool puedeVerCostos;
  final String filtroTexto;
  final ValueChanged<String> onBuscar;
  final ValueChanged<Producto> onSeleccionar;
  final void Function(Producto) onEditar;
  final void Function(Producto) onEliminar;
  final (String, Color) Function(double, double) getStatus;

  @override
  Widget build(BuildContext context) {
    final compacta = vistaLista == 'compacta';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Listado de Productos',
                    style: AppTypography.h4.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  '${productos.length} reg.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppTextField(
              height: 42,
              prefixIcon: Icons.search_rounded,
              suffixIcon: Icons.qr_code_scanner,
              hint: 'Código, nombre, categoría o barras...',
              onSuffixTap: () async {
                final codigo = await BarcodeScannerPage.abrir(
                  context,
                  titulo: 'Escanear producto',
                  subtitulo: 'Centre el código de barras',
                );
                if (!context.mounted || codigo == null) return;
                onBuscar(codigo.trim());
              },
              onChanged: onBuscar,
            ),
          ),
          const SizedBox(height: 10),
          // Cabecera
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: compacta ? 6 : 8,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: _inventoryHeaderCell('PRODUCTO', AppColors.primary),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: _inventoryHeaderCell(
                    'CÓDIGO',
                    AppColors.info,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: _inventoryHeaderCell(
                    'STOCK',
                    AppColors.warning,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (puedeVerCostos) ...[
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 3,
                    child: _inventoryHeaderCell(
                      'COSTO / VENTA',
                      AppColors.secondary,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: productos.isEmpty
                ? Center(
                    child: Text(
                      'No se encontraron productos',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: productos.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (_, i) {
                      final p = productos[i];
                      final stock = p.stock ?? 0;
                      final minimo = p.stockMinimo ?? 10;
                      final (st, sc) = getStatus(stock, minimo);
                      final sel = seleccionado?.id != null &&
                          seleccionado!.id == p.id;
                      return Material(
                        color: sel
                            ? const Color(0xFFF0FDF4)
                            : (i.isEven
                                ? Colors.white
                                : AppColors.grey50.withValues(alpha: 0.5)),
                        child: InkWell(
                          onTap: () => onSeleccionar(p),
                          onDoubleTap: () => onEditar(p),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  width: 4,
                                  color: sel
                                      ? AppColors.primary
                                      : Colors.transparent,
                                ),
                              ),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: compacta ? 6 : 11,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    p.nombre,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: compacta ? 12.5 : 13.5,
                                    ),
                                    maxLines: compacta ? 1 : 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    p.codigo,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.bodySmall.copyWith(
                                      fontFamily: 'monospace',
                                      color: AppColors.grey700,
                                      fontSize: compacta ? 11.5 : 12.5,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: sc.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${stock.toStringAsFixed(stock.truncateToDouble() == stock ? 0 : 1)}  $st',
                                        style: AppTypography.labelSmall.copyWith(
                                          color: sc,
                                          fontWeight: FontWeight.w700,
                                          fontSize: compacta ? 10.5 : 11.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (puedeVerCostos)
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      '${formatRd(p.precioCompra)} / ${formatRd(p.precioVenta)}',
                                      textAlign: TextAlign.right,
                                      style: AppTypography.bodySmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: compacta ? 11.5 : 12.5,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
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

}

// ═══════════════════════════════════════════════
// DESKTOP: panel derecho (detalle)
// ═══════════════════════════════════════════════
class _PanelDetalleProducto extends StatelessWidget {
  const _PanelDetalleProducto({
    required this.producto,
    required this.puedeVerCostos,
    required this.puedeEliminar,
    required this.onEditar,
    required this.onEliminar,
    required this.getStatus,
  });

  final Producto? producto;
  final bool puedeVerCostos;
  final bool puedeEliminar;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  final (String, Color) Function(double, double) getStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: producto == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.touch_app_outlined,
                    size: 40,
                    color: AppColors.grey300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Selecciona un producto\npara ver los detalles.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : _buildDetalle(producto!),
    );
  }

  Widget _buildDetalle(Producto p) {
    final stock = p.stock ?? 0;
    final minimo = p.stockMinimo ?? 10;
    final (st, sc) = getStatus(stock, minimo);
    final montoStock = stock * p.precioVenta;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Detalles y Acciones',
          style: AppTypography.h4.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          p.nombre,
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          'CÓDIGO: ${p.codigo}  ·  Stock: ${stock.toStringAsFixed(stock.truncateToDouble() == stock ? 0 : 2)}',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: sc.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              st,
              style: AppTypography.labelSmall.copyWith(
                color: sc,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Text(
                'VALOR EN STOCK',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatRd(montoStock),
                style: AppTypography.h3.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (puedeVerCostos) ...[
          const SizedBox(height: 12),
          _DatoCaja(label: 'Costo unitario', value: formatRd(p.precioCompra)),
          const SizedBox(height: 8),
          _DatoCaja(label: 'Precio venta', value: formatRd(p.precioVenta)),
          const SizedBox(height: 8),
          _DatoCaja(
            label: 'Margen unitario',
            value: formatRd(p.precioVenta - p.precioCompra),
          ),
        ],
        const Spacer(),
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'Gestión rápida',
          style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: onEditar,
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Editar producto'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        if (puedeEliminar) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onEliminar,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Eliminar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DatoCaja extends StatelessWidget {
  const _DatoCaja({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

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
