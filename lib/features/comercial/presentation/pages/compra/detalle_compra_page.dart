import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/features/comercial/presentation/providers/compra/compra_usecase_providers.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/detalle_compra.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';

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

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'No establecida';
    return fecha.toString().split(' ')[0];
  }

  @override
  Widget build(BuildContext context) {
    final compraAsync = ref.watch(compraPorIdProvider(_idNumerico));
    final confirmarCompra = ref.read(confirmarCompraUseCaseProvider);
    final anularCompra = ref.read(compraRepositoryProvider).anularCompra;
    final ancho = MediaQuery.of(context).size.width;
    final esPequena = ancho < 768;

    return AppScaffold(
      title: 'Detalle de Compra',
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: AppLayout.pantallaPadding,
          child: compraAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
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

              final vencida = compra.estaVencida;

              return FutureBuilder<List<DetalleCompra>>(
                future: _detallesFuture,
                builder: (context, snapshot) {
                  final detalles = snapshot.data ?? const <DetalleCompra>[];

                  Widget buildEstadoTag() {
                    if (vencida && compra.estado == EstadoCompra.registrada) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Vencida',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    final (color, texto) = switch (compra.estado) {
                      EstadoCompra.borrador => (Colors.orange, 'Borrador'),
                      EstadoCompra.registrada => (Colors.blue, 'Registrada'),
                      EstadoCompra.confirmada => (Colors.green, 'Confirmada'),
                      EstadoCompra.recibida => (Colors.teal, 'Recibida'),
                      EstadoCompra.pagada => (Colors.purple, 'Pagada'),
                      EstadoCompra.anulada => (Colors.red.shade700, 'Anulada'),
                      _ => (Colors.grey, 'Desconocida'),
                    };
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        texto,
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              compra.nombreProveedor,
                              style: AppTypography.h4Bold,
                            ),
                          ),
                          buildEstadoTag(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (vencida)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Esta compra está vencida.',
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          Text(
                            'Emisión: ${_formatearFecha(compra.fechaEmision)}',
                            style: AppTypography.bodyMedium,
                          ),
                          Text(
                            'Vencimiento: ${_formatearFecha(compra.fechaVencimientoCalculada)}',
                            style: AppTypography.bodyMedium.copyWith(
                              color: vencida ? Colors.red.shade700 : null,
                              fontWeight: vencida ? FontWeight.bold : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                          Text(
                            'Tipo: ${compra.tipoComprobante}',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          Text(
                            'Pago: ${compra.esCredito ? 'Crédito' : 'Contado'}',
                            style: AppTypography.bodySmall,
                          ),
                          if (compra.esCredito)
                            Text(
                              'Plazo: ${compra.diasCredito} días',
                              style: AppTypography.bodySmall,
                            ),
                        ],
                      ),
                      if (compra.observaciones?.isNotEmpty == true) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Observaciones: ${compra.observaciones}',
                          style: AppTypography.bodySmall.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      const Divider(height: 1, thickness: 1),
                      const SizedBox(height: 16),
                      Text(
                        'Productos (${detalles.length})',
                        style: AppTypography.labelLarge,
                      ),
                      const SizedBox(height: 12),
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
                        ...detalles.map((detalle) => Container(
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
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                children: [
                                  Text('Cant: ${detalle.cantidad}', style: AppTypography.bodySmall),
                                  Text('Costo Unit: RD\$ ${detalle.costoUnitario.toStringAsFixed(2)}', style: AppTypography.bodySmall),
                                  if (detalle.descuentoPorcentaje > 0)
                                    Text('Desc: ${detalle.descuentoPorcentaje.toStringAsFixed(0)}%', style: AppTypography.bodySmall),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Subtotal: RD\$ ${detalle.subtotalLinea.toStringAsFixed(2)}',
                                      style: AppTypography.bodyMediumSemiBold,
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
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),
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
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Divider(),
                              ),
                              Text(
                                'TOTAL: RD\$ ${compra.totalCompra.toStringAsFixed(2)}',
                                style: AppTypography.h4Bold.copyWith(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.arrow_back, size: 18),
                            label: const Text('Volver'),
                            onPressed: () => context.pop(),
                          ),
                          if (!esPequena)
                            Row(
                              children: [
                                if (compra.estado == EstadoCompra.borrador) ...[
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.check_circle, size: 18),
                                    label: const Text('Confirmar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade700,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => _confirmarCompra(compra.id, confirmarCompra.call),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (compra.estado != EstadoCompra.anulada) ...[
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.cancel, size: 18),
                                    label: const Text('Anular'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade700,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => _anularCompra(compra.id, anularCompra),
                                  ),
                                ],
                              ],
                            ),
                        ],
                      ),
                      if (esPequena) ...[
                        const SizedBox(height: 12),
                        if (compra.estado == EstadoCompra.borrador)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.check_circle, size: 18),
                              label: const Text('Confirmar Compra'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _confirmarCompra(compra.id, confirmarCompra.call),
                            ),
                          ),
                        if (compra.estado != EstadoCompra.anulada) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.cancel, size: 18),
                              label: const Text('Anular Compra'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade700,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _anularCompra(compra.id, anularCompra),
                            ),
                          ),
                        ],
                      ],
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

  Future<void> _confirmarCompra(int compraId, Future<Compra> Function(int) confirmar) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Compra'),
        content: const Text(
          '¿Confirmar esta compra?\n\n'
          'Se actualizará inventario, Kardex, costos de producto y el saldo del proveedor.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, Confirmar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Confirmando compra...')));

    try {
      await confirmar(compraId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compra confirmada ✅'), backgroundColor: Colors.green),
      );
      ref.invalidate(compraPorIdProvider(compraId));
      ref.invalidate(listadoComprasProvider);
      ref.invalidate(productoControllerProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _anularCompra(int compraId, Future<Compra> Function(int) anular) async {
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anular Compra'),
        content: const Text(
          '¿Anular esta compra?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, Anular'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anulando compra...')));

    try {
      await anular(compraId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compra anulada ✅'), backgroundColor: Colors.green),
      );
      ref.invalidate(compraPorIdProvider(compraId));
      ref.invalidate(listadoComprasProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
