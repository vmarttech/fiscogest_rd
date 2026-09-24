import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/creditos/presentation/providers/credito_providers.dart';
import 'package:intl/intl.dart';
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

class FormularioCreditoVista extends ConsumerStatefulWidget {
  const FormularioCreditoVista({
    super.key,
    required this.estadoVenta,
    required this.onVolver,
    required this.onConfirmado,
  });
  final RegistrarVentaState estadoVenta;
  final VoidCallback onVolver;
  final void Function(ResultadoFormularioCredito) onConfirmado;

  @override
  ConsumerState<FormularioCreditoVista> createState() =>
      _FormularioCreditoVistaState();
}

class _FormularioCreditoVistaState
    extends ConsumerState<FormularioCreditoVista> {
  // ✅ Reemplazado NumberFormat.currency por formateador sin símbolo
  static final NumberFormat _formatoNumero = NumberFormat('#,##0.00', 'es_DO');
  String _formatearMonto(double valor) => 'RD\$${_formatoNumero.format(valor)}';

  static final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy');
  late final TextEditingController _abonoInicialController;
  late final TextEditingController _tasaInteresController;
  late final TextEditingController _observacionesController;
  int _plazoMeses = 1;
  int _numeroCuotas = 1;
  late DateTime _fechaPrimerVencimiento;
  bool _mostrarTablaCuotas = false;
  bool _guardando = false;
  bool _paramsAplicados = false;
  List<int> _opcionesPlazo = const [1, 2, 3, 6];
  List<int> _opcionesCuotas = const [1, 2, 3, 6];
  @override
  void initState() {
    super.initState();
    _abonoInicialController = TextEditingController(text: '0');
    _tasaInteresController = TextEditingController(text: '0');
    _observacionesController = TextEditingController();
    _fechaPrimerVencimiento = DateTime.now().add(const Duration(days: 30));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _aplicarParametrosConfig();
    });
  }

  Future<void> _aplicarParametrosConfig() async {
    if (_paramsAplicados || !mounted) return;
    try {
      final p = await ref.read(parametrosCreditoProvider.future);
      if (!mounted) return;
      final plazoMax = p.plazoMaxMeses < 1 ? 24 : p.plazoMaxMeses;
      const base = [1, 2, 3, 6, 9, 12, 18, 24, 36];
      final plazos = base.where((m) => m <= plazoMax).toList();
      if (plazos.isEmpty) {
        plazos.add(plazoMax);
      } else if (plazoMax > plazos.last && !plazos.contains(plazoMax)) {
        plazos.add(plazoMax);
      }
      var cuotasDef = p.cuotasDefault;
      if (cuotasDef < 1) cuotasDef = 1;
      if (cuotasDef > plazoMax) cuotasDef = plazoMax;
      final gracia = p.diasGracia < 0 ? 0 : p.diasGracia;
      setState(() {
        _opcionesPlazo = plazos;
        _opcionesCuotas = List<int>.from(plazos);
        _plazoMeses = cuotasDef;
        _numeroCuotas = cuotasDef;
        _tasaInteresController.text = p.tasaMensualDefault.toString();
        _fechaPrimerVencimiento = DateTime.now().add(
          Duration(days: gracia > 0 ? gracia : 30),
        );
        _paramsAplicados = true;
      });
    } catch (_) {
      _paramsAplicados = true;
    }
  }


  @override
  void dispose() {
    _abonoInicialController.dispose();
    _tasaInteresController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  double get _totalVenta => widget.estadoVenta.total;
  double get _abonoInicial =>
      (double.tryParse(_abonoInicialController.text) ?? 0.0).clamp(
        0.0,
        _totalVenta,
      );
  double get _saldoFinanciado =>
      (_totalVenta - _abonoInicial).clamp(0.0, double.infinity);
  double get _tasaMensual =>
      double.tryParse(_tasaInteresController.text) ?? 0.0;

  ResumenCreditoCliente get _resumen =>
      CalculadoraCreditoService.generarResumenCliente(
        totalVenta: _totalVenta,
        abonoInicial: _abonoInicial,
        tasaMensual: _tasaMensual,
        numeroCuotas: _numeroCuotas,
        fechaPrimerVencimiento: _fechaPrimerVencimiento,
      );

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
          : _fechaPrimerVencimiento.add(
              Duration(days: 30 * (_numeroCuotas - 1)),
            );
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
      if (!mounted) return;
      widget.onConfirmado(
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
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Widget _buildSelectorEtiqueta(String texto) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s, bottom: AppSpacing.xs),
      child: Text(
        texto,
        style: AppTypography.labelMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildFilaDato(
    String etiqueta,
    String valor, {
    bool destacado = false,
    Color? colorTexto,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              etiqueta,
              style: AppTypography.labelMedium.copyWith(
                color: colorTexto ?? AppColors.textSecondary,
                fontWeight: destacado ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: destacado
                  ? AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorTexto ?? AppColors.primary,
                    )
                  : AppTypography.labelMedium.copyWith(
                      color: colorTexto ?? AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorOpciones<T>(
    List<T> opciones,
    T valorActual,
    String Function(T) etiqueta,
    ValueChanged<T> alSeleccionar,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: opciones.map((opcion) {
        final activo = valorActual == opcion;
        return ChoiceChip(
          label: Text(
            etiqueta(opcion),
            style: AppTypography.labelMedium.copyWith(
              fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
              color: activo ? colorScheme.onPrimary : AppColors.textPrimary,
            ),
          ),
          selected: activo,
          onSelected: (_) => alSeleccionar(opcion),
          showCheckmark: false,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s,
            vertical: AppSpacing.xs,
          ),
          backgroundColor: colorScheme.surface,
          selectedColor: AppColors.primary,
          side: BorderSide(
            color: activo
                ? AppColors.primary
                : colorScheme.outline.withValues(alpha: 0.35),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCampoFecha() {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: _seleccionarFecha,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Primer vencimiento',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.45),
            ),
          ),
          suffixIcon: const Icon(
            Icons.calendar_today_outlined,
            color: AppColors.primary,
          ),
        ),
        child: Text(
          _formatoFecha.format(_fechaPrimerVencimiento),
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTablaCuotas(List<Cuota> cuotas) {
    return AppCard(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(AppSpacing.m),
        child: DataTable(
          columnSpacing: AppSpacing.m,
          horizontalMargin: AppSpacing.s,
          headingRowHeight: 44,
          dataRowMinHeight: 44,
          dataRowMaxHeight: 52,
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('Vencimiento')),
            DataColumn(label: Text('Capital'), numeric: true),
            DataColumn(label: Text('Interés'), numeric: true),
            DataColumn(label: Text('Total'), numeric: true),
            DataColumn(label: Text('Saldo'), numeric: true),
          ],
          rows: cuotas.map((c) {
            return DataRow(
              cells: [
                DataCell(
                  Text('#${c.numeroCuota}', style: AppTypography.labelMedium),
                ),
                DataCell(
                  Text(
                    _formatoFecha.format(c.fechaVencimiento),
                    style: AppTypography.labelMedium,
                  ),
                ),
                DataCell(
                  Text(
                    _formatearMonto(c.montoCapital), // ✅
                    style: AppTypography.labelMedium,
                  ),
                ),
                DataCell(
                  Text(
                    _formatearMonto(c.montoInteres), // ✅
                    style: AppTypography.labelMedium,
                  ),
                ),
                DataCell(
                  Text(
                    _formatearMonto(c.montoTotal), // ✅
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    _formatearMonto(c.saldoDespues), // ✅
                    style: AppTypography.labelMedium,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildResumenFinanciero(ResumenCreditoCliente resumen) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Resumen del financiamiento',
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          _buildFilaDato(
            'Total venta',
            _formatearMonto(resumen.totalVenta), // ✅
          ),
          _buildFilaDato(
            'Abono inicial',
            _formatearMonto(resumen.abonoInicial), // ✅
          ),
          _buildFilaDato(
            'Saldo financiado',
            _formatearMonto(resumen.saldoFinanciado), // ✅
            destacado: true,
          ),
          if (resumen.montoInteres > 0.001)
            _buildFilaDato(
              'Interés',
              '+ ${_formatearMonto(resumen.montoInteres)}', // ✅
              colorTexto: AppColors.error,
            ),
          const SizedBox(height: AppSpacing.xs),
          Divider(
            color: colorScheme.outline.withValues(alpha: 0.25),
            height: 1,
          ),
          const SizedBox(height: AppSpacing.s),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Total a pagar',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                flex: 2,
                child: Text(
                  _formatearMonto(resumen.totalAPagar), // ✅
                  textAlign: TextAlign.right,
                  softWrap: false,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.m,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.10),
              ),
            ),
            child: Column(
              children: [
                Text(
                  _formatearMonto(resumen.montoPorCuota), // ✅
                  textAlign: TextAlign.center,
                  softWrap: false,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  resumen.numeroCuotas == 1
                      ? 'Pago único'
                      : '${resumen.numeroCuotas} cuotas mensuales',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Primer vencimiento · '
                  '${_formatoFecha.format(resumen.fechaPrimerVencimiento)}',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatosVenta() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Datos de la venta',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        _buildFilaDato(
          'Cliente',
          widget.estadoVenta.clienteNombre ?? 'Consumidor Final',
        ),
        const SizedBox(height: AppSpacing.s),
        _buildFilaDato(
          'Total de venta',
          _formatearMonto(_totalVenta), // ✅
          destacado: true,
        ),
      ],
    );
  }

  Widget _buildCondicionesCredito() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Condiciones del crédito',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        AppTextField(
          controller: _abonoInicialController,
          keyboardType: TextInputType.number,
          label: 'Abono inicial (RD\$)',
          hint: '0.00',
          onChanged: (_) => setState(() {}),
        ),
        _buildSelectorEtiqueta('Plazo'),
        _buildSelectorOpciones<int>(
          _opcionesPlazo,
          _plazoMeses,
          (m) => '$m ${m == 1 ? 'mes' : 'meses'}',
          (m) => setState(() {
            _plazoMeses = m;
            if (_numeroCuotas > m) _numeroCuotas = m;
          }),
        ),
        _buildSelectorEtiqueta('Número de cuotas'),
        _buildSelectorOpciones<int>(
          _opcionesCuotas.where((c) => c <= _plazoMeses).toList(),
          _numeroCuotas,
          (c) => '$c ${c == 1 ? 'cuota' : 'cuotas'}',
          (c) => setState(() => _numeroCuotas = c),
        ),
        _buildSelectorEtiqueta('Primer vencimiento'),
        _buildCampoFecha(),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s),
          child: Text(
            'Tasa mensual (configuración): '
            '${(_tasaMensual * 100).toStringAsFixed(2)}%',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        AppTextField(
          controller: _observacionesController,
          label: 'Observaciones',
          hint: 'Agregar una nota sobre este crédito...',
        ),
      ],
    );
  }

  Widget _buildContenedorEstilizado(Widget child) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildContenidoPrincipal(ResumenCreditoCliente resumen) {
    final anchoPantalla = MediaQuery.of(context).size.width;
    final anchoDisponible = anchoPantalla - 280 - 32;
    final usarDosColumnas = anchoDisponible >= 580;

    final formulario = _buildContenedorEstilizado(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDatosVenta(),
          const SizedBox(height: AppSpacing.l),
          _buildCondicionesCredito(),
        ],
      ),
    );

    final resumenTarjeta = _buildContenedorEstilizado(
      _buildResumenFinanciero(resumen),
    );

    final tablaPies = resumen.cuotas.isNotEmpty
        ? Column(
            children: [
              const SizedBox(height: AppSpacing.l),
              Align(
                alignment: Alignment.center,
                child: TextButton.icon(
                  onPressed: () => setState(
                    () => _mostrarTablaCuotas = !_mostrarTablaCuotas,
                  ),
                  icon: Icon(
                    _mostrarTablaCuotas
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    _mostrarTablaCuotas
                        ? 'Ocultar tabla de cuotas'
                        : 'Ver tabla completa de cuotas',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (_mostrarTablaCuotas) ...[
                const SizedBox(height: AppSpacing.s),
                _buildTablaCuotas(resumen.cuotas),
              ],
            ],
          )
        : const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: !usarDosColumnas
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                formulario,
                const SizedBox(height: AppSpacing.m),
                resumenTarjeta,
                tablaPies,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: formulario),
                    const SizedBox(width: AppSpacing.l),
                    Expanded(flex: 2, child: resumenTarjeta),
                  ],
                ),
                tablaPies,
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resumen = _resumen;
    final maxW = AppBreakpoints.isDesktop(context)
        ? 1100
        : (AppBreakpoints.isTablet(context) ? 900 : 720);

    return AppLayout.centerConstrained(
      maxWidth: maxW,
      child: SingleChildScrollView(
        padding: AppLayout.pantallaPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crédito / Financiamiento',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Configure las condiciones de pago',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
            _buildContenidoPrincipal(resumen),
            const SizedBox(height: AppSpacing.l),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'CANCELAR',
                    onPressed: _guardando ? null : widget.onVolver,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: AppButton(
                    text: 'CONFIRMAR',
                    onPressed: _guardando ? null : _confirmar,
                    isLoading: _guardando,
                  ),
                ),
              ],
            ),
            // Respiro inferior (evita overflow bajo botones / teclado)
            const SizedBox(height: AppSpacing.l),
          ],
        ),
      ),
    );
  }
}
