import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/detalle_compra.dart';
import 'package:fiscogest_rd/features/comercial/presentation/providers/compra/compra_usecase_providers.dart';

class RegistrarCompraPage extends ConsumerStatefulWidget {
  const RegistrarCompraPage({super.key});
  static const String routeName = 'registrar-compra';

  @override
  ConsumerState<RegistrarCompraPage> createState() => _RegistrarCompraPageState();
}

class _DetalleLinea {
  String productoId = '';
  String nombreProducto = '';
  double cantidad = 0.0;
  double costoUnitario = 0.0;
  double descuentoPorcentaje = 0.0;

  double get importeBruto => cantidad * costoUnitario;
  double get montoDescuentoLinea => importeBruto * (descuentoPorcentaje / 100);
  double get subtotalLinea => importeBruto - montoDescuentoLinea;
}

class _RegistrarCompraPageState extends ConsumerState<RegistrarCompraPage> {
  final _formKey = GlobalKey<FormState>();
  final _fechaController = TextEditingController();
  final _proveedorIdController = TextEditingController();
  final _proveedorNombreController = TextEditingController();
  final _comprobanteController = TextEditingController();
  final _observacionesController = TextEditingController();
  final List<_DetalleLinea> _lineas = [];

  @override
  void initState() {
    super.initState();
    _fechaController.text = DateTime.now().toLocal().toString().split(' ')[0];
  }

  void _agregarLinea() {
    setState(() {
      _lineas.add(_DetalleLinea());
    });
  }

  void _eliminarLinea(int index) {
    setState(() {
      _lineas.removeAt(index);
    });
  }

  double get _subtotalSinImpuestos {
    return _lineas.fold(0.0, (sum, linea) => sum + linea.subtotalLinea);
  }

  double get _descuentoGlobal {
    return _lineas.fold(0.0, (sum, linea) => sum + linea.montoDescuentoLinea);
  }

  double get _tasaImpuesto => 0.18;

  double get _montoImpuesto => _subtotalSinImpuestos * _tasaImpuesto;

  double get _totalCompra => _subtotalSinImpuestos + _montoImpuesto;

  Future<void> _guardarCompra() async {
    if (!_formKey.currentState!.validate()) return;

    if (_lineas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Debe agregar al menos un producto')),
      );
      return;
    }

    for (var i = 0; i < _lineas.length; i++) {
      final linea = _lineas[i];
      if (linea.productoId.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Línea ${i + 1}: Ingrese el ID del producto')),
        );
        return;
      }
      if (linea.cantidad <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Línea ${i + 1}: La cantidad debe ser mayor a cero')),
        );
        return;
      }
      if (linea.costoUnitario <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Línea ${i + 1}: El costo unitario debe ser mayor a cero')),
        );
        return;
      }
    }

    final ahora = DateTime.now();
    final compraId = ahora.millisecondsSinceEpoch.toString();

    final compra = Compra(
      id: compraId,
      proveedorId: _proveedorIdController.text.trim(),
      nombreProveedor: _proveedorNombreController.text.trim(),
      fechaEmision: ahora,
      fechaConfirmacion: null,
      numeroComprobante: _comprobanteController.text.trim(),
      subtotalSinImpuestos: _subtotalSinImpuestos,
      montoDescuentoGlobal: _descuentoGlobal,
      tasaImpuesto: _tasaImpuesto,
      montoImpuesto: _montoImpuesto,
      totalCompra: _totalCompra,
      observaciones: _observacionesController.text.trim(),
      estado: EstadoCompra.borrador,
      creadoEn: ahora,
      actualizadoEn: null,
    );

    final detalles = _lineas.asMap().entries.map((entry) {
      final i = entry.key;
      final linea = entry.value;
      return DetalleCompra(
        id: '${compraId}_L$i',
        compraId: compraId,
        productoId: linea.productoId.trim(),
        nombreProducto: linea.nombreProducto.trim(),
        cantidad: linea.cantidad,
        costoUnitario: linea.costoUnitario,
        descuentoPorcentaje: linea.descuentoPorcentaje,
        montoDescuentoLinea: linea.montoDescuentoLinea,
        subtotalLinea: linea.subtotalLinea,
      );
    }).toList();

    try {
      await ref.read(registrarCompraUseCaseProvider).call(
        compra: compra,
        detalles: detalles,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Compra guardada como borrador')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Registrar Compra',
      body: SingleChildScrollView(
        padding: AppSpacing.allM,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Datos de la Compra', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.m),
              AppTextField(
                controller: _fechaController,
                label: 'Fecha de Emisión',
                enabled: false,
              ),
              const SizedBox(height: AppSpacing.m),
              AppTextField(
                controller: _proveedorIdController,
                label: 'ID Proveedor',
              ),
              const SizedBox(height: AppSpacing.m),
              AppTextField(
                controller: _proveedorNombreController,
                label: 'Nombre Proveedor',
              ),
              const SizedBox(height: AppSpacing.m),
              AppTextField(
                controller: _comprobanteController,
                label: 'Número Comprobante',
              ),
              const SizedBox(height: AppSpacing.m),
              AppTextField(
                controller: _observacionesController,
                label: 'Observaciones',
              ),
              const SizedBox(height: AppSpacing.l),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Productos / Líneas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: _agregarLinea,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Agregar Producto'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),

              if (_lineas.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No hay productos agregados. Presione "Agregar Producto".',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                )
              else
                ..._lineas.asMap().entries.map((entry) {
                  final index = entry.key;
                  final linea = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.m),
                    child: Padding(
                      padding: AppSpacing.allM,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Línea ${index + 1}', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () => _eliminarLinea(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: AppTextField(
                                  controller: TextEditingController(text: linea.productoId),
                                  label: 'ID Producto',
                                  onChanged: (v) => setState(() => linea.productoId = v),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.m),
                              Expanded(
                                flex: 3,
                                child: AppTextField(
                                  controller: TextEditingController(text: linea.nombreProducto),
                                  label: 'Nombre Producto',
                                  onChanged: (v) => setState(() => linea.nombreProducto = v),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: AppTextField(
                                  controller: TextEditingController(text: linea.cantidad > 0 ? linea.cantidad.toString() : ''),
                                  label: 'Cantidad',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (v) => setState(() => linea.cantidad = double.tryParse(v) ?? 0),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.m),
                              Expanded(
                                child: AppTextField(
                                  controller: TextEditingController(text: linea.costoUnitario > 0 ? linea.costoUnitario.toString() : ''),
                                  label: 'Costo Unitario',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (v) => setState(() => linea.costoUnitario = double.tryParse(v) ?? 0),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.m),
                              Expanded(
                                child: AppTextField(
                                  controller: TextEditingController(text: linea.descuentoPorcentaje > 0 ? linea.descuentoPorcentaje.toString() : ''),
                                  label: '% Descuento',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (v) => setState(() => linea.descuentoPorcentaje = double.tryParse(v) ?? 0),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              'Subtotal línea: \$${linea.subtotalLinea.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: AppSpacing.l),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.m),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Subtotal: \$${_subtotalSinImpuestos.toStringAsFixed(2)}'),
                      Text('Descuentos: \$${_descuentoGlobal.toStringAsFixed(2)}'),
                      Text('ITBIS (18%): \$${_montoImpuesto.toStringAsFixed(2)}'),
                      const Divider(),
                      Text('TOTAL: \$${_totalCompra.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.l),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Guardar Compra',
                  onPressed: _guardarCompra,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
