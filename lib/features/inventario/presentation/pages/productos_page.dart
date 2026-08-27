import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/kardex_provider.dart';
import 'package:fiscogest_rd/features/categorias/presentation/pages/categorias_page.dart';
import 'package:fiscogest_rd/features/marcas/presentation/pages/marcas_page.dart';
import 'package:fiscogest_rd/features/unidades/presentation/pages/unidades_page.dart';
import 'package:fiscogest_rd/features/inventario/domain/enums/tipo_movimiento.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_dropdown.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';

class ProductosPage extends ConsumerStatefulWidget {
  const ProductosPage({super.key});
  static const String routeName = 'inventario';
  @override
  ConsumerState<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends ConsumerState<ProductosPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filtroProductos = '';
  String _filtroKardex = '';
  TipoMovimiento? _filtroTipoKardex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esPantallaPequena = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('Gestion Integral de Inventario'),
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_outlined, color: AppColors.white, size: 22),
            tooltip: 'Ajustes de Inventario',
            onPressed: () => context.pushNamed('lista-ajustes'),
          ),
          const SizedBox(width: AppSpacing.s),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.tabIndicator,
          indicatorWeight: 3,
          labelStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
          unselectedLabelColor: AppColors.white70,
          labelColor: AppColors.white,
          tabs: [
            Tab(icon: const Icon(Icons.inventory_2_outlined), text: esPantallaPequena ? null : 'Productos'),
            Tab(icon: const Icon(Icons.receipt_long_outlined), text: esPantallaPequena ? null : 'Kardex'),
            Tab(icon: const Icon(Icons.category_outlined), text: esPantallaPequena ? null : 'Categorias'),
            Tab(icon: const Icon(Icons.branding_watermark_outlined), text: esPantallaPequena ? null : 'Marcas'),
            Tab(icon: const Icon(Icons.straighten_outlined), text: esPantallaPequena ? null : 'Unidades'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSeccionProductos(context),
          _buildSeccionKardex(context, esPantallaPequena),
          const CategoriasPage(),
          const MarcasPage(),
          const UnidadesPage(),
        ],
      ),
    );
  }

  Widget _buildSeccionProductos(BuildContext context) {
    final productosAsync = ref.watch(productoControllerProvider);
    return Padding(
      padding: AppSpacing.allL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkSurface,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: AppSpacing.hL,
                ),
                onPressed: () => context.push('/productos/nuevo'),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Nuevo Producto', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          AppTextField(
            hint: 'Buscar por codigo, nombre...',
            onChanged: (v) => setState(() => _filtroProductos = v),
          ),
          const SizedBox(height: AppSpacing.m),
          Expanded(
            child: productosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error: $e', style: AppTypography.bodyMedium.copyWith(color: AppColors.error)),
              ),
              data: (productos) {
                final filtrados = productos
                    .where((p) => p.codigo.toLowerCase().contains(_filtroProductos) || p.nombre.toLowerCase().contains(_filtroProductos))
                    .toList();
                if (filtrados.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text(
                        'El inventario esta listo para registrar elementos.',
                        style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: AppSpacing.vS,
                  itemCount: filtrados.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.m),
                  itemBuilder: (_, i) {
                    final prod = filtrados[i];
                    return AppCard(
                      padding: AppSpacing.allL,
                      elevation: 2,
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            margin: const EdgeInsets.only(right: AppSpacing.m),
                            decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.inventory_2_outlined, color: AppColors.darkSurface, size: 24),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${prod.codigo} • ${prod.nombre}',
                                  style: AppTypography.h4.copyWith(color: AppColors.darkSurface),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Wrap(
                                  spacing: AppSpacing.s,
                                  runSpacing: AppSpacing.xs,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                        children: [
                                          const TextSpan(text: 'Stock: '),
                                          TextSpan(
                                            text: '${prod.stock}',
                                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkSurface),
                                          ),
                                        ],
                                      ),
                                    ),
                                    RichText(
                                      text: TextSpan(
                                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                        children: [
                                          const TextSpan(text: 'Compra: '),
                                          TextSpan(
                                            text: '${prod.precioCompra}',
                                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.success),
                                          ),
                                        ],
                                      ),
                                    ),
                                    RichText(
                                      text: TextSpan(
                                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                        children: [
                                          const TextSpan(text: 'Venta: '),
                                          TextSpan(
                                            text: '${prod.precioVenta}',
                                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.error),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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

  // ✅ TITULO ELIMINADO + MIGRACION COMPLETA DE LAYOUT
  Widget _buildSeccionKardex(BuildContext context, bool esPantallaPequena) {
    final movimientosAsync = ref.watch(kardexPorProductoProvider(''));
    return Padding(
      padding: AppSpacing.allL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🚫 TITULO "Historial de Movimientos" — ELIMINADO COMPLETAMENTE
          const SizedBox(height: AppSpacing.s),
          // ✅ MIGRACION: EN CELULAR UNO DEBAJO DEL OTRO → SIN DESBORDAMIENTO
          if (esPantallaPequena) ...[
            AppTextField(
              hint: 'Buscar por producto, documento...',
              onChanged: (v) => setState(() => _filtroKardex = v),
            ),
            const SizedBox(height: AppSpacing.m),
            AppDropdown<TipoMovimiento>(
              initialValue: _filtroTipoKardex,
              hint: 'Tipo Movimiento',
              items: TipoMovimiento.values.map((t) => DropdownMenuItem(
                value: t,
                child: Text(t.name.toUpperCase(), style: AppTypography.bodyMedium),
              )).toList(),
              onChanged: (v) => setState(() => _filtroTipoKardex = v),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    hint: 'Buscar por producto, documento...',
                    onChanged: (v) => setState(() => _filtroKardex = v),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: AppDropdown<TipoMovimiento>(
                    initialValue: _filtroTipoKardex,
                    hint: 'Tipo Movimiento',
                    items: TipoMovimiento.values.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.name.toUpperCase(), style: AppTypography.bodyMedium),
                    )).toList(),
                    onChanged: (v) => setState(() => _filtroTipoKardex = v),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.m),
          Expanded(
            child: movimientosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error: $e', style: AppTypography.bodyMedium.copyWith(color: AppColors.error)),
              ),
              data: (movimientos) {
                final filtrados = movimientos.where((m) {
                  final coincideTexto = m.productoId.toString().contains(_filtroKardex) ||
                      (m.documentoReferencia?.contains(_filtroKardex) ?? false);
                  final coincideTipo = _filtroTipoKardex == null || m.tipoMovimiento == _filtroTipoKardex;
                  return coincideTexto && coincideTipo;
                }).toList();
                if (filtrados.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text(
                        'Aparecera el historial completo de entradas, salidas y ajustes de inventario.',
                        style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: AppSpacing.vS,
                  itemCount: filtrados.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.m),
                  itemBuilder: (_, i) {
                    final mov = filtrados[i];
                    final colorTipo = switch (mov.tipoMovimiento) {
                      TipoMovimiento.entrada => AppColors.success,
                      TipoMovimiento.salida => AppColors.error,
                      TipoMovimiento.ajuste => AppColors.warning,
                      _ => AppColors.info,
                    };
                    final fechaValida = mov.fechaMovimiento ?? DateTime.now();
                    return AppCard(
                      padding: AppSpacing.allL,
                      elevation: 2,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 60,
                            decoration: BoxDecoration(color: colorTipo, borderRadius: BorderRadius.circular(4)),
                          ),
                          const SizedBox(width: AppSpacing.m),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mov.tipoMovimiento.name.toUpperCase(),
                                  style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold, color: colorTipo),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Producto: ${mov.productoId}\nDocumento: ${mov.documentoReferencia ?? 'Sin doc'}',
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Cantidad: ${mov.cantidad}  |  Saldo: ${mov.saldoAnterior} -> ${mov.saldoNuevo}',
                                  style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.darkSurface),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${fechaValida.day}/${fechaValida.month}/${fechaValida.year}',
                                  style: AppTypography.labelSmall.copyWith(color: AppColors.textDisabled, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
                                  decoration: BoxDecoration(color: colorTipo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                  child: Text(
                                    mov.tipoMovimiento == TipoMovimiento.entrada ? 'Entrante' : 'Saliente',
                                    style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold, color: colorTipo),
                                  ),
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
}
