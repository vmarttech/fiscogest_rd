import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_form.dart';
import 'package:fiscogest_rd/core/ui/app_section.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/abono_credito.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/cuenta_por_cobrar.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/cuota.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/estado_credito.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/plan_pago.dart';
import 'package:fiscogest_rd/features/creditos/domain/services/calculadora_credito_service.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_provider.dart';

class ResultadoFormularioCredito {
  const ResultadoFormularioCredito({
    required this.cuenta,
    this.planPago,
    this.abonoInicial,
  });

  final CuentaPorCobrar cuenta;
  final PlanPago? planPago;
  final AbonoCredito? abonoInicial;
}

class FormularioCreditoDialog extends ConsumerStatefulWidget {
  const FormularioCreditoDialog({
    super.key,
    required this.estadoVenta,
    this.onVolver,
    this.onResultado,
  });

  final RegistrarVentaState estadoVenta;
  final VoidCallback? onVolver;
  final void Function(ResultadoFormularioCredito)? onResultado;
  static const String routeName = 'formulario-credito';

  static Future<ResultadoFormularioCredito?> navegar(
    BuildContext context,
    RegistrarVentaState estadoVenta,
  ) async {
    return showDialog<ResultadoFormularioCredito>(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: 900,
          height: 700,
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: FormularioCreditoDialog(estadoVenta: estadoVenta),
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<FormularioCreditoDialog> createState() =>
      _FormularioCreditoDialogState();
}

class _FormularioCreditoDialogState
    extends ConsumerState<FormularioCreditoDialog> {
  static final NumberFormat _formatoMonto = NumberFormat.currency(
    locale: 'es_DO',
    symbol: 'RD\$ ',
    decimalDigits: 2,
    customPattern: '¤ #,##0.00',
  );
  static final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy');

  late final TextEditingController _abonoInicialController;
  late final TextEditingController _tasaInteresController;
  late final TextEditingController _observacionesController;
  int _plazoMeses = 1;
  int _numeroCuotas = 1;
  late DateTime _fechaPrimerVencimiento;
  bool _mostrarTablaCuotas = false;
  bool _guardando = false;

  static const List<int> _opcionesPlazo = [1, 2, 3, 6];
  static const List<int> _opcionesCuotas = [1, 2, 3, 6];
  static const List<double> _opcionesTasa = [0.0, 0.03, 0.05, 0.08, 0.10];

  @override
  void initState() {
    super.initState();
    _abonoInicialController = TextEditingController(text: '0');
    _tasaInteresController = TextEditingController(text: '0.05');
    _observacionesController = TextEditingController();
    _fechaPrimerVencimiento = DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _abonoInicialController.dispose();
    _tasaInteresController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  double get _totalVenta => widget.estadoVenta.total;
  double get _abonoInicial {
    final valor = double.tryParse(_abonoInicialController.text) ?? 0.0;
    return valor.clamp(0.0, _totalVenta);
  }
  double get _saldoFinanciado => (_totalVenta - _abonoInicial).clamp(0.0, double.infinity);
  double get _tasaMensual {
    return double.tryParse(_tasaInteresController.text) ?? 0.05;
  }

  ResumenCreditoCliente get _resumen {
    return CalculadoraCreditoService.generarResumenCliente(
      totalVenta: _totalVenta,
      abonoInicial: _abonoInicial,
      tasaMensual: _tasaMensual,
      numeroCuotas: _numeroCuotas,
      fechaPrimerVencimiento: _fechaPrimerVencimiento,
    );
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaPrimerVencimiento,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'DO'),
    );
    if (fecha != null) {
      setState(() {
        _fechaPrimerVencimiento = fecha;
      });
    }
  }

  void _accionVolver() {
    if (widget.onVolver != null) {
      widget.onVolver!();
    } else if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> _confirmar() async {
    if (_saldoFinanciado <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El saldo financiado debe ser mayor a RD\$ 0.00'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() => _guardando = true);

    try {
      final resumen = _resumen;
      final ahora = DateTime.now();
      final fechaVencimientoFinal = _numeroCuotas <= 1
          ? _fechaPrimerVencimiento
          : _fechaPrimerVencimiento.add(Duration(days: 30 * (_numeroCuotas - 1)));

      PlanPago? planPago;
      if (_numeroCuotas > 1) {
        planPago = CalculadoraCreditoService.generarPlanPago(
          capital: _saldoFinanciado,
          tasaMensual: _tasaMensual,
          numeroCuotas: _numeroCuotas,
          fechaPrimerVencimiento: _fechaPrimerVencimiento,
        );
      }

      final cuenta = CuentaPorCobrar(
        clienteId: widget.estadoVenta.clienteId ?? 0,
        clienteNombre: widget.estadoVenta.clienteNombre,
        ventaId: null,
        totalOriginal: _totalVenta,
        abonoInicial: _abonoInicial,
        tasaInteres: _tasaMensual,
        montoInteres: resumen.montoInteres,
        plazoDias: _plazoMeses * 30,
        numeroCuotas: _numeroCuotas,
        planPago: planPago,
        fechaCreacion: ahora,
        fechaVencimiento: fechaVencimientoFinal,
        estado: EstadoCredito.alDia,
        observaciones: _observacionesController.text.trim().isEmpty
            ? null
            : _observacionesController.text.trim(),
        usuarioId: widget.estadoVenta.usuarioId,
      );

      AbonoCredito? abonoInicial;
      if (_abonoInicial > 0.001) {
        abonoInicial = AbonoCredito(
          cuentaId: 0,
          monto: _abonoInicial,
          metodoPago: widget.estadoVenta.tipoPago,
          fecha: ahora,
          usuarioId: widget.estadoVenta.usuarioId,
        );
      }

      final resultado = ResultadoFormularioCredito(
        cuenta: cuenta,
        planPago: planPago,
        abonoInicial: abonoInicial,
      );

      if (!mounted) return;

      if (widget.onResultado != null) {
        widget.onResultado!(resultado);
      } else if (Navigator.canPop(context)) {
        Navigator.pop(context, resultado);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final resumen = _resumen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            AppButton(
              text: '← VOLVER',
              onPressed: _guardando ? null : _accionVolver,
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Text(
                'Formulario de Crédito',
                style: AppTypography.h4Bold.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        Flexible(
          child: SingleChildScrollView(
            child: AppForm(
              fields: [
                AppSection(
                  title: 'Datos de la venta',
                  children: [
                    _buildFilaSoloLectura(
                      'Cliente:',
                      widget.estadoVenta.clienteNombre ?? 'Consumidor Final',
                    ),
                    _buildFilaSoloLectura(
                      'Total de venta:',
                      _formatoMonto.format(_totalVenta),
                      destacado: true,
                    ),
                  ],
                ),
                AppSection(
                  title: 'Condiciones del crédito',
                  children: [
                    AppTextField(
                      controller: _abonoInicialController,
                      keyboardType: TextInputType.number,
                      label: 'Abono inicial (RD\$)',
                      hint: '0.00',
                      onChanged: (_) => setState(() {}),
                    ),
                    _buildSelectorEtiqueta('Plazo:'),
                    Wrap(
                      spacing: AppSpacing.s,
                      children: _opcionesPlazo.map((meses) {
                        final activo = _plazoMeses == meses;
                        return ChoiceChip(
                          label: Text('$meses ${meses == 1 ? 'mes' : 'meses'}'),
                          selected: activo,
                          onSelected: (_) {
                            setState(() {
                              _plazoMeses = meses;
                              if (_numeroCuotas > meses) {
                                _numeroCuotas = meses;
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    _buildSelectorEtiqueta('Número de cuotas:'),
                    Wrap(
                      spacing: AppSpacing.s,
                      children: _opcionesCuotas
                          .where((c) => c <= _plazoMeses)
                          .map((cuotas) {
                        final activo = _numeroCuotas == cuotas;
                        return ChoiceChip(
                          label: Text('$cuotas ${cuotas == 1 ? 'cuota' : 'cuotas'}'),
                          selected: activo,
                          onSelected: (_) => setState(() => _numeroCuotas = cuotas),
                        );
                      }).toList(),
                    ),
                    InkWell(
                      onTap: _seleccionarFecha,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha primer vencimiento',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _formatoFecha.format(_fechaPrimerVencimiento),
                          style: AppTypography.labelMedium,
                        ),
                      ),
                    ),
                    _buildSelectorEtiqueta('Tasa mensual:'),
                    Wrap(
                      spacing: AppSpacing.s,
                      children: _opcionesTasa.map((tasa) {
                        final activo = (_tasaMensual - tasa).abs() < 0.001;
                        return ChoiceChip(
                          label: Text('${(tasa * 100).toStringAsFixed(0)}%'),
                          selected: activo,
                          onSelected: (_) {
                            setState(() {
                              _tasaInteresController.text = tasa.toString();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    AppTextField(
                      controller: _observacionesController,
                      label: 'Observaciones (opcional)',
                    ),
                  ],
                ),
                AppSection(
                  title: 'Resumen para el cliente',
                  children: [
                    _buildFilaResumen(
                      'Total venta:',
                      _formatoMonto.format(resumen.totalVenta),
                    ),
                    _buildFilaResumen(
                      'Abono inicial:',
                      _formatoMonto.format(resumen.abonoInicial),
                    ),
                    _buildFilaResumen(
                      'Saldo financiado:',
                      _formatoMonto.format(resumen.saldoFinanciado),
                    ),
                    if (resumen.montoInteres > 0.001)
                      _buildFilaResumen(
                        'Interés:',
                        '+ ${_formatoMonto.format(resumen.montoInteres)}',
                        colorTexto: AppColors.error,
                      ),
                    _buildFilaResumen(
                      'TOTAL A PAGAR:',
                      _formatoMonto.format(resumen.totalAPagar),
                      destacado: true,
                      colorTexto: AppColors.primary,
                    ),
                    _buildFilaResumen(
                      resumen.numeroCuotas == 1
                          ? 'Pago único:'
                          : '${resumen.numeroCuotas} cuotas de:',
                      _formatoMonto.format(resumen.montoPorCuota),
                    ),
                    _buildFilaResumen(
                      'Primer vencimiento:',
                      _formatoFecha.format(resumen.fechaPrimerVencimiento),
                    ),
                    if (resumen.cuotas.isNotEmpty) ...[
                      TextButton.icon(
                        onPressed: () => setState(
                            () => _mostrarTablaCuotas = !_mostrarTablaCuotas),
                        icon: Icon(_mostrarTablaCuotas
                            ? Icons.expand_less
                            : Icons.expand_more),
                        label: Text(
                          _mostrarTablaCuotas
                              ? 'Ocultar tabla'
                              : 'Ver tabla de cuotas',
                          style: AppTypography.labelMedium,
                        ),
                      ),
                      if (_mostrarTablaCuotas)
                        _buildTablaCuotas(resumen.cuotas),
                    ],
                  ],
                ),
                AppSection(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'CANCELAR',
                            onPressed: _guardando ? null : _accionVolver,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: AppButton(
                            text: 'CONFIRMAR CRÉDITO',
                            onPressed: _guardando ? null : _confirmar,
                            isLoading: _guardando,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectorEtiqueta(String texto) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s, bottom: AppSpacing.xs),
      child: Text(
        texto,
        style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildFilaSoloLectura(String etiqueta, String valor, {bool destacado = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: AppTypography.labelMedium),
          Text(
            valor,
            style: destacado
                ? AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  )
                : AppTypography.labelMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildFilaResumen(String etiqueta, String valor, {bool destacado = false, Color? colorTexto}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            etiqueta,
            style: destacado
                ? AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorTexto,
                  )
                : AppTypography.labelMedium.copyWith(color: colorTexto),
          ),
          Text(
            valor,
            textAlign: TextAlign.right,
            style: destacado
                ? AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorTexto,
                  )
                : AppTypography.labelMedium.copyWith(color: colorTexto),
          ),
        ],
      ),
    );
  }

  Widget _buildTablaCuotas(List<Cuota> cuotas) {
    return AppCard(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.allS,
        child: DataTable(
          columnSpacing: AppSpacing.m,
          headingRowHeight: 40,
          dataRowMaxHeight: 48,
          columns: const [
            DataColumn(label: Text('Cuota', style: AppTypography.labelMedium)),
            DataColumn(label: Text('Vencimiento', style: AppTypography.labelMedium)),
            DataColumn(label: Text('Capital', style: AppTypography.labelMedium), numeric: true),
            DataColumn(label: Text('Interés', style: AppTypography.labelMedium), numeric: true),
            DataColumn(label: Text('Total', style: AppTypography.labelMedium), numeric: true),
            DataColumn(label: Text('Saldo', style: AppTypography.labelMedium), numeric: true),
          ],
          rows: cuotas.map((c) {
            return DataRow(cells: [
              DataCell(Text('#${c.numeroCuota}', style: AppTypography.labelMedium)),
              DataCell(Text(_formatoFecha.format(c.fechaVencimiento), style: AppTypography.labelMedium)),
              DataCell(Text(_formatoMonto.format(c.montoCapital), style: AppTypography.labelMedium)),
              DataCell(Text(_formatoMonto.format(c.montoInteres), style: AppTypography.labelMedium)),
              DataCell(Text(_formatoMonto.format(c.montoTotal), style: AppTypography.labelMedium)),
              DataCell(Text(_formatoMonto.format(c.saldoDespues), style: AppTypography.labelMedium)),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
