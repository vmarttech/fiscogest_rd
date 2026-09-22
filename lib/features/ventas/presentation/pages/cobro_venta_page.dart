import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/caja_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/listas_ventas_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart'
    as venta_providers;

class CobroVentaPage extends ConsumerStatefulWidget {
  const CobroVentaPage({super.key});

  static const String routeName = 'cobro-venta';
  static const String path = '/ventas/cobro';

  @override
  ConsumerState<CobroVentaPage> createState() => _CobroVentaPageState();
}

class _CobroVentaPageState extends ConsumerState<CobroVentaPage> {
  final TextEditingController _abonoController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();

  int ventaId = 0;
  double montoTotal = 0.0;
  bool esCredito = false;
  String numeroCotizacion = 'N/A';
  String? nombreCliente;
  FormaPago _formaPago = FormaPago.efectivo;
  bool _procesando = false;
  bool _argsListos = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsListos) return;
    _argsListos = true;

    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    ventaId = args?['ventaId'] as int? ?? 0;
    montoTotal = (args?['montoTotal'] as num?)?.toDouble() ?? 0.0;
    esCredito = args?['esCredito'] as bool? ?? false;
    numeroCotizacion = args?['numeroCotizacion'] as String? ?? 'N/A';
    nombreCliente = args?['nombreCliente'] as String?;

    ref.read(cajaProvider.notifier).inicializarVenta(montoTotal, esCredito);

    if (esCredito) {
      final abonoMinimo = montoTotal * 0.30;
      _abonoController.text = abonoMinimo.toStringAsFixed(2);
      ref.read(cajaProvider.notifier).establecerAbono(abonoMinimo);
    } else {
      _abonoController.text = montoTotal.toStringAsFixed(2);
      ref.read(cajaProvider.notifier).establecerAbono(montoTotal);
    }
  }

  @override
  void dispose() {
    _abonoController.dispose();
    _referenciaController.dispose();
    super.dispose();
  }

  void _onAbonoChanged(String texto) {
    final limpio = texto.trim().replaceAll(',', '.');
    final valor = double.tryParse(limpio) ?? 0.0;
    ref.read(cajaProvider.notifier).establecerAbono(valor);
  }

  Future<void> _cobrarYGenerarFactura() async {
    if (!mounted || _procesando) return;

    final cajaNotifier = ref.read(cajaProvider.notifier);
    final estado = ref.read(cajaProvider);

    if (!cajaNotifier.validarCobroCompleto()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            esCredito
                ? 'El abono debe ser mayor a RD\$ 0 y no exceder el total'
                : 'Debe cubrir el monto total',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (ventaId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Documento de cotización no válido'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _procesando = true);

    try {
      final repositorio = ref.read(venta_providers.ventasRepositoryProvider);
      final Venta venta;

      if (esCredito) {
        venta = await repositorio.registrarVentaConAbono(
          ventaId,
          estado.abono,
          _referenciaController.text.trim(),
        );
      } else {
        venta = await repositorio.confirmarVentaBorrador(ventaId);
      }

      ref.invalidate(listaVentasBorradorProvider);
      ref.invalidate(listaCotizacionesProvider);

      if (!mounted) return;

      final numeroFactura = venta.numeroFactura ?? '—';
      final saldo = esCredito ? (montoTotal - estado.abono) : 0.0;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final esPequena = MediaQuery.of(ctx).size.width < 600;
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Factura generada',
              style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'N° Factura: $numeroFactura',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: esPequena ? 14 : 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ref. Cotización: ${venta.numeroCotizacion}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: esPequena ? 13 : 14,
                  ),
                ),
                if (esCredito) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Abono: RD\$ ${estado.abono.toStringAsFixed(2)}',
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: esPequena ? 13 : 14,
                    ),
                  ),
                  Text(
                    'Saldo pendiente: RD\$ ${saldo.toStringAsFixed(2)}',
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: esPequena ? 13 : 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Aceptar'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cobrar: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(cajaProvider);
    final esPantallaPequena = MediaQuery.of(context).size.width < 600;
    final padding = esPantallaPequena ? 12.0 : 16.0;
    final tamanoCuerpo = esPantallaPequena ? 13.0 : 14.0;
    final tamanoTotal = esPantallaPequena ? 22.0 : 26.0;
    final tamanoEtiqueta = esPantallaPequena ? 11.0 : 12.0;
    final alturaBoton = esPantallaPequena ? 52.0 : 56.0;

    return AppScaffold(
      title: esCredito ? 'COBRO A CRÉDITO' : 'COBRO EN CAJA',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        bottom: true,
        maintainBottomViewPadding: true,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(padding, padding, padding, 8),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Resumen documento
                    Container(
                      padding: EdgeInsets.all(esPantallaPequena ? 14 : 16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'N° $numeroCotizacion',
                                  style: AppTypography.h4.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: esPantallaPequena ? 16 : 18,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: esCredito
                                      ? AppColors.warning.withValues(alpha: 0.12)
                                      : AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  esCredito ? 'Crédito' : 'Contado',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: tamanoEtiqueta,
                                    color: esCredito
                                        ? AppColors.warning
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (nombreCliente != null &&
                              nombreCliente!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_outline,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    nombreCliente!,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontSize: tamanoCuerpo,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1),
                          ),
                          Text(
                            'TOTAL A COBRAR',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: tamanoEtiqueta,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'RD\$ ${montoTotal.toStringAsFixed(2)}',
                            style: AppTypography.h3.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: tamanoTotal,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: esPantallaPequena ? 14 : 16),

                    // Forma de pago
                    Text(
                      'Forma de pago',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: esPantallaPequena ? 13 : 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: FormaPago.values.map((forma) {
                        final seleccionado = _formaPago == forma;
                        return ChoiceChip(
                          label: Text(forma.nombre),
                          selected: seleccionado,
                          onSelected: (_) {
                            setState(() => _formaPago = forma);
                          },
                          selectedColor:
                              AppColors.primary.withValues(alpha: 0.15),
                          labelStyle: AppTypography.labelMedium.copyWith(
                            fontWeight: seleccionado
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: seleccionado
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontSize: tamanoCuerpo,
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: esPantallaPequena ? 14 : 16),

                    // Monto / abono
                    Text(
                      esCredito ? 'Abono inicial' : 'Monto a pagar',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: esPantallaPequena ? 13 : 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _abonoController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: esPantallaPequena ? 16 : 18,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        prefixText: 'RD\$ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: esPantallaPequena ? 14 : 16,
                        ),
                      ),
                      onChanged: _onAbonoChanged,
                      enabled: esCredito,
                    ),

                    if (esCredito) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Saldo pendiente: RD\$ ${estado.saldoPendiente.toStringAsFixed(2)}',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: tamanoCuerpo,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                      SizedBox(height: esPantallaPequena ? 12 : 14),
                      TextField(
                        controller: _referenciaController,
                        decoration: InputDecoration(
                          labelText: 'Referencia / observación (opcional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Barra fija COBRAR Y GENERAR FACTURA
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                padding,
                10,
                padding,
                esPantallaPequena ? 12 : 14,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: const Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: alturaBoton,
                  child: ElevatedButton.icon(
                    onPressed:
                        _procesando ? null : _cobrarYGenerarFactura,
                    icon: _procesando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Icon(Icons.receipt_long, size: 22),
                    label: Text(
                      _procesando
                          ? 'Procesando...'
                          : 'COBRAR Y GENERAR FACTURA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: esPantallaPequena ? 13 : 15,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.white,
                      disabledBackgroundColor: AppColors.grey300,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
