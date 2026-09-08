import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/abono_credito.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/cuenta_por_cobrar.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/cuota.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/estado_credito.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/plan_pago.dart';
import 'package:fiscogest_rd/features/creditos/domain/services/calculadora_credito_service.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_provider.dart';

/// Resultado devuelto por el formulario al confirmar
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

/// Formulario de condiciones del fiao / crédito
/// Se abre al elegir "Crédito" como forma de pago en la venta
/// Muestra vista previa de cuotas SIN revelar la tasa de interés
class FormularioCreditoDialog extends ConsumerStatefulWidget {
  const FormularioCreditoDialog({
    super.key,
    required this.estadoVenta,
  });

  final RegistrarVentaState estadoVenta;

  static Future<ResultadoFormularioCredito?> mostrar({
    required BuildContext context,
    required RegistrarVentaState estadoVenta,
  }) async {
    return showDialog<ResultadoFormularioCredito>(
      context: context,
      barrierDismissible: false,
      builder: (context) => FormularioCreditoDialog(estadoVenta: estadoVenta),
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

  // Opciones predefinidas según uso comercial dominicano
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

  // ============================================
  // VALORES CALCULADOS EN TIEMPO REAL
  // ============================================

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

  // ============================================
  // ACCIONES
  // ============================================

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaPrimerVencimiento,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'DO'),
    );
    if (fecha != null) {
      setState(() => _fechaPrimerVencimiento = fecha);
    }
  }

  Future<void> _confirmar() async {
    if (_saldoFinanciado <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El saldo financiado debe ser mayor a RD\$ 0.00'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final resumen = _resumen;
      final ahora = DateTime.now();
      final fechaVencimientoFinal = _numeroCuotas <= 1
          ? _fechaPrimerVencimiento
          : _fechaPrimerVencimiento.add(Duration(days: 30 * (_numeroCuotas - 1)));

      // Construir plan de pagos si hay más de 1 cuota
      PlanPago? planPago;
      if (_numeroCuotas > 1) {
        planPago = CalculadoraCreditoService.generarPlanPago(
          capital: _saldoFinanciado,
          tasaMensual: _tasaMensual,
          numeroCuotas: _numeroCuotas,
          fechaPrimerVencimiento: _fechaPrimerVencimiento,
        );
      }

      // Construir cuenta por cobrar
      final cuenta = CuentaPorCobrar(
        clienteId: widget.estadoVenta.clienteId ?? 0,
        clienteNombre: widget.estadoVenta.clienteNombre,
        ventaId: null, // se actualizará después de registrar la venta
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

      // Construir abono inicial si existe
      AbonoCredito? abonoInicial;
      if (_abonoInicial > 0.001) {
        abonoInicial = AbonoCredito(
          cuentaId: 0, // se actualizará después
          monto: _abonoInicial,
          metodoPago: widget.estadoVenta.tipoPago,
          fecha: ahora,
          usuarioId: widget.estadoVenta.usuarioId,
        );
      }

      if (!mounted) return;
      Navigator.pop(
        context,
        ResultadoFormularioCredito(
          cuenta: cuenta,
          planPago: planPago,
          abonoInicial: abonoInicial,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // ============================================
  // BUILD
  // ============================================

  @override
  Widget build(BuildContext context) {
    final resumen = _resumen;
    final esPantallaPequena = MediaQuery.of(context).size.width < 600;

    return AlertDialog(
      title: const Text('CONDICIONES DEL CRÉDITO / FIAO'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: esPantallaPequena ? double.maxFinite : 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // =====================
              // DATOS DE LA VENTA
              // =====================
              _buildSeccionTitulo('Datos de la venta'),
              const SizedBox(height: AppSpacing.s),
              _buildFilaSoloLectura(
                'Cliente:',
                widget.estadoVenta.clienteNombre ?? 'Consumidor Final',
              ),
              _buildFilaSoloLectura(
                'Total de venta:',
                _formatoMonto.format(_totalVenta),
                destacado: true,
              ),
              const SizedBox(height: AppSpacing.m),
              const Divider(),
              const SizedBox(height: AppSpacing.m),

              // =====================
              // CONDICIONES
              // =====================
              _buildSeccionTitulo('Condiciones del crédito'),
              const SizedBox(height: AppSpacing.s),

              // Abono inicial
              TextFormField(
                controller: _abonoInicialController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Abono inicial (RD\$)',
                  border: OutlineInputBorder(),
                  hintText: '0.00',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.s),

              // Plazo
              _buildSelectorEtiqueta('Plazo:'),
              Wrap(
                spacing: 8,
                children: _opcionesPlazo.map((meses) {
                  final activo = _plazoMeses == meses;
                  return ChoiceChip(
                    label: Text('$meses ${meses == 1 ? 'mes' : 'meses'}'),
                    selected: activo,
                    onSelected: (_) {
                      setState(() {
                        _plazoMeses = meses;
                        if (_numeroCuotas > meses) _numeroCuotas = meses;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.s),

              // Número de cuotas
              _buildSelectorEtiqueta('Número de cuotas:'),
              Wrap(
                spacing: 8,
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
              const SizedBox(height: AppSpacing.s),

              // Fecha primer vencimiento
              InkWell(
                onTap: _seleccionarFecha,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha primer vencimiento',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(_formatoFecha.format(_fechaPrimerVencimiento)),
                ),
              ),
              const SizedBox(height: AppSpacing.s),

              // Tasa de interés (SOLO PARA USUARIO INTERNO, NO PARA CLIENTE)
              _buildSelectorEtiqueta('Tasa mensual (uso interno):'),
              Wrap(
                spacing: 8,
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
              const SizedBox(height: AppSpacing.s),

              // Observaciones
              TextField(
                controller: _observacionesController,
                decoration: const InputDecoration(
                  labelText: 'Observaciones (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.m),
              const Divider(),
              const SizedBox(height: AppSpacing.m),

              // =====================
              // RESUMEN PARA CLIENTE
              // =====================
              _buildSeccionTitulo('Resumen para el cliente'),
              const SizedBox(height: AppSpacing.s),
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
                  'Incremento por tiempo:',
                  '+ ${_formatoMonto.format(resumen.montoInteres)}',
                  colorTexto: Colors.red.shade700,
                ),
              _buildFilaResumen(
                'TOTAL A PAGAR:',
                _formatoMonto.format(resumen.totalAPagar),
                destacado: true,
                colorTexto: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.s),
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

              // Tabla de cuotas (expandible)
              if (resumen.cuotas.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s),
                TextButton.icon(
                  onPressed: () => setState(
                      () => _mostrarTablaCuotas = !_mostrarTablaCuotas),
                  icon: Icon(_mostrarTablaCuotas
                      ? Icons.expand_less
                      : Icons.expand_more),
                  label: Text(_mostrarTablaCuotas
                      ? 'Ocultar tabla de cuotas'
                      : 'Ver tabla completa de cuotas'),
                ),
                if (_mostrarTablaCuotas) _buildTablaCuotas(resumen.cuotas),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: _guardando ? null : _confirmar,
          child: _guardando
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('CONFIRMAR CRÉDITO'),
        ),
      ],
    );
  }

  // ============================================
  // WIDGETS AUXILIARES
  // ============================================

  Widget _buildSeccionTitulo(String texto) {
    return Text(
      texto,
      style: AppTypography.labelLarge.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildSelectorEtiqueta(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        texto,
        style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildFilaSoloLectura(String etiqueta, String valor,
      {bool destacado = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: AppTypography.labelMedium),
          Text(
            valor,
            style: destacado
                ? AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.bold, color: AppColors.primary)
                : AppTypography.labelMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildFilaResumen(String etiqueta, String valor,
      {bool destacado = false, Color? colorTexto}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            etiqueta,
            style: destacado
                ? AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.bold, color: colorTexto)
                : AppTypography.labelMedium.copyWith(color: colorTexto),
          ),
          Text(
            valor,
            textAlign: TextAlign.right,
            style: destacado
                ? AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.bold, color: colorTexto)
                : AppTypography.labelMedium.copyWith(color: colorTexto),
          ),
        ],
      ),
    );
  }

  Widget _buildTablaCuotas(List<Cuota> cuotas) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          headingRowHeight: 40,
          dataRowMaxHeight: 48,
          columns: const [
            DataColumn(label: Text('Cuota')),
            DataColumn(label: Text('Vencimiento')),
            DataColumn(label: Text('Capital'), numeric: true),
            DataColumn(label: Text('Interés'), numeric: true),
            DataColumn(label: Text('Total'), numeric: true),
            DataColumn(label: Text('Saldo'), numeric: true),
          ],
          rows: cuotas.map((c) {
            return DataRow(cells: [
              DataCell(Text('#${c.numeroCuota}')),
              DataCell(Text(_formatoFecha.format(c.fechaVencimiento))),
              DataCell(Text(_formatoMonto.format(c.montoCapital))),
              DataCell(Text(_formatoMonto.format(c.montoInteres))),
              DataCell(Text(_formatoMonto.format(c.montoTotal))),
              DataCell(Text(_formatoMonto.format(c.saldoDespues))),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
