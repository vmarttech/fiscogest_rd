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
        data: (lista) {
          if (limpio.isEmpty) return <Producto>[];
          return lista.where((p) {
            if (!p.activo) return false;
            final nombre = p.nombre.toLowerCase();
            final codigo = p.codigo.toLowerCase();
            final barras = (p.codigoBarras ?? '').toLowerCase();
            return nombre.contains(limpio) ||
                codigo.contains(limpio) ||
                (barras.isNotEmpty && barras.contains(limpio));
          }).toList();
        },
        orElse: () => <Producto>[],
      );
    });
  }

  Future<void> _pedirCantidadYAgregar(Producto prod) async {
    final controller = TextEditingController(text: '1');
    final cantidadSeleccionada = await showDialog<double>(
      context: context,
      builder: (ctx) {
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
              StatefulBuilder(
                builder: (ctx2, setLocal) {
                  void aplicarDelta(double delta) {
                    final actual = double.tryParse(
                          controller.text.replaceAll(',', '.'),
                        ) ??
                        1;
                    var n = actual + delta;
                    if (n < 0.001) n = 0.001;
                    final txt = n % 1 == 0
                        ? n.toInt().toString()
                        : n.toStringAsFixed(2);
                    controller.value = TextEditingValue(
                      text: txt,
                      selection: TextSelection.collapsed(offset: txt.length),
                    );
                    setLocal(() {});
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => aplicarDelta(-1),
                        icon: const Icon(Icons.remove),
                      ),
                      SizedBox(
                        width: 96,
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
                        ),
                      ),
                      IconButton(
                        onPressed: () => aplicarDelta(1),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final v = double.tryParse(
                      controller.text.replaceAll(',', '.'),
                    ) ??
                    0;
                Navigator.pop(ctx, v > 0 ? v : null);
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });
    if (cantidadSeleccionada != null &&
        cantidadSeleccionada > 0 &&
        mounted) {
      await widget.alAgregar(prod, cantidadSeleccionada);
      if (mounted) {
        _buscador.clear();
        _buscar('');
      }
    }
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
            hintText: 'Buscar por nombre, código o barras...',
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
            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: lista.length,
              itemBuilder: (context, i) {
                final prod = lista[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: ListTile(
                    title: Text(prod.nombre),
                    subtitle: Text(
                      '${prod.codigo.trim().isNotEmpty ? '[${prod.codigo}] · ' : ''}'
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
              ),
            );
          },
        ),
      ],
    );
  }
}
