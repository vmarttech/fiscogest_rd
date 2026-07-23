import 'package:flutter/material.dart';
import 'package:fiscogestrd/models/operacion.dart';

class RegistroVentaScreen extends StatefulWidget {
  const RegistroVentaScreen({super.key});

  @override
  State<RegistroVentaScreen> createState() => _RegistroVentaScreenState();
}

class _RegistroVentaScreenState extends State<RegistroVentaScreen> {
  final _formKey = GlobalKey<FormState>();

  final _numeroComprobanteCtrl = TextEditingController();
  final _clienteCtrl = TextEditingController();
  final _rncClienteCtrl = TextEditingController();
  final _subTotalCtrl = TextEditingController();
  final _itbisCtrl = TextEditingController();
  final _impuestoSelectivoCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _observacionCtrl = TextEditingController();

  DateTime _fechaSeleccionada = DateTime.now();

  @override
  void dispose() {
    _numeroComprobanteCtrl.dispose();
    _clienteCtrl.dispose();
    _rncClienteCtrl.dispose();
    _subTotalCtrl.dispose();
    _itbisCtrl.dispose();
    _impuestoSelectivoCtrl.dispose();
    _totalCtrl.dispose();
    _observacionCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('es', 'ES'),
    );
    if (fecha != null) {
      setState(() => _fechaSeleccionada = fecha);
    }
  }

  Future<void> _guardarVenta() async {
    if (_formKey.currentState?.validate() ?? false) {
      Venta(
        numeroComprobante: _numeroComprobanteCtrl.text.trim(),
        fecha: _fechaSeleccionada,
        cliente: _clienteCtrl.text.trim(),
        rncCliente: _rncClienteCtrl.text.trim().isNotEmpty
            ? _rncClienteCtrl.text.trim()
            : null,
        detalles: const [],
        subTotal: double.tryParse(_subTotalCtrl.text) ?? 0.0,
        itbisGenerado: double.tryParse(_itbisCtrl.text) ?? 0.0,
        impuestoSelectivo: double.tryParse(_impuestoSelectivoCtrl.text) ?? 0.0,
        total: double.tryParse(_totalCtrl.text) ?? 0.0,
        observacion: _observacionCtrl.text.trim().isNotEmpty
            ? _observacionCtrl.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venta registrada correctamente')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Venta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Fecha: ${_fechaSeleccionada.day}/${_fechaSeleccionada.month}/${_fechaSeleccionada.year}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _seleccionarFecha,
                    child: const Text('Cambiar'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _numeroComprobanteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Número de comprobante',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.trim().isEmpty ?? true ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _clienteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cliente',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.trim().isEmpty ?? true ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _rncClienteCtrl,
                decoration: const InputDecoration(
                  labelText: 'RNC / Cédula (opcional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _subTotalCtrl,
                decoration: const InputDecoration(
                  labelText: 'Subtotal',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) return 'Campo obligatorio';
                  if (double.tryParse(value!) == null) return 'Ingrese un valor válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _itbisCtrl,
                decoration: const InputDecoration(
                  labelText: 'ITBIS Generado',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _impuestoSelectivoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Impuesto Selectivo',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _totalCtrl,
                decoration: const InputDecoration(
                  labelText: 'Total',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) return 'Campo obligatorio';
                  if (double.tryParse(value!) == null) return 'Ingrese un valor válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _observacionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observación (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _guardarVenta,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text(
                  'Guardar Venta',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}