import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/existencia.dart';
import '../providers/existencia_provider.dart';

class FormularioMovimientoScreen extends ConsumerStatefulWidget {
  final Existencia? existencia;
  const FormularioMovimientoScreen({super.key, this.existencia});

  @override
  ConsumerState<FormularioMovimientoScreen> createState() => _FormularioMovimientoScreenState();
}

class _FormularioMovimientoScreenState extends ConsumerState<FormularioMovimientoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();
  String _tipoMovimiento = 'entrada'; // entrada / salida / reserva / ajuste

  late Existencia _existencia;

  @override
  void initState() {
    super.initState();
    _existencia = widget.existencia ?? Existencia(
      productoId: 0,
      codigoProducto: '',
      nombreProducto: '',
      cantidadDisponible: 0,
    );
  }

  Future<void> _procesarMovimiento() async {
    if (_formKey.currentState!.validate()) {
      final cantidad = double.parse(_cantidadController.text);

      setState(() {
        switch (_tipoMovimiento) {
          case 'entrada':
            _existencia = Existencia(
              id: _existencia.id,
              productoId: _existencia.productoId,
              codigoProducto: _existencia.codigoProducto,
              nombreProducto: _existencia.nombreProducto,
              cantidadDisponible: _existencia.cantidadDisponible + cantidad,
              cantidadReservada: _existencia.cantidadReservada,
              cantidadMinima: _existencia.cantidadMinima,
              cantidadMaxima: _existencia.cantidadMaxima,
              ubicacion: _existencia.ubicacion,
            );
            break;
          case 'salida':
            if (cantidad > _existencia.cantidadReal) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error: Cantidad mayor a la existente')),
              );
              return;
            }
            _existencia = Existencia(
              id: _existencia.id,
              productoId: _existencia.productoId,
              codigoProducto: _existencia.codigoProducto,
              nombreProducto: _existencia.nombreProducto,
              cantidadDisponible: _existencia.cantidadDisponible - cantidad,
              cantidadReservada: _existencia.cantidadReservada,
              cantidadMinima: _existencia.cantidadMinima,
              cantidadMaxima: _existencia.cantidadMaxima,
              ubicacion: _existencia.ubicacion,
            );
            break;
          case 'reserva':
            _existencia = Existencia(
              id: _existencia.id,
              productoId: _existencia.productoId,
              codigoProducto: _existencia.codigoProducto,
              nombreProducto: _existencia.nombreProducto,
              cantidadDisponible: _existencia.cantidadDisponible,
              cantidadReservada: _existencia.cantidadReservada + cantidad,
              cantidadMinima: _existencia.cantidadMinima,
              cantidadMaxima: _existencia.cantidadMaxima,
              ubicacion: _existencia.ubicacion,
            );
            break;
          case 'ajuste':
            _existencia = Existencia(
              id: _existencia.id,
              productoId: _existencia.productoId,
              codigoProducto: _existencia.codigoProducto,
              nombreProducto: _existencia.nombreProducto,
              cantidadDisponible: cantidad,
              cantidadReservada: _existencia.cantidadReservada,
              cantidadMinima: _existencia.cantidadMinima,
              cantidadMaxima: _existencia.cantidadMaxima,
              ubicacion: _existencia.ubicacion,
            );
            break;
        }
      });

      try {
        await ref.read(existenciaNotifierProvider.notifier).guardar(_existencia);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Movimiento registrado correctamente ✅')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e ❌')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existencia != null 
          ? 'Movimiento: ${_existencia.nombreProducto}' 
          : 'Nuevo Movimiento de Inventario'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.existencia != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Producto: ${_existencia.codigoProducto} - ${_existencia.nombreProducto}', 
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Cantidad actual: ${_existencia.cantidadReal.toStringAsFixed(2)}'),
                      Text('Stock mínimo: ${_existencia.cantidadMinima.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              const Text('Tipo de Movimiento', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              // ✅ CORREGIDO: Cambiado 'value' por 'initialValue'
              DropdownButtonFormField<String>(
                initialValue: _tipoMovimiento,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'entrada', child: Text('Entrada / Compra')),
                  DropdownMenuItem(value: 'salida', child: Text('Salida / Venta')),
                  DropdownMenuItem(value: 'reserva', child: Text('Reservar')),
                  DropdownMenuItem(value: 'ajuste', child: Text('Ajuste de Inventario')),
                ],
                onChanged: (valor) {
                  if (valor != null) setState(() => _tipoMovimiento = valor);
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _cantidadController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (v == null || double.tryParse(v) == null) ? 'Ingrese una cantidad válida' : null,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _procesarMovimiento,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('REGISTRAR MOVIMIENTO', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}