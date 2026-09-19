import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/detalle_compra.dart';
import 'package:fiscogest_rd/features/comercial/presentation/providers/compra/compra_usecase_providers.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart' as repo;
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/historial_costos_page.dart';

class DetalleCompraPage extends ConsumerStatefulWidget {
  const DetalleCompraPage({
    super.key,
    required this.compraId,
  });

  static const String routeName = 'detalle-compra';
  final Object compraId;

  @override
  ConsumerState<DetalleCompraPage> createState() => _DetalleCompraPageState();
}

class _DetalleCompraPageState extends ConsumerState<DetalleCompraPage> {
  int _compraId = 0;
  List<DetalleCompra> _detalles = [];
  bool _cargandoDetalles = true;

  @override
  void initState() {
    super.initState();
    _procesarCompraId();
    _cargarDetalles();
  }

  void _procesarCompraId() {
    _compraId = switch (widget.compraId) {
      final int valorInt => valorInt,
      final String valorStr =>
        int.tryParse(valorStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      _ => 0,
    };
  }

  Future<void> _cargarDetalles() async {
    if (_compraId == 0) {
      if (mounted) setState(() => _cargandoDetalles = false);
      return;
    }
    if (mounted) setState(() => _cargandoDetalles = true);
    final repoCompra = ref.read(repo.compraRepositoryProvider);
    final lista = await repoCompra.listarDetallesDeCompra(_compraId);
    if (mounted) {
      setState(() {
        _detalles = lista;
        _cargandoDetalles = false;
      });
    }
  }

  String _formatearFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy').format(fecha);
  }

  String _formatearMonto(double valor) {
    return NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$').format(valor);
  }

  @override
  Widget build(BuildContext context) {
    final compraAsync = ref.watch(compraPorIdProvider(_compraId));
    final ancho = MediaQuery.of(context).size.width;
    final esPequena = ancho < 768;

    return AppScaffold(
      title: 'Detalle de Compra',
      body: SafeArea(
        bottom: true,
        child: _compraId == 0
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'ID de compra no válido',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
            : compraAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: AppLayout.pantallaPadding,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text(
                          'Error al cargar la compra',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('$error', textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
                data: (compra) {
                  if (compra == null) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Compra no encontrada',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  final vencida = compra.estaVencida;

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(compraPorIdProvider(_compraId));
                      await _cargarDetalles();
                    },
                    child: SingleChildScrollView(
                      padding: AppLayout.pantallaPadding,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildCabecera(compra, vencida, esPequena),
                          const SizedBox(height: AppSpacing.m),
                          _buildTarjetaInformacion(compra, vencida, esPequena),
                          const SizedBox(height: AppSpacing.m),
                          _buildTarjetaTotales(compra, esPequena),
                          const SizedBox(height: AppSpacing.m),
                          _buildSeccionDetalles(compra, esPequena),
                          const SizedBox(height: AppSpacing.l),
                          _buildBotonesAccion(compra, esPequena),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildCabecera(Compra compra, bool vencida, bool esPequena) {
    final (color, texto) = switch (compra.estado) {
      EstadoCompra.borrador => (Colors.orange, 'Borrador'),
      EstadoCompra.registrada => (Colors.blue, 'Registrada'),
      EstadoCompra.confirmada => (Colors.green, 'Confirmada'),
      EstadoCompra.recibida => (Colors.teal, 'Recibida'),
      EstadoCompra.pagada => (Colors.purple, 'Pagada'),
      EstadoCompra.anulada => (Colors.red.shade700, 'Anulada'),
      _ => (Colors.grey, 'Desconocida'),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                compra.numeroComprobante.isNotEmpty
                    ? compra.numeroComprobante
                    : 'Compra #${compra.id}',
                style: TextStyle(
                  fontSize: esPequena ? 18 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                compra.nombreProveedor,
                style: TextStyle(
                  fontSize: esPequena ? 14 : 15,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                texto,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            if (vencida) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Vencida',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTarjetaInformacion(Compra compra, bool vencida, bool esPequena) {
    return Card(
      elevation: vencida ? 2 : 1,
      color: vencida ? Colors.red.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: esPequena ? 16 : 24,
              runSpacing: 12,
              children: [
                _datoInformacion(
                  'Fecha Emisión',
                  _formatearFecha(compra.fechaEmision),
                  esPequena,
                ),
                if (compra.ncf.isNotEmpty)
                  _datoInformacion('NCF', compra.ncf, esPequena),
                _datoInformacion('Tipo', compra.tipoComprobante, esPequena),
                _datoInformacion(
                  'Condición',
                  compra.esCredito ? 'Crédito (${compra.diasCredito} días)' : 'Contado',
                  esPequena,
                ),
                if (compra.esCredito && compra.fechaVencimiento != null)
                  _datoInformacion(
                    'Vencimiento',
                    _formatearFecha(compra.fechaVencimiento!),
                    esPequena,
                    destacado: vencida,
                  ),
                if (compra.fechaConfirmacion != null)
                  _datoInformacion(
                    'Confirmación',
                    _formatearFecha(compra.fechaConfirmacion!),
                    esPequena,
                  ),
              ],
            ),
            if (compra.observaciones != null && compra.observaciones!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(
                'Observaciones',
                style: TextStyle(
                  fontSize: esPequena ? 11 : 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                compra.observaciones!,
                style: TextStyle(
                  fontSize: esPequena ? 13 : 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _datoInformacion(
    String etiqueta,
    String valor,
    bool esPequena, {
    bool destacado = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: TextStyle(
            fontSize: esPequena ? 11 : 12,
            color: destacado ? Colors.red.shade700 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: TextStyle(
            fontSize: esPequena ? 13 : 14,
            fontWeight: FontWeight.w500,
            color: destacado ? Colors.red.shade700 : null,
          ),
        ),
      ],
    );
  }

  Widget _buildTarjetaTotales(Compra compra, bool esPequena) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          children: [
            _filaTotal(
              'Subtotal',
              _formatearMonto(compra.subtotalSinImpuestos),
              esPequena,
            ),
            const SizedBox(height: 4),
            _filaTotal(
              'Descuento',
              _formatearMonto(compra.montoDescuentoGlobal),
              esPequena,
            ),
            const SizedBox(height: 4),
            _filaTotal(
              'ITBIS / Impuesto',
              _formatearMonto(compra.montoImpuesto),
              esPequena,
            ),
            const Divider(height: 16),
            _filaTotal(
              'TOTAL',
              _formatearMonto(compra.totalCompra),
              esPequena,
              destacado: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _filaTotal(
    String etiqueta,
    String valor,
    bool esPequena, {
    bool destacado = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          etiqueta,
          style: TextStyle(
            fontSize: esPequena ? 13 : 14,
            fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            fontSize: esPequena ? 13 : 14,
            fontWeight: destacado ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSeccionDetalles(Compra compra, bool esPequena) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Artículos (${_detalles.length})',
                  style: TextStyle(
                    fontSize: esPequena ? 15 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            if (_cargandoDetalles)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_detalles.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'Sin líneas de detalle registradas',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._detalles.map((detalle) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: InkWell(
                    onTap: () {
                      context.pushNamed(
                        HistorialCostosPage.routeName,
                        pathParameters: {
                          'productoId': detalle.productoId.toString(),
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: esPequena
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        detalle.nombreProducto,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatearMonto(detalle.totalLinea),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 2,
                                  children: [
                                    Text(
                                      'Cant: ${detalle.cantidad}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      'Unit: ${_formatearMonto(detalle.costoUnitario)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    if (detalle.descuentoPorcentaje > 0)
                                      Text(
                                        'Desc: ${detalle.descuentoPorcentaje.toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Subtotal: ${_formatearMonto(detalle.subtotalLinea)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Base: ${_formatearMonto(detalle.baseImponibleLinea)} · ITBIS: ${_formatearMonto(detalle.itbisLinea)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        detalle.nombreProducto,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (detalle.descuentoPorcentaje > 0)
                                        Text(
                                          'Desc: ${detalle.descuentoPorcentaje.toStringAsFixed(0)}%',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    detalle.cantidad.toString(),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    _formatearMonto(detalle.costoUnitario),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    _formatearMonto(detalle.totalLinea),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonesAccion(Compra compra, bool esPequena) {
    final confirmarCompra = ref.read(confirmarCompraUseCaseProvider);
    final anularCompra = ref.read(anularCompraProvider);

    Future<void> ejecutarConfirmar() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirmar Compra'),
          content: const Text(
            '¿Confirmar esta compra?\n\n'
            'Se actualizará inventario, Kardex, costos de producto y el saldo del proveedor.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sí, Confirmar'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      if (!mounted) return;
      try {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Confirmando compra...')),
          );
        }
        await confirmarCompra(compra.id);
        if (!mounted) return;
        ref.invalidate(compraPorIdProvider(_compraId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Compra confirmada ✅'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }

    Future<void> ejecutarAnular() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Anular Compra'),
          content: const Text(
            '¿Anular esta compra?\n\n'
            'Se revertirá el impacto en inventario, costos y saldo del proveedor.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sí, Anular'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      if (!mounted) return;
      try {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Anulando compra...')),
          );
        }
        await anularCompra(compra.id);
        if (!mounted) return;
        ref.invalidate(compraPorIdProvider(_compraId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Compra anulada ✅'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }

    final botones = <Widget>[];

    if (compra.estado == EstadoCompra.borrador) {
      botones.add(
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_circle, color: Colors.white, size: 18),
            label: const Text('Confirmar', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: ejecutarConfirmar,
          ),
        ),
      );
    }

    if (compra.estado != EstadoCompra.anulada && compra.estado != EstadoCompra.borrador) {
      botones.add(
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.cancel, color: Colors.white, size: 18),
            label: const Text('Anular', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: ejecutarAnular,
          ),
        ),
      );
    }

    botones.add(
      Expanded(
        child: OutlinedButton.icon(
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Volver'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () {
            if (mounted) context.pop();
          },
        ),
      ),
    );

    return Column(
      children: [
        if (esPequena)
          Column(
            children: [
              for (var i = 0; i < botones.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: botones[i]),
              ],
            ],
          )
        else
          Row(
            children: [
              for (var i = 0; i < botones.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                botones[i],
              ],
            ],
          ),
      ],
    );
  }
}
