import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/comercial/presentation/providers/compra/compra_usecase_providers.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/detalle_compra.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';

class DetalleCompraPage extends ConsumerStatefulWidget {
  const DetalleCompraPage({super.key, required this.compraId});
  static const String routeName = 'detalle-compra';
  final Object compraId;

  @override
  ConsumerState<DetalleCompraPage> createState() => _DetalleCompraPageState();
}

class _DetalleCompraPageState extends ConsumerState<DetalleCompraPage> {
  late final int _idNumerico;
  late final Future<List<DetalleCompra>> _detallesFuture;

  @override
  void initState() {
    super.initState();
    _idNumerico = switch (widget.compraId) {
      final int id => id,
      final String idStr => int.tryParse(idStr) ?? 0,
      _ => 0,
    };
    final repositorio = ref.read(compraRepositoryProvider);
    _detallesFuture = repositorio.listarDetallesDeCompra(_idNumerico);
  }

  @override
  Widget build(BuildContext context) {
    final compraAsync = ref.watch(compraPorIdProvider(_idNumerico));
    return AppScaffold(
      title: 'Detalle de Compra',
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: AppLayout.pantallaPadding,
          child: compraAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, pila) => Center(
              child: Padding(
                padding: AppSpacing.allM,
                child: Text(
                  'Error al cargar compra: $error',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelMedium.copyWith(color: AppColors.error),
                ),
              ),
            ),
            data: (compra) {
              if (compra == null) {
                return const Center(
                  child: Padding(
                    padding: AppSpacing.allL,
                    child: Text(
                      'Compra no encontrada.',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                );
              }
              return FutureBuilder<List<DetalleCompra>>(
                future: _detallesFuture,
                builder: (context, snapshot) {
                  final detalles = snapshot.data ?? const <DetalleCompra>[];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(compra.nombreProveedor, style: AppTypography.h4Bold),
                      const SizedBox(height: 4),
                      Text(
                        'Fecha Emisión: ${compra.fechaEmision.toString().split(' ')[0]}',
                        style: AppTypography.bodyMedium,
                      ),
                      if (compra.fechaVencimiento != null)
                        Text(
                          'Vencimiento: ${compra.fechaVencimiento!.toString().split(' ')[0]}',
                          style: AppTypography.bodyMedium,
                        ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          if (compra.numeroComprobante.isNotEmpty)
                            Text(
                              'Factura: ${compra.numeroComprobante}',
                              style: AppTypography.bodyMedium,
                            ),
                          if (compra.ncf.isNotEmpty)
                            Text(
                              'NCF: ${compra.ncf}',
                              style: AppTypography.bodyMediumSemiBold,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          Text(
                            'Tipo: ${compra.tipoComprobante}',
                            style: AppTypography.bodySmall,
                          ),
                          Text(
                            'Pago: ${compra.formaPago}',
                            style: AppTypography.bodySmall,
                          ),
                          if (compra.formaPago == 'credito') ...[
                            Text(
                              'Condición: ${compra.condicionPago} (${compra.diasCredito} días)',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ],
                      ),
                      if (compra.observaciones?.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Observaciones: ${compra.observaciones}',
                          style: AppTypography.bodySmall.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Divider(height: 1, thickness: 1),
                      const SizedBox(height: 16),
                      Text(
                        'Productos (${detalles.length})',
                        style: AppTypography.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (snapshot.hasError)
                        Padding(
                          padding: AppSpacing.allM,
                          child: Text(
                            'No se pudieron cargar los detalles: ${snapshot.error}',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                          ),
                        )
                      else if (detalles.isEmpty)
                        const Padding(
                          padding: AppSpacing.allL,
                          child: Text(
                            'Sin productos registrados en esta compra.',
                            style: AppTypography.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        ...detalles.map((final DetalleCompra detalle) => Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: AppSpacing.allM,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      detalle.nombreProducto,
                                      style: AppTypography.bodyMediumSemiBold,
                                    ),
                                  ),
                                  Text(
                                    'RD\$ ${detalle.totalLinea.toStringAsFixed(2)}',
                                    style: AppTypography.bodyMediumBold.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 12,
                                runSpacing: 2,
                                children: [
                                  Text('Cant: ${detalle.cantidad}', style: AppTypography.bodySmall),
                                  Text(
                                    'Costo Unit: RD\$ ${detalle.costoUnitario.toStringAsFixed(2)}',
                                    style: AppTypography.bodySmall,
                                  ),
                                  if (detalle.fleteUnitario > 0)
                                    Text(
                                      'Flete: RD\$ ${detalle.fleteUnitario.toStringAsFixed(2)}',
                                      style: AppTypography.bodySmall,
                                    ),
                                  if (detalle.seguroUnitario > 0)
                                    Text(
                                      'Seguro: RD\$ ${detalle.seguroUnitario.toStringAsFixed(2)}',
                                      style: AppTypography.bodySmall,
                                    ),
                                  if (detalle.arancelesUnitario > 0)
                                    Text(
                                      'Aranceles: RD\$ ${detalle.arancelesUnitario.toStringAsFixed(2)}',
                                      style: AppTypography.bodySmall,
                                    ),
                                  if (detalle.gastosUnitario > 0)
                                    Text(
                                      'Otros: RD\$ ${detalle.gastosUnitario.toStringAsFixed(2)}',
                                      style: AppTypography.bodySmall,
                                    ),
                                  if (detalle.descuentoPorcentaje > 0)
                                    Text(
                                      'Desc: ${detalle.descuentoPorcentaje.toStringAsFixed(0)}%',
                                      style: AppTypography.bodySmall,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Costo Adquisición: RD\$ ${detalle.costoAdquisicion.toStringAsFixed(2)}',
                                      style: AppTypography.bodyMediumSemiBold.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Subtotal: RD\$ ${detalle.subtotalLinea.toStringAsFixed(2)}',
                                      style: AppTypography.bodySmall,
                                    ),
                                    Text(
                                      'Base Imponible: RD\$ ${detalle.baseImponibleLinea.toStringAsFixed(2)}',
                                      style: AppTypography.bodySmall,
                                    ),
                                    Text(
                                      'ITBIS (18%): RD\$ ${detalle.itbisLinea.toStringAsFixed(2)}',
                                      style: AppTypography.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Subtotal: RD\$ ${compra.subtotalSinImpuestos.toStringAsFixed(2)}',
                                style: AppTypography.bodyMedium,
                              ),
                              Text(
                                'Descuentos: RD\$ ${compra.montoDescuentoGlobal.toStringAsFixed(2)}',
                                style: AppTypography.bodyMedium,
                              ),
                              Text(
                                'ITBIS: RD\$ ${compra.montoImpuesto.toStringAsFixed(2)}',
                                style: AppTypography.bodyMedium,
                              ),
                              const Divider(),
                              Text(
                                'TOTAL: RD\$ ${compra.totalCompra.toStringAsFixed(2)}',
                                style: AppTypography.h4Bold.copyWith(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
