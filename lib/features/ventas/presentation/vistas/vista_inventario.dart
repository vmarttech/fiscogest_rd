import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/ventas_navegacion_provider.dart';

/// Vista de listado y selección de productos
/// ✅ REUTILIZA: entidad Producto + productoControllerProvider existentes
/// ✅ FILTRA: según categoría seleccionada en barra inferior
/// ✅ NAVEGA: al detalle al seleccionar producto
class VistaInventario extends ConsumerStatefulWidget {
  const VistaInventario({super.key});

  @override
  ConsumerState<VistaInventario> createState() => _VistaInventarioState();
}

class _VistaInventarioState extends ConsumerState<VistaInventario> {
  final _busqueda = TextEditingController();
  String? _terminoBusqueda;

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  List<Producto> _filtrar(List<Producto> lista, CategoriaProducto categoria) {
    var resultados = lista.where((p) => p.activo).toList();

    // Filtrar por término de búsqueda
    if (_terminoBusqueda != null && _terminoBusqueda!.isNotEmpty) {
      final termino = _terminoBusqueda!.toLowerCase().trim();
      resultados = resultados
          .where((p) =>
              p.nombre.toLowerCase().contains(termino) ||
              p.codigo.toLowerCase().contains(termino))
          .toList();
    }

    // TODO: Cuando tengas categorías reales asignadas a productos,
    // aquí se cruza categoriaId con la categoría seleccionada
    // Por ahora: Manufactura → productos con descripción indicadora
    switch (categoria) {
      case CategoriaProducto.productos:
        return resultados;
      case CategoriaProducto.manufactura:
        return resultados
            .where((p) =>
                p.descripcion?.toLowerCase().contains('manufactura') == true)
            .toList();
      case CategoriaProducto.servicios:
        return resultados
            .where((p) => p.unidadMedidaId == 99)
            .toList();
      case CategoriaProducto.scanner:
        return resultados
            .where((p) => p.codigoBarras?.isNotEmpty == true)
            .toList();
    }
  }

  void _seleccionarProducto(Producto producto) {
    // TODO: Conectar con carrito/línea de venta
    // Por ahora: navegar a VistaDetalle llevando el producto
    ref.read(ventasNavegacionProvider.notifier).cambiarVista(VistaActual.detalle);
  }

  @override
  Widget build(BuildContext context) {
    final estadoProductos = ref.watch(productoControllerProvider);
    final categoria = ref.watch(
      ventasNavegacionProvider.select((e) => e.categoriaSeleccionada),
    );

    return Column(
      children: [
        // Buscador
        Padding(
          padding: AppSpacing.allM,
          child: TextField(
            controller: _busqueda,
            decoration: const InputDecoration(
              hintText: 'Buscar producto...',
              prefixIcon: Icon(Icons.search, color: AppColors.grey600),
              filled: true,
              fillColor: AppColors.grey50,
              border: OutlineInputBorder(),
              contentPadding: AppSpacing.allS,
            ),
            onChanged: (valor) {
              setState(() => _terminoBusqueda = valor);
            },
          ),
        ),

        // Listado
        Expanded(
          child: estadoProductos.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, pila) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: AppSpacing.m),
                  Text('Error al cargar productos: $error',
                      style: AppTypography.bodyMedium),
                ],
              ),
            ),
            data: (todos) {
              final lista = _filtrar(todos, categoria);

              if (lista.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 64, color: AppColors.grey400),
                      const SizedBox(height: AppSpacing.m),
                      Text(
                        _terminoBusqueda?.isNotEmpty == true
                            ? 'No hay coincidencias'
                            : 'No hay productos en esta categoría',
                        style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: AppSpacing.allM,
                itemCount: lista.length,
                itemBuilder: (ctx, i) {
                  final producto = lista[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.s),
                    child: InkWell(
                      onTap: () => _seleccionarProducto(producto),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: AppSpacing.allM,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    producto.nombre,
                                    style: AppTypography.labelLarge,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    producto.codigo,
                                    style: AppTypography.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'RD\$ ${producto.precioVenta.toStringAsFixed(2)}',
                                  style: AppTypography.labelMedium.copyWith(
                                      color: AppColors.primary),
                                ),
                                if (producto.stock != null)
                                  Text(
                                    'Stock: ${producto.stock!.toStringAsFixed(0)}',
                                    style: AppTypography.bodySmall,
                                  ),
                              ],
                            ),
                          ],
                        ),
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
}
