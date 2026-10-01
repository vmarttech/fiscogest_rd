import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
typedef AgregarProductoCallback =
    Future<void> Function(Producto producto, double cantidad);

class PanelProductos extends ConsumerStatefulWidget {
  const PanelProductos({super.key, required this.alAgregar});

  final AgregarProductoCallback alAgregar;

  @override
  ConsumerState<PanelProductos> createState() => _PanelProductosState();
}

class _PanelProductosState extends ConsumerState<PanelProductos> {
  final TextEditingController _buscador = TextEditingController();
  List<Producto> _resultados = [];
  String _ultimoTexto = '';

  @override
  void dispose() {
    _buscador.dispose();
    super.dispose();
  }

  void _buscar(String texto) {
    final limpio = texto.trim().toLowerCase();
    if (limpio == _ultimoTexto) return;
    _ultimoTexto = limpio;
    final todos = ref.read(productoControllerProvider);
    setState(() {
      _resultados = todos.maybeWhen(
        data: (lista) => lista
            .where((p) => p.activo && p.nombre.toLowerCase().contains(limpio))
            .toList(),
        orElse: () => <Producto>[],
      );
    });
  }

  Future<void> _pedirCantidadYAgregar(Producto prod) async {
    double cantidad = 1;
    final controller = TextEditingController(text: '1');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            void syncFromField() {
              final v = double.tryParse(
                    controller.text.replaceAll(',', '.'),
                  ) ??
                  cantidad;
              cantidad = v < 0.001 ? 0.001 : v;
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Cantidad',
                style: AppTypography.h4.copyWith(fontWeight: FontWeight.w800),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    prod.nombre,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Precio: ${formatRd(prod.precioVenta)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          syncFromField();
                          if (cantidad > 1) {
                            cantidad -= 1;
                          } else if (cantidad > 0.001) {
                            cantidad = (cantidad - 0.5).clamp(0.001, 999999);
                          }
                          controller.text = cantidad % 1 == 0
                              ? cantidad.toInt().toString()
                              : cantidad.toStringAsFixed(2);
                          setLocal(() {});
                        },
                        icon: const Icon(Icons.remove),
                      ),
                      SizedBox(
                        width: 88,
                        child: TextField(
                          controller: controller,
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => setLocal(() {}),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          syncFromField();
                          cantidad += 1;
                          controller.text = cantidad % 1 == 0
                              ? cantidad.toInt().toString()
                              : cantidad.toStringAsFixed(2);
                          setLocal(() {});
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    syncFromField();
                    if (cantidad <= 0) return;
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok == true && mounted) {
      final v = double.tryParse(controller.text.replaceAll(',', '.')) ?? 1;
      if (v > 0) {
        await widget.alAgregar(prod, v);
      }
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productosAsync = ref.watch(productoControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _buscador,
          decoration: const InputDecoration(
            hintText: 'Buscar producto por nombre...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          onChanged: _buscar,
        ),
        const SizedBox(height: AppSpacing.s),
        productosAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(
            'Error al cargar productos: $e',
            style: const TextStyle(color: AppColors.error),
          ),
          data: (_) {
            final lista = _resultados;
            if (_buscador.text.trim().isEmpty) {
              return const Text(
                'Escriba para buscar productos del inventario',
                style: AppTypography.bodySmall,
              );
            }
            if (lista.isEmpty) {
              return const Text(
                'No se encontraron productos',
                style: AppTypography.bodySmall,
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lista.length,
              itemBuilder: (context, i) {
                final prod = lista[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: ListTile(
                    title: Text(prod.nombre),
                    subtitle: Text(
                      'Precio: ${formatRd(prod.precioVenta)}'
                      '${prod.stock != null ? ' • Stock: ${prod.stock}' : ''}',
                      style: AppTypography.bodySmall,
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _pedirCantidadYAgregar(prod),
                      child: const Text('Agregar'),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
