import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';

/// Consulta de existencia en Ventas. Solo lectura. Compacta y ergonómica.
class ConsultaStockLecturaSheet extends ConsumerStatefulWidget {
  const ConsultaStockLecturaSheet({super.key});

  @override
  ConsumerState<ConsultaStockLecturaSheet> createState() =>
      _ConsultaStockLecturaSheetState();
}

class _ConsultaStockLecturaSheetState
    extends ConsumerState<ConsultaStockLecturaSheet> {
  final _q = TextEditingController();
  String _filtro = '';

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(productoControllerProvider);
    final mobile = AppBreakpoints.isMobile(context);
    // Más baja: ~45% móvil / ~42% desktop (no 85%)
    final h = MediaQuery.sizeOf(context).height * (mobile ? 0.48 : 0.42);
    final maxW = mobile ? double.infinity : 420.0;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW, maxHeight: h),
        child: Material(
          color: AppColors.white,
          elevation: 12,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 4, 6),
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
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: TextField(
                  controller: _q,
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
              Expanded(
                child: async.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
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
                      final barras = (p.codigoBarras ?? '').toLowerCase();
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
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                      itemCount: list.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, thickness: 0.5),
                      itemBuilder: (_, i) {
                        final p = list[i];
                        final stock = p.stock ?? 0;
                        final stockTxt = stock == stock.roundToDouble()
                            ? '${stock.toInt()}'
                            : stock.toStringAsFixed(1);
                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          title: Text(
                            p.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
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
    );
  }
}
