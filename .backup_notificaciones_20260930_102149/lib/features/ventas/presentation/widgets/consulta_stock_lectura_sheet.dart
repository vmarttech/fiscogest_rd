import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';

/// Consulta de existencia en Ventas. Solo lectura.
/// Tarjeta flotante arrastrable para que el teclado nunca la tape.
class ConsultaStockLecturaSheet extends ConsumerStatefulWidget {
  const ConsultaStockLecturaSheet({super.key});

  @override
  ConsumerState<ConsultaStockLecturaSheet> createState() =>
      _ConsultaStockLecturaSheetState();
}

class _ConsultaStockLecturaSheetState
    extends ConsumerState<ConsultaStockLecturaSheet> {
  final _q = TextEditingController();
  final _focus = FocusNode();
  String _filtro = '';

  /// Offset vertical (0 = posición base, negativo = subir)
  double _offsetY = 0;

  @override
  void dispose() {
    _q.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(productoControllerProvider);
    final mobile = AppBreakpoints.isMobile(context);
    final size = MediaQuery.sizeOf(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final keyboardOpen = viewInsets.bottom > 0;

    // Altura de la tarjeta
    final cardH = mobile
        ? (keyboardOpen ? size.height * 0.42 : size.height * 0.48)
        : size.height * 0.42;
    final maxW = mobile ? size.width - 24 : 420.0;

    // Cuando el teclado aparece, subimos automáticamente la tarjeta
    final autoLift = keyboardOpen ? -(viewInsets.bottom * 0.55) : 0.0;
    final effectiveOffset = _offsetY + autoLift;

    return Stack(
      children: [
        // Fondo semitransparente (tap para cerrar)
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.black38),
          ),
        ),

        // Tarjeta arrastrable
        Align(
          alignment: Alignment.bottomCenter,
          child: Transform.translate(
            offset: Offset(0, effectiveOffset),
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  // Solo permitir subir (negativo) o bajar un poco
                  _offsetY = (_offsetY + details.delta.dy)
                      .clamp(-size.height * 0.45, 40.0);
                });
              },
              onVerticalDragEnd: (_) {
                // Si la bajó mucho, cerrar
                if (_offsetY > 80) {
                  Navigator.pop(context);
                }
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: maxW,
                  height: cardH,
                  margin: EdgeInsets.only(
                    bottom: mobile ? 12 : 24,
                    left: mobile ? 12 : 0,
                    right: mobile ? 12 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Handle de arrastre
                      const SizedBox(height: 8),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      // Título + cerrar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 4, 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Existencia',
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (keyboardOpen)
                              TextButton(
                                onPressed: () => _focus.unfocus(),
                                child: const Text('Listo'),
                              ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close, size: 20),
                            ),
                          ],
                        ),
                      ),
                      // Campo de búsqueda
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                        child: TextField(
                          controller: _q,
                          focusNode: _focus,
                          autofocus: true,
                          style: AppTypography.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre o código…',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (v) =>
                              setState(() => _filtro = v.trim().toLowerCase()),
                        ),
                      ),
                      // Lista
                      Expanded(
                        child: async.when(
                          loading: () => const Center(
                              child: CircularProgressIndicator()),
                          error: (Object e, StackTrace st) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text('Error: $e'),
                            ),
                          ),
                          data: (List<Producto> productos) {
                            final list = productos.where((p) {
                              if (_filtro.isEmpty) return true;
                              final nombre = p.nombre.toLowerCase();
                              final codigo = p.codigo.toLowerCase();
                              final barras =
                                  (p.codigoBarras ?? '').toLowerCase();
                              return nombre.contains(_filtro) ||
                                  codigo.contains(_filtro) ||
                                  barras.contains(_filtro);
                            }).toList();

                            if (list.isEmpty) {
                              return Center(
                                child: Text(
                                  'Sin resultados',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              );
                            }

                            return ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(8, 0, 8, 12),
                              itemCount: list.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1, thickness: 0.5),
                              itemBuilder: (_, i) {
                                final p = list[i];
                                final stock = p.stock ?? 0;
                                final stockTxt =
                                    stock == stock.roundToDouble()
                                        ? '${stock.toInt()}'
                                        : stock.toStringAsFixed(1);
                                return ListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8),
                                  title: Text(
                                    p.nombre,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodyMedium
                                        .copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    p.codigo,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  trailing: Text(
                                    stockTxt,
                                    style: AppTypography.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: stock <= 0
                                          ? AppColors.error
                                          : AppColors.success,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
