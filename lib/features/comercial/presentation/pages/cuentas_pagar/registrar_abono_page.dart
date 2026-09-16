import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/presentation/providers/cuentas_pagar_providers.dart';

class RegistrarAbonoPage extends ConsumerStatefulWidget {
  const RegistrarAbonoPage({super.key, required this.cuentaPagarId});
  final int cuentaPagarId;

  @override
  ConsumerState<RegistrarAbonoPage> createState() => _RegistrarAbonoPageState();
}

class _RegistrarAbonoPageState extends ConsumerState<RegistrarAbonoPage> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _referenciaController = TextEditingController();
  final _notaController = TextEditingController();

  DateTime _fechaPago = DateTime.now();
  String _formaPago = 'efectivo';
  bool _isSubmitting = false;

  static const List<Map<String, String>> formasPago = [
    {'value': 'efectivo', 'label': 'Efectivo'},
    {'value': 'transferencia', 'label': 'Transferencia'},
    {'value': 'cheque', 'label': 'Cheque'},
    {'value': 'tarjeta', 'label': 'Tarjeta'},
    {'value': 'otro', 'label': 'Otro'},
  ];

  @override
  void dispose() {
    _montoController.dispose();
    _referenciaController.dispose();
    _notaController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaPago,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (seleccionada != null) setState(() => _fechaPago = seleccionada);
  }

  Future<void> _guardarAbono() async {
    if (!_formKey.currentState!.validate()) return;
    final monto = double.tryParse(_montoController.text.replaceAll(',', '.'));
    if (monto == null || monto <= 0) return;

    setState(() => _isSubmitting = true);
    try {
      final cuenta = await ref.read(cuentasPagarDaoProvider).obtenerCuentaPorId(widget.cuentaPagarId);
      if (!mounted) return;
      if (cuenta == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta no encontrada'), backgroundColor: Colors.red),
        );
        return;
      }

      await ref.read(registrarAbonoUseCaseProvider).call(
            cuentaPagarId: widget.cuentaPagarId,
            proveedorId: cuenta.proveedorId,
            monto: monto,
            fechaPago: _fechaPago,
            formaPago: _formaPago,
            referencia: _referenciaController.text.trim().isNotEmpty ? _referenciaController.text.trim() : null,
            nota: _notaController.text.trim().isNotEmpty ? _notaController.text.trim() : null,
          );

      if (!mounted) return;
      ref.invalidate(listadoCuentasPagarProvider);
      ref.invalidate(historialPagosPorCuentaProvider(widget.cuentaPagarId));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Abono registrado correctamente'), backgroundColor: Colors.green),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cuentaAsync = ref.watch(listadoCuentasPagarProvider);
    final pagosAsync = ref.watch(historialPagosPorCuentaProvider(widget.cuentaPagarId));

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Abono'), elevation: 0),
      body: cuentaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error al cargar datos: $e')),
        data: (items) {
          final cuentaItem = items.firstWhere(
            (i) => i.id == widget.cuentaPagarId,
            orElse: () => throw StateError('Cuenta no encontrada'),
          );

          return pagosAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error cargando pagos: $e')),
            data: (List<PagoProveedorData> pagos) {
              final totalAbonado = pagos.fold<double>(0.0, (sum, PagoProveedorData p) => sum + p.monto);
              final saldoPendiente = cuentaItem.monto - totalAbonado;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Proveedor: ${cuentaItem.proveedorNombre}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 8),
                              Text('Concepto: ${cuentaItem.concepto}', style: const TextStyle(fontSize: 14)),
                              const Divider(height: 24),
                              _filaResumen('Total cuenta', cuentaItem.monto),
                              const SizedBox(height: 4),
                              _filaResumen('Total abonado', totalAbonado),
                              const Divider(height: 16),
                              _filaResumen('Saldo pendiente', saldoPendiente, esDestacado: true),
                            ],
                          ),
                        ),
                      ),

                      TextFormField(
                        controller: _montoController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Monto del abono RD\$',
                          border: OutlineInputBorder(),
                          prefixText: 'RD\$ ',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        style: const TextStyle(fontSize: 16),
                        validator: (value) {
                          final m = double.tryParse(value?.replaceAll(',', '.') ?? '');
                          if (m == null || m <= 0) return 'Ingrese un monto válido mayor a cero';
                          if (m > saldoPendiente) return 'Excede saldo pendiente (RD\$ ${saldoPendiente.toStringAsFixed(2)})';
                          return null;
                        },
                        enabled: !_isSubmitting,
                      ),
                      const SizedBox(height: 16),

                      InkWell(
                        onTap: _isSubmitting ? null : _seleccionarFecha,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha de pago',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today, size: 20),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          child: Text('${_fechaPago.day}/${_fechaPago.month}/${_fechaPago.year}', style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: _formaPago,
                        decoration: const InputDecoration(
                          labelText: 'Forma de pago',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                        items: formasPago.map((fp) => DropdownMenuItem(value: fp['value'], child: Text(fp['label']!))).toList(),
                        onChanged: _isSubmitting ? null : (v) => setState(() => _formaPago = v!),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _referenciaController,
                        decoration: const InputDecoration(
                          labelText: 'Referencia (opcional)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        style: const TextStyle(fontSize: 16),
                        enabled: !_isSubmitting,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _notaController,
                        decoration: const InputDecoration(
                          labelText: 'Nota / Observación (opcional)',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        style: const TextStyle(fontSize: 16),
                        maxLines: 2,
                        enabled: !_isSubmitting,
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _guardarAbono,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size(double.infinity, 48),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            : const Text('✅ Registrar Abono'),
                      ),
                      const SizedBox(height: 32),

                      const Text('Historial de pagos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (pagos.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('Sin abonos registrados aún.', style: TextStyle(color: Colors.grey, fontSize: 15), textAlign: TextAlign.center),
                        )
                      else
                        ...pagos.map((PagoProveedorData pago) {
                          final refVal = pago.referencia;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text('RD\$ ${pago.monto.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              subtitle: Text(
                                '${pago.fechaPago.day}/${pago.fechaPago.month}/${pago.fechaPago.year} • ${_etiquetaFormaPago(pago.formaPago)}'
                                '${refVal?.isNotEmpty == true ? '\n$refVal' : ''}',
                                style: const TextStyle(fontSize: 14, height: 1.4),
                              ),
                              isThreeLine: refVal?.isNotEmpty == true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _filaResumen(String etiqueta, double valor, {bool esDestacado = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: TextStyle(fontSize: 15, fontWeight: esDestacado ? FontWeight.bold : FontWeight.normal)),
          Text(
            'RD\$ ${valor.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 15, fontWeight: esDestacado ? FontWeight.bold : FontWeight.normal, color: esDestacado ? Colors.blue[800] : null),
          ),
        ],
      );

  String _etiquetaFormaPago(String valor) => const {
        'efectivo': 'Efectivo',
        'transferencia': 'Transferencia',
        'cheque': 'Cheque',
        'tarjeta': 'Tarjeta',
        'otro': 'Otro',
      }[valor] ?? valor;
}
