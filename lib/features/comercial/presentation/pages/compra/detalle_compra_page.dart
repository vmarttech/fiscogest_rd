import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';
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
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart'
    as repo;
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/historial_costos_page.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';

class DetalleCompraPage extends ConsumerStatefulWidget {
  const DetalleCompraPage({super.key, required this.compraId});
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
        FiscoGestNotifications.show(
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

  String _formatearMonto(double valor) => formatRd(valor);

  @override
  Widget build(BuildContext context) {
    final compraAsync = ref.watch(compraPorIdProvider(_compraId));
    final ancho = MediaQuery.of(context).size.width;
    final esPequena = ancho < 768;
    final modoSimplificado =
        ref.watch(configuracionControllerProvider).valueOrNull?.modoSimplificado ??
        false;

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
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: AppSpacing.m),
                        const Text(
                          'Error al cargar la compra',
                          style: AppTypography.h4Bold,
                        ),
                        const SizedBox(height: AppSpacing.s),
                        Text(
                          '$error',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium,
                        ),
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
                          const Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: AppColors.grey500,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Compra no encontrada',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.grey500,
                            ),
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
                          _buildTarjetaInformacion(
                            compra, vencida, esPequena, modoSimplificado,
                          ),
                          const SizedBox(height: AppSpacing.m),
                          _buildTarjetaTotales(compra, esPequena, modoSimplificado),
                          const SizedBox(height: AppSpacing.m),
                          _buildSeccionDetalles(
                            compra, esPequena, modoSimplificado,
                          ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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

  Widget _buildTarjetaInformacion(
    Compra compra, bool vencida, bool esPequena, bool modoSimplificado,
  ) {
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
              if (!modoSimplificado && compra.ncf.isNotEmpty)
                _datoInformacion('NCF', compra.ncf, esPequena),
              if (!modoSimplificado)
                _datoInformacion('Tipo', compra.tipoComprobante, esPequena),
              _datoInformacion(
                'Condición',
                compra.esCredito
                    ? 'Crédito (${compra.diasCredito} días)'
                    : 'Contado',
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
              if (compra.fechaRecepcion != null)
                _datoInformacion(
                  'Recepción',
                  _formatearFecha(compra.fechaRecepcion!),
                  esPequena,
                ),
              if (compra.fechaPago != null)
                _datoInformacion(
                  'Fecha Pago',
                  _formatearFecha(compra.fechaPago!),
                  esPequena,
                ),
            ],
          ),
          if (compra.observaciones != null &&
              compra.observaciones!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 8),
            const Text(
              'Observaciones',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              compra.observaciones!,
              style: AppTypography.bodyMedium.copyWith(
                fontStyle: FontStyle.italic,
              ),
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
        Text(etiqueta, style: TextStyle(fontSize: 11, color: colorEtiqueta)),
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

  Widget _buildTarjetaTotales(
    Compra compra, bool esPequena, bool modoSimplificado,
  ) {
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
          if (!modoSimplificado)
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

  Widget _buildSeccionDetalles(
    Compra compra, bool esPequena, bool modoSimplificado,
  ) {
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                  if (!modoSimplificado)
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
    final marcarComoRecibida = ref.read(marcarComoRecibidaProvider);
    final marcarComoPagada = ref.read(marcarComoPagadaProvider);
    final anularCompra = ref.read(anularCompraProvider);

    Future<bool?> confirmarDialogo({
      required String titulo,
      required String contenido,
      required String etiquetaBoton,
      required Color colorBoton,
    }) async {
      return showDialog<bool>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: Text(titulo),
          content: Text(contenido),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorBoton,
                foregroundColor: AppColors.white,
              ),
              onPressed: () {
                Navigator.of(ctx).pop(true);
              },
              child: Text(etiquetaBoton),
            ),
          ],
        ),
      );
    }

    Future<void> ejecutarConfirmar() async {
      final ok = await confirmarDialogo(
        titulo: 'Confirmar Compra',
        contenido:
            '¿Confirmar esta compra?\n\nSe actualizará inventario, Kardex, costos de producto y el saldo del proveedor.',
        etiquetaBoton: 'Sí, Confirmar',
        colorBoton: AppColors.success,
      );
      if (ok != true) return;
      if (!mounted) return;
      try {
        if (mounted) {
          FiscoGestNotifications.show(
            const SnackBar(content: Text('Confirmando compra...')),
          );
        }
        await confirmarCompra(compra.id);
        ref.invalidate(productoControllerProvider);
        if (!mounted) return;
        ref.invalidate(compraPorIdProvider(_compraId));
        if (mounted) {
          FiscoGestNotifications.show(
            const SnackBar(
              content: Text('Compra confirmada ✅'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        if (mounted) {
          FiscoGestNotifications.show(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    Future<void> ejecutarMarcarComoRecibida() async {
      final ok = await confirmarDialogo(
        titulo: 'Marcar como Recibida',
        contenido:
            '¿Confirmas que los productos de esta compra han sido recibidos?\n\nSe registrará la fecha de recepción.',
        etiquetaBoton: 'Sí, Recibida',
        colorBoton: AppColors.secondary,
      );
      if (ok != true) return;
      if (!mounted) return;
      try {
        if (mounted) {
          FiscoGestNotifications.show(
            const SnackBar(content: Text('Registrando recepción...')),
          );
        }
        await marcarComoRecibida(compra.id);
        if (!mounted) return;
        ref.invalidate(compraPorIdProvider(_compraId));
        if (mounted) {
          FiscoGestNotifications.show(
            const SnackBar(
              content: Text('Compra marcada como Recibida ✅'),
              backgroundColor: AppColors.secondary,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        if (mounted) {
          FiscoGestNotifications.show(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    Future<void> ejecutarMarcarComoPagada() async {
      final ok = await confirmarDialogo(
        titulo: 'Marcar como Pagada',
        contenido:
            '¿Marcar esta compra como Pagada?\n\nSe registrará la fecha de pago y pasará a estado Pagada.',
        etiquetaBoton: 'Sí, Pagada',
        colorBoton: AppColors.primaryDark,
      );
      if (ok != true) return;
      if (!mounted) return;
      try {
        if (mounted) {
          FiscoGestNotifications.show(
            const SnackBar(content: Text('Registrando pago...')),
          );
        }
        await marcarComoPagada(compra.id);
        if (!mounted) return;
        ref.invalidate(compraPorIdProvider(_compraId));
        if (mounted) {
          FiscoGestNotifications.show(
            const SnackBar(
              content: Text('Compra marcada como Pagada ✅'),
              backgroundColor: AppColors.primaryDark,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        if (mounted) {
          FiscoGestNotifications.show(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    Future<void> ejecutarAnular() async {
      final ok = await confirmarDialogo(
        titulo: 'Anular Compra',
        contenido: '¿Anular esta compra?\n\nEsta acción no se puede deshacer.',
        etiquetaBoton: 'Sí, Anular',
        colorBoton: AppColors.error,
      );
      if (ok != true) return;
      if (!mounted) return;
      try {
        if (mounted) {
          FiscoGestNotifications.show(
            const SnackBar(content: Text('Anulando compra...')),
          );
        }
        await anularCompra(compra.id);
        if (!mounted) return;
        ref.invalidate(compraPorIdProvider(_compraId));
        if (mounted) {
          FiscoGestNotifications.show(
            const SnackBar(
              content: Text('Compra anulada ✅'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        if (mounted) {
          FiscoGestNotifications.show(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    final botones = <Widget>[];

    if (compra.estado == EstadoCompra.borrador ||
        compra.estado == EstadoCompra.registrada) {
      botones.add(
        SizedBox(
          width: esPequena ? double.infinity : 160,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Confirmar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
            ),
            onPressed: ejecutarConfirmar,
          ),
        ),
      );
    }

    if (compra.estado == EstadoCompra.confirmada) {
      botones.add(
        SizedBox(
          width: esPequena ? double.infinity : 160,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.inventory, size: 18),
            label: const Text('Marcar Recibida'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.white,
            ),
            onPressed: ejecutarMarcarComoRecibida,
          ),
        ),
      );
    }

    if (compra.estado == EstadoCompra.recibida ||
        compra.estado == EstadoCompra.confirmada) {
      botones.add(
        SizedBox(
          width: esPequena ? double.infinity : 160,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.payment, size: 18),
            label: const Text('Marcar Pagada'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: AppColors.white,
            ),
            onPressed: ejecutarMarcarComoPagada,
          ),
        ),
      );
    }

    if (compra.estado != EstadoCompra.anulada &&
        compra.estado != EstadoCompra.borrador) {
      botones.add(
        SizedBox(
          width: esPequena ? double.infinity : 160,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.cancel, size: 18),
            label: const Text('Anular'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
            onPressed: ejecutarAnular,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: botones,
    );
  }
}
