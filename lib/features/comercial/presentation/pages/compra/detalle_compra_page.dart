import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
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
    try {
      final repoCompra = ref.read(repo.compraRepositoryProvider);
      final lista = await repoCompra.listarDetallesDeCompra(_compraId);
      if (mounted) {
        setState(() {
          _detalles = lista;
          _cargandoDetalles = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _detalles = [];
          _cargandoDetalles = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando detalles: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
                    Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    SizedBox(height: 16),
                    Text('ID de compra no válido', style: AppTypography.h4Bold),
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
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: AppSpacing.m),
                        const Text('Error al cargar la compra', style: AppTypography.h4Bold),
                        const SizedBox(height: AppSpacing.s),
                        Text('$error', textAlign: TextAlign.center, style: AppTypography.bodyMedium),
                      ],
                    ),
                  ),
                ),
                data: (compra) {
                  if (compra == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox_outlined, size: 48, color: AppColors.grey500),
                          const SizedBox(height: 16),
                          Text(
                            'Compra no encontrada',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.grey500),
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
      EstadoCompra.borrador => (AppColors.warning, 'Borrador'),
      EstadoCompra.registrada => (AppColors.primary, 'Registrada'),
      EstadoCompra.confirmada => (AppColors.success, 'Confirmada'),
      EstadoCompra.recibida => (AppColors.secondary, 'Recibida'),
      EstadoCompra.pagada => (AppColors.primaryDark, 'Pagada'),
      EstadoCompra.anulada => (AppColors.error, 'Anulada'),
      _ => (AppColors.grey500, 'Desconocida'),
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
                style: esPequena ? AppTypography.h4 : AppTypography.h3,
              ),
              const SizedBox(height: 4),
              Text(
                compra.nombreProveedor,
                style: TextStyle(
                  fontSize: esPequena ? 14 : 15,
                  color: AppColors.grey700,
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
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Vencida',
                  style: TextStyle(
                    color: AppColors.error,
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
    return AppCard(
      color: vencida ? AppColors.error.withValues(alpha: 0.05) : null,
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
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 8),
            const Text(
              'Observaciones',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              compra.observaciones!,
              style: AppTypography.bodyMedium.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _datoInformacion(
    String etiqueta,
    String valor,
    bool esPequena, {
    bool destacado = false,
  }) {
    final colorEtiqueta = destacado ? AppColors.error : AppColors.textSecondary;
    final colorValor = destacado ? AppColors.error : AppColors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: TextStyle(fontSize: 11, color: colorEtiqueta),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorValor,
          ),
        ),
      ],
    );
  }

  Widget _buildTarjetaTotales(Compra compra, bool esPequena) {
    return AppCard(
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
          const Divider(height: 16, color: AppColors.border),
          _filaTotal(
            'TOTAL',
            _formatearMonto(compra.totalCompra),
            esPequena,
            destacado: true,
          ),
        ],
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
            fontSize: 14,
            fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            fontSize: 14,
            fontWeight: destacado ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSeccionDetalles(Compra compra, bool esPequena) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Artículos (${_detalles.length})',
                style: AppTypography.h4Bold,
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
                  style: TextStyle(color: AppColors.grey500),
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
                                      style: AppTypography.bodyMediumSemiBold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatearMonto(detalle.totalLinea),
                                    style: AppTypography.h4PrimaryBold,
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
                                    style: AppTypography.bodySmall,
                                  ),
                                  Text(
                                    'Unit: ${_formatearMonto(detalle.costoUnitario)}',
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Subtotal: ${_formatearMonto(detalle.subtotalLinea)}',
                                    style: AppTypography.labelMedium,
                                  ),
                                  Text(
                                    'Base: ${_formatearMonto(detalle.baseImponibleLinea)} · ITBIS: ${_formatearMonto(detalle.itbisLinea)}',
                                    style: AppTypography.bodySmall,
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
                                      style: AppTypography.bodyMediumSemiBold,
                                    ),
                                    if (detalle.descuentoPorcentaje > 0)
                                      Text(
                                        'Desc: ${detalle.descuentoPorcentaje.toStringAsFixed(0)}%',
                                        style: AppTypography.bodySmall,
                                      ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(detalle.cantidad.toString(), textAlign: TextAlign.center),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(_formatearMonto(detalle.costoUnitario), textAlign: TextAlign.right),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  _formatearMonto(detalle.totalLinea),
                                  textAlign: TextAlign.right,
                                  style: AppTypography.h4PrimaryBold,
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
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.white,
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
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
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
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
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
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }

    Widget botonConfirmar() => ElevatedButton.icon(
          icon: const Icon(Icons.check_circle, color: AppColors.white, size: 18),
          label: const Text('Confirmar', style: TextStyle(color: AppColors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: ejecutarConfirmar,
        );

    Widget botonAnular() => ElevatedButton.icon(
          icon: const Icon(Icons.cancel, color: AppColors.white, size: 18),
          label: const Text('Anular', style: TextStyle(color: AppColors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: ejecutarAnular,
        );

    Widget botonVolver() => OutlinedButton.icon(
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Volver'),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
          onPressed: () {
            if (mounted) context.pop();
          },
        );

    final lista = <Widget>[];
    if (compra.estado == EstadoCompra.borrador) {
      lista.add(botonConfirmar());
    }
    if (compra.estado != EstadoCompra.anulada &&
        compra.estado != EstadoCompra.borrador) {
      lista.add(botonAnular());
    }
    lista.add(botonVolver());

    if (esPequena) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < lista.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            lista[i],
          ],
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < lista.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: lista[i]),
        ],
      ],
    );
  }
}
