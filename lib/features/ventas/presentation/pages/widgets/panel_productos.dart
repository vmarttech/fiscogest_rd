import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/ventas_page.dart';

class _TarjetaProfesional extends StatelessWidget {
  const _TarjetaProfesional({required this.child}) : colorFondo = Colors.white;
  final Widget child;
  final Color colorFondo;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.allM,
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

class _TablaProductosEscritorio extends StatelessWidget {
  const _TablaProductosEscritorio({required this.productos, required this.alAgregar});
  final List<Producto> productos;
  final void Function(Producto)? alAgregar;
  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(1.2), 2: FlexColumnWidth(0.8), 3: FlexColumnWidth(1.3)},
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(6)),
          children: const [
            Padding(padding: AppSpacing.vM, child: Text('Producto', style: AppTypography.labelSmall, textAlign: TextAlign.left)),
            Padding(padding: AppSpacing.vM, child: Text('Precio Venta', style: AppTypography.labelSmall, textAlign: TextAlign.right)),
            Padding(padding: AppSpacing.vM, child: Text('Stock', style: AppTypography.labelSmall, textAlign: TextAlign.center)),
            Padding(padding: AppSpacing.vM, child: SizedBox.shrink()),
          ],
        ),
        const TableRow(children: [Divider(height: 1)]),
        for (final prod in productos)
          TableRow(children: [
            Padding(padding: AppSpacing.vS, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(prod.nombre, style: AppTypography.bodyMedium),
              Text(prod.codigo, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
            ])),
            Padding(padding: AppSpacing.vS, child: Text('RD\$ ${prod.precioVenta.toStringAsFixed(2)}', style: AppTypography.labelMedium, textAlign: TextAlign.right)),
            Padding(padding: AppSpacing.vS, child: Text('${prod.stock ?? 0.0}', style: AppTypography.bodyMedium, textAlign: TextAlign.center)),
            Padding(padding: AppSpacing.vS, child: Align(alignment: Alignment.centerRight, child: AppButton(text: 'Agregar', icon: Icons.add, onPressed: alAgregar != null ? () => alAgregar!(prod) : null))),
          ]),
      ],
    );
  }
}

class _TarjetaProductoMovil extends StatelessWidget {
  const _TarjetaProductoMovil({required this.producto, required this.alAgregar});
  final Producto producto;
  final void Function(Producto)? alAgregar;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      padding: AppSpacing.allM,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(producto.nombre, style: AppTypography.labelMedium),
          Text(producto.codigo, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          Text('Stock disponible: ${producto.stock ?? 0.0}', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('RD\$ ${producto.precioVenta.toStringAsFixed(2)}', style: AppTypography.h4.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.s),
          AppButton(text: 'Agregar', icon: Icons.add, onPressed: alAgregar != null ? () => alAgregar!(producto) : null),
        ]),
      ]),
    );
  }
}

class _ListaProductosMovil extends StatelessWidget {
  const _ListaProductosMovil({required this.productos, required this.alAgregar});
  final List<Producto> productos;
  final void Function(Producto)? alAgregar;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: productos.map((prod) => _TarjetaProductoMovil(
        producto: prod,
        alAgregar: alAgregar,
      )).toList(),
    );
  }
}

class PanelProductos extends ConsumerWidget {
  const PanelProductos({super.key, this.esMovil = false});
  final bool esMovil;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagina = context.findAncestorStateOfType<VentasPageState>();
    final carga = ref.watch(productoControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Catálogo de Productos', style: AppTypography.h4),
            const SizedBox(height: AppSpacing.xs),
            Text('Busca y agrega artículos al carrito', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        _TarjetaProfesional(
          child: Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Buscar por código, nombre o código de barras',
                  prefixIcon: Icons.search,
                  onChanged: (valor) {
                    if (pagina != null) {
                      pagina.terminoBusqueda = valor;
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              AppButton(text: '', icon: Icons.qr_code_scanner, onPressed: () {}),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        _TarjetaProfesional(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Productos Disponibles', style: AppTypography.labelMedium),
                  Consumer(
                    builder: (_, ref, __) {
                      final productos = pagina?.productosFiltrados ?? [];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
                        child: Text('${productos.length} artículos', style: AppTypography.bodySmall.copyWith(color: AppColors.primary)),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              const Divider(height: 1, thickness: 1),
              const SizedBox(height: AppSpacing.m),
              carga.when(
                loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Padding(padding: const EdgeInsets.symmetric(vertical: 48), child: Text('Error al cargar productos: $e', style: AppTypography.bodyMedium.copyWith(color: AppColors.error), textAlign: TextAlign.center)),
                data: (_) {
                  final productos = pagina?.productosFiltrados ?? [];
                  if (productos.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: AppSpacing.m),
                        Text(pagina?.terminoBusqueda.isNotEmpty == true ? 'No hay coincidencias' : 'No hay productos registrados', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                      ]),
                    );
                  }
                  return esMovil ? _ListaProductosMovil(productos: productos, alAgregar: pagina?.agregarAlCarrito) : _TablaProductosEscritorio(productos: productos, alAgregar: pagina?.agregarAlCarrito);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
