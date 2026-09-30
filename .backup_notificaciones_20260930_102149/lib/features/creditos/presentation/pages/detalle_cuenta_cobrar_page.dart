import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/clientes/domain/interfaces/i_cliente_repository.dart';
import 'package:fiscogest_rd/features/clientes/presentation/providers/cliente_providers.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/abono_credito.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/cuenta_por_cobrar.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/cuota.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/estado_credito.dart';
import 'package:fiscogest_rd/features/creditos/presentation/pages/cuentas_cobrar_page.dart'
    show cuentasCobrarListaProvider, creditoTotalesProvider;
import 'package:fiscogest_rd/features/creditos/presentation/providers/credito_providers.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart'
    as venta_providers;
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart'
    show cajaRepositoryProvider;

class DetalleCuentaCobrarPage extends ConsumerStatefulWidget {
  const DetalleCuentaCobrarPage({super.key, required this.cuentaId});

  static const String routeName = 'credito-cuenta-detalle';
  static const String path = '/creditos/cuentas/:id';

  final int cuentaId;

  @override
  ConsumerState<DetalleCuentaCobrarPage> createState() =>
      _DetalleCuentaCobrarPageState();
}

class _DetalleCuentaCobrarPageState
    extends ConsumerState<DetalleCuentaCobrarPage> {
  CuentaPorCobrar? _cuenta;
  final List<({String nombre, int cantidad, double total})> _lineas = [];
  bool _cargando = true;
  String? _error;
  bool _pagando = false;
  bool _imprimiendoCronograma = false;

  static final _fmt = NumberFormat('#,##0.00', 'es_DO');
  static final _fmtFecha = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }


  Future<void> _imprimirCronograma(CuentaPorCobrar c) async {
    if (c.planPago == null || c.planPago!.cuotas.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cuotas para imprimir')),
      );
      return;
    }
    setState(() => _imprimiendoCronograma = true);
    try {
      final svc = await ref.read(creditoDocumentoServiceProvider.future);
      await svc.imprimirCronograma(cuenta: c);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al imprimir: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _imprimiendoCronograma = false);
    }
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
      _lineas.clear();
    });
    try {
      final repo = ref.read(cuentaPorCobrarRepositoryProvider);
      final CuentaPorCobrar? c = await repo.obtenerPorId(widget.cuentaId);
      if (c == null) {
        setState(() {
          _error = 'Cuenta no encontrada';
          _cargando = false;
        });
        return;
      }
      // Local no-nullable: copyWith no degrada el tipo
      CuentaPorCobrar cuenta = c;
      if (cuenta.clienteNombre == null || cuenta.clienteNombre!.isEmpty) {
        try {
          final IClienteRepository cliRepo =
              ref.read(clienteRepositoryProvider);
          final cli = await cliRepo.obtenerClientePorId(cuenta.clienteId);
          if (cli != null) {
            cuenta = cuenta.copyWith(clienteNombre: cli.nombre);
          }
        } catch (_) {}
      }
      final int? ventaId = cuenta.ventaId;
      if (ventaId != null && ventaId > 0) {
        try {
          final IVentasRepository vRepo =
              ref.read(venta_providers.ventasRepositoryProvider);
          final venta = await vRepo.obtenerVentaPorId(ventaId);
          if (venta != null) {
            for (final d in venta.detalles) {
              final total = d.subtotal > 0 ? d.subtotal : (d.cantidad * d.precioUnitario);
              _lineas.add((
                nombre: (d.nombreProducto != null && d.nombreProducto!.trim().isNotEmpty)
                  ? d.nombreProducto!.trim()
                  : 'Producto #${d.productoId}',
                cantidad: d.cantidad,
                total: total,
              ));
            }
          }
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _cuenta = cuenta;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _cargando = false;
      });
    }
  }



  Future<void> _dialogoRegistrarPago() async {
    final c = _cuenta;
    if (c == null || c.id == null) return;
    final plan = c.planPago;
    final pendientes =
        plan?.cuotas.where((q) => !q.pagada).toList() ?? <Cuota>[];
    final nCuotas = pendientes.isNotEmpty
        ? pendientes.length
        : (c.numeroCuotas > 1 ? c.numeroCuotas : 1);
    final aPagar = pendientes.isNotEmpty
        ? pendientes.first.montoTotal.clamp(0.01, c.saldoPendiente)
        : (nCuotas > 1
            ? c.saldoPendiente / nCuotas
            : c.saldoPendiente);
    final controller = TextEditingController(
      text: aPagar.toStringAsFixed(2),
    );
    final notaController = TextEditingController();
    var metodo = 'efectivo';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: AppRadius.allL),
              title: const Text('Registrar pago', style: AppTypography.h4),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Saldo pendiente: RD\$ ${_fmt.format(c.saldoPendiente)}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AppLayout.vS,
                    Text(
                      pendientes.isNotEmpty
                          ? 'Próxima cuota #${pendientes.first.numeroCuota}: RD\$ ${_fmt.format(aPagar)}'
                          : 'Monto sugerido: RD\$ ${_fmt.format(aPagar)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AppLayout.vM,
                    TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Monto a pagar',
                        prefixText: 'RD\$ ',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                    ),
                    AppLayout.vM,
                    DropdownButtonFormField<String>(
                      initialValue: metodo,
                      decoration: const InputDecoration(
                        labelText: 'Forma de pago',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'efectivo',
                          child: Text('Efectivo'),
                        ),
                        DropdownMenuItem(
                          value: 'transferencia',
                          child: Text('Transferencia'),
                        ),
                        DropdownMenuItem(
                          value: 'tarjeta',
                          child: Text('Tarjeta'),
                        ),
                        DropdownMenuItem(
                          value: 'otro',
                          child: Text('Otro'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setLocal(() => metodo = v);
                      },
                    ),
                    AppLayout.vM,
                    TextField(
                      controller: notaController,
                      decoration: const InputDecoration(
                        labelText: 'Nota (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final raw = controller.text
                        .trim()
                        .replaceAll(' ', '')
                        .replaceAll(',', '.');
                    final v = double.tryParse(raw);
                    if (v == null || v <= 0) return;
                    if (v > c.saldoPendiente + 0.05) return;
                    Navigator.pop(ctx, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('Registrar'),
                ),
              ],
            );
          },
        );
      },
    );

    final raw =
        controller.text.trim().replaceAll(' ', '').replaceAll(',', '.');
    final monto = double.tryParse(raw) ?? 0;
    final nota = notaController.text.trim();
    controller.dispose();
    notaController.dispose();
    if (confirmed != true || !mounted || monto <= 0) return;

    setState(() => _pagando = true);
    try {
      final notaAuto = nota.isEmpty
          ? (pendientes.isNotEmpty
              ? 'Cuota #${pendientes.first.numeroCuota}'
                  '${c.ventaId != null ? ' · Venta #${c.ventaId}' : ''}'
              : (c.ventaId != null ? 'Venta #${c.ventaId}' : null))
          : nota;
      await ref.read(cuentaPorCobrarRepositoryProvider).registrarAbono(
            AbonoCredito(
              cuentaId: c.id!,
              monto: monto,
              metodoPago: metodo,
              fecha: DateTime.now(),
              nota: notaAuto,
            ),
          );
      try {
        await ref.read(cajaRepositoryProvider).registrarMovimiento(
              referencia: c.numero ?? 'CXC-${c.id}',
              monto: monto,
              tipo: 'ingreso',
              descripcion:
                  'Abono ${c.numero ?? c.id} · ${c.clienteNombre ?? ''}',
              formaPago: metodo,
            );
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pago registrado: RD\$ ${_fmt.format(monto)}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      ref.invalidate(cuentasCobrarListaProvider);
      ref.invalidate(creditoTotalesProvider);
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'.replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _pagando = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final c = _cuenta;
    return AppScaffold(
      title: 'DETALLE DE CUENTA',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/creditos/cuentas');
          }
        },
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: AppLayout.pantallaPadding,
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                )
              : c == null
                  ? const Center(child: Text('Cuenta no encontrada'))
                  : Column(
                      children: [
                        Expanded(child: _buildBody(c)),
                        if (!c.estaPagada)
                          SafeArea(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 12),
                              child: SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _pagando
                                      ? null
                                      : _dialogoRegistrarPago,
                                  icon:
                                      const Icon(Icons.payments_outlined),
                                  label: Text(
                                    _pagando
                                        ? 'Registrando…'
                                        : 'Registrar pago / cuota',
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                    minimumSize:
                                        const Size.fromHeight(52),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
    );
  }


  Widget _buildBody(CuentaPorCobrar c) {
    final desktop = AppBreakpoints.isDesktop(context);
    final mobile = AppBreakpoints.isMobile(context);

    return Align(
      alignment: Alignment.topCenter,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          mobile ? 16 : 20,
          mobile ? 12 : 16,
          mobile ? 16 : 20,
          24,
        ),
        children: [
          AppLayout.centerConstrained(
            maxWidth: desktop ? 720 : 560,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabecera
                AppCard(
                  borderColor: AppColors.border,
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.numero ?? 'CXC-${c.id}',
                              style: AppTypography.h4.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              c.clienteNombre ?? 'Cliente #${c.clienteId}',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.grey700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          c.estado.nombre.toUpperCase(),
                          style: AppTypography.labelSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Resumen importes
                AppCard(
                  borderColor: AppColors.border,
                  child: Column(
                    children: [
                      _fila('Total original',
                          'RD\$ ${_fmt.format(c.totalOriginal)}'),
                      const Divider(height: 16, color: AppColors.border),
                      _fila(
                        'Abonado',
                        'RD\$ ${_fmt.format(c.totalAbonado > 0 ? c.totalAbonado : c.abonoInicial)}',
                      ),
                      const Divider(height: 16, color: AppColors.border),
                      _fila(
                        'Saldo pendiente',
                        'RD\$ ${_fmt.format(c.saldoPendiente)}',
                        bold: true,
                        valueColor: AppColors.primary,
                      ),
                      const Divider(height: 16, color: AppColors.border),
                      _fila(
                        'Vence',
                        _fmtFecha.format(c.fechaVencimiento),
                      ),
                      if (c.ventaId != null) ...[
                        const Divider(height: 16, color: AppColors.border),
                        _fila('Venta', '#${c.ventaId}'),
                      ],
                    ],
                  ),
                ),
                if (_lineas.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Qué compró',
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    borderColor: AppColors.border,
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < _lineas.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 1, color: AppColors.border),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${_lineas[i].nombre} × ${_lineas[i].cantidad}',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  'RD\$ ${_fmt.format(_lineas[i].total)}',
                                  style: AppTypography.labelMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (c.planPago != null &&
                    c.planPago!.cuotas.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Plan de cuotas',
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _imprimiendoCronograma
                            ? null
                            : () => _imprimirCronograma(c),
                        icon: _imprimiendoCronograma
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.print_outlined, size: 18),
                        label: const Text('Imprimir'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    borderColor: AppColors.border,
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0;
                            i < c.planPago!.cuotas.length;
                            i++) ...[
                          if (i > 0)
                            const Divider(height: 1, color: AppColors.border),
                          Builder(
                            builder: (_) {
                              final q = c.planPago!.cuotas[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Cuota ${q.numeroCuota} · ${_fmtFecha.format(q.fechaVencimiento)}',
                                        style:
                                            AppTypography.bodyMedium.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'RD\$ ${_fmt.format(q.montoTotal)}',
                                      style:
                                          AppTypography.labelMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      q.pagada ? 'PAGADA' : 'PENDIENTE',
                                      style:
                                          AppTypography.labelSmall.copyWith(
                                        color: q.pagada
                                            ? AppColors.success
                                            : AppColors.warning,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Pagos realizados',
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                AppCard(
                  borderColor: AppColors.border,
                  padding: EdgeInsets.zero,
                  child: c.abonos.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Aún no hay abonos registrados',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.grey600,
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            for (var i = 0; i < c.abonos.length; i++) ...[
                              if (i > 0)
                                const Divider(
                                  height: 1,
                                  color: AppColors.border,
                                ),
                              ListTile(
                                dense: true,
                                title: Text(
                                  _fmtFecha.format(c.abonos[i].fecha),
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  c.abonos[i].metodoPago,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.grey600,
                                  ),
                                ),
                                trailing: Text(
                                  'RD\$ ${_fmt.format(c.abonos[i].monto)}',
                                  style: AppTypography.labelLarge.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _fila(
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.grey600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
