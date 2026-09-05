import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/app_sizes.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

class VistaInventario extends ConsumerStatefulWidget {
  const VistaInventario({super.key});

  @override
  ConsumerState<VistaInventario> createState() => _VistaInventarioState();
}

class _VistaInventarioState extends ConsumerState<VistaInventario> {
  final TextEditingController _busqueda = TextEditingController();
  String? _terminoBusqueda;
  static const double _tasaItbis = 18.0;

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  List<Producto> _filtrar(List<Producto> lista, CategoriaProducto categoria) {
    var resultados = lista.where((Producto p) => p.activo).toList();
    if (_terminoBusqueda != null && _terminoBusqueda!.isNotEmpty) {
      final String termino = _terminoBusqueda!.toLowerCase().trim();
      resultados = resultados
          .where((Producto p) =>
              p.nombre.toLowerCase().contains(termino) ||
              p.codigo.toLowerCase().contains(termino))
          .toList();
    }
    switch (categoria) {
      case CategoriaProducto.productos:
        return resultados;
      case CategoriaProducto.manufactura:
        return resultados
            .where((Producto p) =>
                p.descripcion?.toLowerCase().contains('manufactura') == true)
            .toList();
      case CategoriaProducto.servicios:
        return resultados.where((Producto p) => p.unidadMedidaId == 99).toList();
      case CategoriaProducto.scanner:
        return resultados
            .where((Producto p) => p.codigoBarras?.isNotEmpty == true)
            .toList();
    }
  }

  void _seleccionarProducto(Producto producto) {
    const int cantidad = 1;
    final double precioUnitario = producto.precioVenta;
    final double subtotal = cantidad * precioUnitario;
    final DetalleVenta linea = DetalleVenta(
      productoId: producto.id ?? 0,
      nombreProducto: producto.nombre,
      cantidad: cantidad,
      precioUnitario: precioUnitario,
      subtotal: subtotal,
      subtotalLinea: subtotal,
      tasaImpuesto: _tasaItbis,
    );
    ref.read(registrarVentaProvider.notifier).agregarProducto(linea);
    ref
        .read(ventasNavegacionProvider.notifier)
        .cambiarVista(VistaActual.inicio);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Producto>> estadoProductos =
        ref.watch(productoControllerProvider);
    final CategoriaProducto categoria = ref.watch(
      ventasNavegacionProvider.select(
        (e) => e.categoriaSeleccionada,
      ),
    );

    return Column(
      children: [
        Padding(
          padding: AppSpacing.allM,
          child: AppTextField(
            controller: _busqueda,
            hint: 'Buscar producto, código o escanear',
            prefixIcon: Icons.search,
            onChanged: (String valor) {
              setState(() => _terminoBusqueda = valor);
            },
          ),
        ),
        Padding(
          padding: AppSpacing.hM,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filtroEtiqueta('Todos',
                    categoria == CategoriaProducto.productos, () {
                  ref
                      .read(ventasNavegacionProvider.notifier)
                      .cambiarCategoria(CategoriaProducto.productos);
                }),
                const SizedBox(width: AppSpacing.s),
                _filtroEtiqueta('Manufactura',
                    categoria == CategoriaProducto.manufactura, () {
                  ref
                      .read(ventasNavegacionProvider.notifier)
                      .cambiarCategoria(CategoriaProducto.manufactura);
                }),
                const SizedBox(width: AppSpacing.s),
                _filtroEtiqueta('Servicios',
                    categoria == CategoriaProducto.servicios, () {
                  ref
                      .read(ventasNavegacionProvider.notifier)
                      .cambiarCategoria(CategoriaProducto.servicios);
                }),
                const SizedBox(width: AppSpacing.s),
                _filtroEtiqueta('Escanear',
                    categoria == CategoriaProducto.scanner, () {
                  ref
                      .read(ventasNavegacionProvider.notifier)
                      .cambiarCategoria(CategoriaProducto.scanner);
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Expanded(
          child: estadoProductos.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object error, StackTrace pila) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 48,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    'Error al cargar productos: $error',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ),
            data: (List<Producto> todos) {
              final List<Producto> lista = _filtrar(todos, categoria);
              if (lista.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: AppColors.grey400,
                      ),
                      const SizedBox(height: AppSpacing.m),
                      Text(
                        _terminoBusqueda?.isNotEmpty == true
                            ? 'No hay coincidencias'
                            : 'No hay productos en esta categoría',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return GridView.builder(
                padding: AppSpacing.allM,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      MediaQuery.of(context).size.width < 400 ? 1 : 2,
                  crossAxisSpacing: AppSpacing.s,
                  mainAxisSpacing: AppSpacing.s,
                  childAspectRatio: 1.5,
                ),
                itemCount: lista.length,
                itemBuilder: (BuildContext ctx, int i) {
                  final Producto producto = lista[i];
                  return AppCard(
                    padding: AppSpacing.allS,
                    child: InkWell(
                      onTap: () => _seleccionarProducto(producto),
                      borderRadius: AppRadius.allM,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            producto.nombre,
                            style: AppTypography.labelLarge,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            producto.codigo,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'RD\$ ${producto.precioVenta.toStringAsFixed(2)}',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Stock: ${producto.stock?.toInt() ?? '-'}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: AppButton(
                              text: 'AGREGAR',
                              onPressed: () =>
                                  _seleccionarProducto(producto),
                              icon: Icons.add,
                              height: AppSizes.buttonHeightSm,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filtroEtiqueta(String texto, bool activo, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.allCircular,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: activo
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surface,
          border: Border.all(
            color: activo ? AppColors.primary : AppColors.border,
          ),
          borderRadius: AppRadius.allCircular,
        ),
        child: Text(
          texto,
          style: TextStyle(
            color: activo ? AppColors.primary : AppColors.textSecondary,
            fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
