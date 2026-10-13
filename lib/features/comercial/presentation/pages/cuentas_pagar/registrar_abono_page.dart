import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_action_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/cuenta_pagar.dart';
import 'package:fiscogest_rd/features/comercial/presentation/providers/cuentas_pagar_providers.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';

class RegistrarAbonoPage extends ConsumerStatefulWidget {
  const RegistrarAbonoPage({super.key, required this.cuentaId});
  static const String routeName = 'registrar-abono';
  final Object cuentaId;

  @override
  ConsumerState<RegistrarAbonoPage> createState() => _RegistrarAbonoPageState();
}

class _RegistrarAbonoPageState extends ConsumerState<RegistrarAbonoPage> {
  late final int _idNumerico;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late DateTime _fecha;
  final TextEditingController _montoCtrl = TextEditingController();
  String _formaPago = 'efectivo';
  final TextEditingController _referenciaCtrl = TextEditingController();
  final TextEditingController _notaCtrl = TextEditingController();
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _idNumerico = switch (widget.cuentaId) {
      final int id => id,
      final String idStr => int.tryParse(idStr) ?? 0,
      _ => 0,
    };
    _fecha = DateTime.now();
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _referenciaCtrl.dispose();
    _notaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final double? monto = double.tryParse(_montoCtrl.text.replaceAll(',', '.'));
    if (monto == null || monto <= 0) return;

    setState(() => _cargando = true);

    try {
      final registrar = ref.read(registrarAbonoProvider);
      final ok = await registrar(
        cuentaPagarId: _idNumerico,
        monto: monto,
        fechaPago: _fecha,
        formaPago: _formaPago,
        referencia: _referenciaCtrl.text.trim(),
        nota: _notaCtrl.text.trim().isNotEmpty ? _notaCtrl.text.trim() : null,
      );

      if (!mounted) return;
      setState(() => _cargando = false);

      if (ok) {
        if (!mounted) return;
        FiscoGestNotifications.show(
          const SnackBar(
            content: Text('Abono registrado ✅'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else {
        if (!mounted) return;
        FiscoGestNotifications.show(
          const SnackBar(
            content: Text('No se pudo registrar el abono. ¿Caja abierta?'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      FiscoGestNotifications.show(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<CuentaPagar?> cuentaAsync = ref.watch(
      cuentaPagarPorIdProvider(_idNumerico),
    );

    return AppScaffold(
      title: 'Registrar Abono',
      body: SafeArea(
        bottom: true,
        child: cuentaAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace? _) => Center(
            child: Padding(
              padding: AppLayout.pantallaPadding,
              child: Text(
                'Error: $error',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ),
          data: (CuentaPagar? cuenta) {
            if (cuenta == null) {
              return const Center(child: Text('Cuenta no encontrada'));
            }
            final double saldoPendiente = cuenta.saldoPendiente;

            if (saldoPendiente <= 0) {
              return Center(
                child: Padding(
                  padding: AppLayout.pantallaPadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 48,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Esta cuenta ya está pagada.',
                        style: AppTypography.h4Bold,
                      ),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Volver'),
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: AppLayout.pantallaPadding,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      child: Padding(
                        padding: AppSpacing.allM,
                        child: Column(
                          children: [
                            Text(
                              cuenta.nombreProveedor,
                              style: AppTypography.h4Bold,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Saldo pendiente a la fecha:',
                              style: AppTypography.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatRd(saldoPendiente),
                              style: AppTypography.h4Bold.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Fecha',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      initialValue: _fecha.toString().split(' ')[0],
                      readOnly: true,
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _fecha,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) setState(() => _fecha = picked);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _montoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Monto del Abono',
                        prefixText: 'RD\$ ',
                      ),
                      validator: (String? value) {
                        final double? v = double.tryParse(
                          value?.replaceAll(',', '.') ?? '',
                        );
                        if (v == null || v <= 0) {
                          return 'Ingrese un monto válido';
                        }
                        if (v > saldoPendiente) {
                          return 'Excede saldo pendiente (${formatRdNumero(saldoPendiente)}  )';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _formaPago,
                      decoration: const InputDecoration(
                        labelText: 'Forma de Pago',
                      ),
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'efectivo',
                          child: Text('Efectivo'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'transferencia',
                          child: Text('Transferencia'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'cheque',
                          child: Text('Cheque'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'tarjeta',
                          child: Text('Tarjeta'),
                        ),
                      ],
                      onChanged: (String? v) =>
                          setState(() => _formaPago = v ?? 'efectivo'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _referenciaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Referencia / Nº Comprobante',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nota (opcional)',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    AppActionBar(
                      actions: [
                        TextButton(
                          onPressed: _cargando ? null : () => context.pop(),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: _cargando ? null : _guardar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 20,
                            ),
                          ),
                          child: _cargando
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Registrar Abono',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
