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
  
  // ✅ NUEVOS CONTROLADORES: PUNTO B y PUNTO C
  final _minimoController = TextEditingController();
  final _maximoController = TextEditingController();
  final _ubicacionController = TextEditingController();

  String _tipoMovimiento = 'entrada'; // entrada / salida / reserva / ajuste
  late Existencia _existencia;
  bool _modificarDatos = false; // 🔘 Switch para editar datos maestros

  @override
  void initState() {
    super.initState();
    // ✅ CORRECCIÓN ERROR LÍNEA 24: AGREGADOS LOS CAMPOS OBLIGATORIOS
    _existencia = widget.existencia ?? Existencia(
      productoId: 0,
      codigoProducto: '',
      nombreProducto: '',
      cantidadDisponible: 0.0,
      cantidadReservada: 0.0,
      cantidadMinima: 5.0,   // ✅ Valor por defecto seguro
      cantidadMaxima: 1000.0,// ✅ Valor por defecto seguro
      ubicacion: 'Almacén Principal', // ✅ Valor por defecto seguro
    );

    // ✅ Inicializar controladores con valores actuales
    _minimoController.text = _existencia.cantidadMinima.toString();
    _maximoController.text = _existencia.cantidadMaxima.toString();
    _ubicacionController.text = _existencia.ubicacion;
  }

  Future<void> _procesarMovimiento() async {
    if (_formKey.currentState!.validate()) {
      final cantidad = double.parse(_cantidadController.text);

      setState(() {
        // ✅ OPCIÓN: Si activó modificar datos, actualizamos Mín, Máx y Ubicación
        final nuevoMinimo = _modificarDatos ? double.parse(_minimoController.text) : _existencia.cantidadMinima;
        final nuevoMaximo = _modificarDatos ? double.parse(_maximoController.text) : _existencia.cantidadMaxima;
        final nuevaUbicacion = _modificarDatos ? _ubicacionController.text : _existencia.ubicacion;

        switch (_tipoMovimiento) {
          case 'entrada':
            _existencia = Existencia(
              id: _existencia.id,
              productoId: _existencia.productoId,
              codigoProducto: _existencia.codigoProducto,
              nombreProducto: _existencia.nombreProducto,
              cantidadDisponible: _existencia.cantidadDisponible + cantidad,
              cantidadReservada: _existencia.cantidadReservada,
              cantidadMinima: nuevoMinimo,
              cantidadMaxima: nuevoMaximo,
              ubicacion: nuevaUbicacion,
            );
            break;

          case 'salida':
            // ✅ USO DE CANTIDADREAL (ya definida en modelo)
            if (cantidad > _existencia.cantidadReal) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('❌ Error: Cantidad mayor a la existente o reservada')),
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
              cantidadMinima: nuevoMinimo,
              cantidadMaxima: nuevoMaximo,
              ubicacion: nuevaUbicacion,
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
              cantidadMinima: nuevoMinimo,
              cantidadMaxima: nuevoMaximo,
              ubicacion: nuevaUbicacion,
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
              cantidadMinima: nuevoMinimo,
              cantidadMaxima: nuevoMaximo,
              ubicacion: nuevaUbicacion,
            );
            break;
        }
      });

      try {
        await ref.read(existenciaNotifierProvider.notifier).guardar(_existencia);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Movimiento registrado correctamente')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Error: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _minimoController.dispose();
    _maximoController.dispose();
    _ubicacionController.dispose();
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
              // 📊 PANEL DE INFORMACIÓN (Homologado con Listado)
              if (widget.existencia != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _existencia.tieneExcesoStock 
                        ? Colors.deepOrange.shade50 
                        : _existencia.estaBajoMinimo 
                            ? Colors.red.shade50 
                            : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Producto: ${_existencia.codigoProducto} - ${_existencia.nombreProducto}', 
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('✅ Stock Real Disponible: ${_existencia.cantidadReal.toStringAsFixed(2)}'),
                      Text('📦 Total Almacenado: ${_existencia.cantidadDisponible.toStringAsFixed(2)}'),
                      Text('🔒 Reservado: ${_existencia.cantidadReservada.toStringAsFixed(2)}'),
                      Text('⚠️ Mínimo: ${_existencia.cantidadMinima.toStringAsFixed(2)} | 🚀 Máximo: ${_existencia.cantidadMaxima.toStringAsFixed(2)}'),
                      Text('📍 Ubicación: ${_existencia.ubicacion}'),
                      Text('⏱️ Último movimiento: ${_existencia.fechaFormateada}', 
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 🔘 OPCIÓN PARA EDITAR DATOS DE INVENTARIO (PUNTO B y C)
                SwitchListTile(
                  title: const Text('Modificar datos de inventario'),
                  subtitle: const Text('Mínimo, Máximo y Ubicación'),
                  value: _modificarDatos,
                  onChanged: (valor) => setState(() => _modificarDatos = valor),
                  secondary: const Icon(Icons.edit_note),
                ),
                const SizedBox(height: 10),

                // ✅ CAMPOS EDITABLES SOLO SI SE ACTIVA EL SWITCH
                if (_modificarDatos) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _minimoController,
                          decoration: const InputDecoration(
                            labelText: 'Stock Mínimo',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            // ✅ CORRECCIÓN: Validación segura paso a paso
                            if (v == null || v.isEmpty) return 'Requerido';
                            final valorMin = double.tryParse(v);
                            if (valorMin == null || valorMin < 0) return 'Inválido';
                            
                            // ✅ Obtenemos valor máximo de forma segura
                            final valorMax = double.tryParse(_maximoController.text) ?? 9999.0;
                            
                            // ✅ Condición 100% booleana y segura
                            if (valorMin >= valorMax) {
                              return 'Mínimo debe ser < Máximo';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _maximoController,
                          decoration: const InputDecoration(
                            labelText: 'Stock Máximo',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requerido';
                            final valor = double.tryParse(v);
                            if (valor == null || valor < 0) return 'Inválido';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ubicacionController,
                    decoration: const InputDecoration(
                      labelText: 'Ubicación / Pasillo / Estante',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Ingrese una ubicación' : null,
                  ),
                  const SizedBox(height: 20),
                ],
              ],

              // 🔄 TIPO DE MOVIMIENTO
              const Text('Tipo de Movimiento', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _tipoMovimiento,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'entrada', child: Text('Entrada / Compra')),
                  DropdownMenuItem(value: 'salida', child: Text('Salida / Venta')),
                  DropdownMenuItem(value: 'reserva', child: Text('Reservar / Apartar')),
                  DropdownMenuItem(value: 'ajuste', child: Text('Ajuste de Inventario')),
                ],
                onChanged: (valor) {
                  if (valor != null) setState(() => _tipoMovimiento = valor);
                },
              ),
              const SizedBox(height: 16),

              // 🔢 CANTIDAD DEL MOVIMIENTO
              TextFormField(
                controller: _cantidadController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad a mover',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (v == null || double.tryParse(v) == null || double.parse(v) <= 0) 
                    ? 'Ingrese una cantidad válida mayor a 0' 
                    : null,
              ),
              const SizedBox(height: 24),

              // 💾 BOTÓN GUARDAR
              ElevatedButton(
                onPressed: _procesarMovimiento,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
                child: const Text('REGISTRAR MOVIMIENTO'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}