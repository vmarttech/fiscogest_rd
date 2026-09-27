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

  static final _fmt = NumberFormat('#,##0.00', 'es_DO');
  static final _fmtFecha = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de cuenta'),
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
                  : _buildBody(c),
      bottomNavigationBar: (!_cargando &&
              c != null &&
              !c.estaPagada &&
              _error == null)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: ElevatedButton.icon(
                  onPressed: _pagando ? null : _dialogoRegistrarPago,
                  icon: const Icon(Icons.payments_outlined),
                  label: Text(
                    _pagando ? 'Registrando…' : 'Registrar pago / cuota',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody(CuentaPorCobrar c) {
    return ListView(
      padding: AppLayout.pantallaPadding,
      children: [
        Text(
          c.numero ?? 'CXC-${c.id}',
          style: AppTypography.h4.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          c.clienteNombre ?? 'Cliente #${c.clienteId}',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        AppLayout.vM,
        AppCard(
          borderColor: AppColors.border,
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              _fila('Estado', c.estado.nombre.toUpperCase()),
              _fila('Total original', 'RD\$ ${_fmt.format(c.totalOriginal)}'),
              _fila(
                'Abonado',
                'RD\$ ${_fmt.format(c.totalAbonado > 0 ? c.totalAbonado : c.abonoInicial)}',
              ),
              _fila(
                'Saldo pendiente',
                'RD\$ ${_fmt.format(c.saldoPendiente)}',
                bold: true,
              ),
              _fila('Vence', _fmtFecha.format(c.fechaVencimiento)),
              if (c.ventaId != null) _fila('Venta', '#${c.ventaId}'),
            ],
          ),
        ),
        if (_lineas.isNotEmpty) ...[
          AppLayout.vM,
          const Text('Qué compró', style: AppTypography.labelMedium),
          AppLayout.vS,
          AppCard(
            borderColor: AppColors.border,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                for (final l in _lineas)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${l.nombre} × ${l.cantidad}',
                            style: AppTypography.bodySmall,
                          ),
                        ),
                        Text(
                          'RD\$ ${_fmt.format(l.total)}',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (c.planPago != null && c.planPago!.cuotas.isNotEmpty) ...[
          AppLayout.vM,
          const Text('Plan de cuotas', style: AppTypography.labelMedium),
          AppLayout.vS,
          AppCard(
            borderColor: AppColors.border,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                for (final q in c.planPago!.cuotas)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Cuota ${q.numeroCuota} · ${_fmtFecha.format(q.fechaVencimiento)}',
                            style: AppTypography.bodySmall,
                          ),
                        ),
                        Text(
                          'RD\$ ${_fmt.format(q.montoTotal)}',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          q.pagada ? 'PAGADA' : 'PENDIENTE',
                          style: AppTypography.bodySmall.copyWith(
                            color: q.pagada
                                ? AppColors.success
                                : AppColors.warning,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        AppLayout.vM,
        const Text('Pagos realizados', style: AppTypography.labelMedium),
        AppLayout.vS,
        if (c.abonos.isEmpty)
          Text(
            'Aún no hay abonos registrados',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          )
        else
          ...c.abonos.map(
            (a) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(_fmtFecha.format(a.fecha)),
              subtitle: Text(a.metodoPago),
              trailing: Text(
                'RD\$ ${_fmt.format(a.monto)}',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _fila(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
