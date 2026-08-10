import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/kardex_provider.dart';
import 'package:fiscogest_rd/features/inventario/domain/enums/tipo_movimiento.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_dropdown.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_form.dart'; // ✅ Agrega esta línea

class KardexPage extends ConsumerStatefulWidget {
  const KardexPage({super.key, this.productoId});
  final String? productoId;

  @override
  ConsumerState<KardexPage> createState() => _KardexPageState();
}

class _KardexPageState extends ConsumerState<KardexPage> {
  late final int? _productoIdFijo;
  String _filtroBusqueda = '';
  TipoMovimiento? _filtroTipo;

  @override
void initState() {
  super.initState();
  final pid = widget.productoId; // ← ÚNICA línea nueva
  _productoIdFijo = pid != null ? int.tryParse(pid) : null; // ← Solo cambia la referencia
}

  @override
  Widget build(BuildContext context) {
    final movimientosAsync = ref.watch(
      kardexPorProductoProvider(_productoIdFijo?.toString() ?? ''),
    );

    return AppScaffold(
      title: 'Historial de Movimientos',
      body: Padding(
        padding: AppSpacing.allM,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entradas, salidas, ajustes, transferencias y traslados del inventario.',
              style: AppTypography.labelMedium,
            ),
            const SizedBox(height: AppSpacing.m),
            // ✅ Usar AppForm
// ✅ Reemplaza TODO el Row anterior por esto:
AppForm(
  columnsMobile: 1,
  columnsTablet: 2,
  columnsDesktop: 2,
  fields: [
    AppTextField(
      hint: 'Buscar por producto...',
      onChanged: (valor) => setState(() => _filtroBusqueda = valor),
    ),
    AppDropdown<TipoMovimiento>(
      initialValue: _filtroTipo,
      hint: 'Tipo',
      items: TipoMovimiento.values.map((tipo) {
        return DropdownMenuItem<TipoMovimiento>(
          value: tipo,
          child: Text(
            tipo.name.toUpperCase(),
            style: AppTypography.bodyMedium,
          ),
        );
      }).toList(),
      onChanged: (valor) => setState(() => _filtroTipo = valor),
    ),
  ],
),
            const SizedBox(height: AppSpacing.m),
            Expanded(
              child: movimientosAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text('Error: $error', style: AppTypography.labelMedium.copyWith(color: Colors.red)),
                ),
                data: (movimientos) {
                  final filtrados = movimientos.where((mov) {
                    if (_productoIdFijo != null && mov.productoId != _productoIdFijo) return false;
                    final coincideTexto = mov.productoId.toString().contains(_filtroBusqueda) ||
                        (mov.documentoReferencia?.toLowerCase().contains(_filtroBusqueda) ?? false);
                    final coincideTipo = _filtroTipo == null || mov.tipoMovimiento == _filtroTipo;
                    return coincideTexto && coincideTipo;
                  }).toList();

                  if (filtrados.isEmpty) {
                    return Center(child: Text('Sin movimientos registrados.', style: AppTypography.bodyMedium.copyWith(color: const Color(0xFF64748B))));
                  }

                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: filtrados.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s),
                    itemBuilder: (_, indice) {
                      final mov = filtrados[indice];
                      final colorTipo = switch(mov.tipoMovimiento) {
                        TipoMovimiento.entrada => const Color(0xFF10B981),
                        TipoMovimiento.salida => const Color(0xFFEF4444),
                        TipoMovimiento.ajuste => const Color(0xFFF59E0B),
                        TipoMovimiento.transferencia => const Color(0xFF6366F1),
                        _ => const Color(0xFF8B5CF6),
                      };

                      return AppCard(
                        padding: AppSpacing.allM,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 6,
                              height: 56,
                              decoration: BoxDecoration(color: colorTipo, borderRadius: BorderRadius.circular(3)),
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
                                    'Prod: ${mov.productoId} • Doc: ${mov.documentoReferencia ?? 'Sin doc'}',
                                    style: AppTypography.bodySmall.copyWith(color: const Color(0xFF64748B)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Cant: ${mov.cantidad} | Saldo: ${mov.saldoAnterior} → ${mov.saldoNuevo}',
                                    style: AppTypography.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${mov.fechaMovimiento?.day ?? '-'}/${mov.fechaMovimiento?.month ?? '-'}/${mov.fechaMovimiento?.year ?? '-'}',

                                  style: AppTypography.bodySmall.copyWith(color: const Color(0xFF94A3B8)),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colorTipo.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    mov.tipoMovimiento == TipoMovimiento.entrada ? 'Entrante' : 'Saliente',
                                    style: AppTypography.labelSmall.copyWith(color: colorTipo, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
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
      ),
    );
  }
}
