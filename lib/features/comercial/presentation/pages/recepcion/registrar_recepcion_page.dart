import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/recepcion.dart';
import 'package:fiscogest_rd/features/comercial/presentation/providers/recepcion/recepcion_provider.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/recepcion_elemento.dart';

class RegistrarRecepcionPage extends ConsumerStatefulWidget {
  const RegistrarRecepcionPage({
    super.key,
    this.compraId = 0,
    this.proveedorId = 0,
    this.proveedorNombre,
    this.usuarioResponsable = 'usuario_actual',
    this.detallesCompra = const [],
  });

  static const String routeName = 'registrar-recepcion';
  final int compraId;
  final int proveedorId;
  final String? proveedorNombre;
  final String usuarioResponsable;
  final List<DetalleRecepcion> detallesCompra;

  @override
  ConsumerState<RegistrarRecepcionPage> createState() =>
      _RegistrarRecepcionPageState();
}

class _RegistrarRecepcionPageState
    extends ConsumerState<RegistrarRecepcionPage> {
  String _estadoRecepcion = 'parcial';
  late List<DetalleRecepcion> _detallesEditables;
  final List<TextEditingController> _costoControllers = [];
  final List<TextEditingController> _fleteControllers = [];
  final List<TextEditingController> _seguroControllers = [];
  final List<TextEditingController> _arancelesControllers = [];
  final List<TextEditingController> _gastosControllers = [];

  @override
  void initState() {
    super.initState();
    _detallesEditables = widget.detallesCompra.map((d) => d).toList();
    for (final d in _detallesEditables) {
      _costoControllers.add(TextEditingController(
        text: (d.costoUnitario ?? 0).toString(),
      ));
      _fleteControllers.add(TextEditingController(
        text: d.fleteUnitario.toString(),
      ));
      _seguroControllers.add(TextEditingController(
        text: d.seguroUnitario.toString(),
      ));
      _arancelesControllers.add(TextEditingController(
        text: d.arancelesUnitario.toString(),
      ));
      _gastosControllers.add(TextEditingController(
        text: d.gastosUnitario.toString(),
      ));
    }
  }

  @override
  void dispose() {
    for (final c in _costoControllers) {
      c.dispose();
    }
    for (final c in _fleteControllers) {
      c.dispose();
    }
    for (final c in _seguroControllers) {
      c.dispose();
    }
    for (final c in _arancelesControllers) {
      c.dispose();
    }
    for (final c in _gastosControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final fechaController = TextEditingController(
      text: DateTime.now().toLocal().toString().split(' ')[0],
    );
    final proveedorController = TextEditingController(
      text: widget.proveedorNombre ?? widget.proveedorId.toString(),
    );
    final observacionesController = TextEditingController();

    return AppScaffold(
      title: 'Registrar Recepción',
      body: SingleChildScrollView(
        padding: AppSpacing.allM,
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Datos de Recepción', style: AppTypography.h4),
              AppLayout.vM,
              AppTextField(
                controller: fechaController,
                label: 'Fecha de Recepción',
                enabled: false,
              ),
              AppLayout.vM,
              AppTextField(
                controller: proveedorController,
                label: 'Proveedor',
                enabled: false,
              ),
              AppLayout.vM,
              const Text(
                'Estado de Recepción',
                style: AppTypography.labelMedium,
              ),
              AppLayout.vS,
              Row(
                children: [
                  _buildBotonEstado('parcial', 'Parcial'),
                  AppLayout.hM,
                  _buildBotonEstado('completa', 'Completa'),
                ],
              ),
              AppLayout.vM,
              const Text(
                'Detalle de Productos',
                style: AppTypography.labelMedium,
              ),
              AppLayout.vS,
              ..._detallesEditables.asMap().entries.map((entry) {
                final index = entry.key;
                final det = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: AppSpacing.allM,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            det.productoNombre ?? 'Producto',
                            style: AppTypography.labelMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pedida: ${det.cantidadPedida ?? 0} — Recibida: ${det.cantidadRecibida ?? 0}',
                            style: AppTypography.bodySmall,
                          ),
                          if ((det.diferencia ?? 0) != 0)
                            Text(
                              'Diferencia: ${det.diferencia}',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.red,
                              ),
                            ),
                          AppLayout.vS,
                          AppTextField(
                            controller: _costoControllers[index],
                            label: 'Costo Unitario',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (valor) {
                              final nuevoCosto = double.tryParse(valor) ?? 0.0;
                              setState(() {
                                _detallesEditables[index] = _detallesEditables[index].copyWith(
                                  costoUnitario: nuevoCosto,
                                );
                              });
                            },
                          ),
                          AppLayout.vS,
                          AppTextField(
                            controller: _fleteControllers[index],
                            label: 'Flete por unidad',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (valor) {
                              final nuevo = double.tryParse(valor) ?? 0.0;
                              setState(() {
                                _detallesEditables[index] = _detallesEditables[index].copyWith(
                                  fleteUnitario: nuevo,
                                );
                              });
                            },
                          ),
                          AppLayout.vS,
                          AppTextField(
                            controller: _seguroControllers[index],
                            label: 'Seguro por unidad',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (valor) {
                              final nuevo = double.tryParse(valor) ?? 0.0;
                              setState(() {
                                _detallesEditables[index] = _detallesEditables[index].copyWith(
                                  seguroUnitario: nuevo,
                                );
                              });
                            },
                          ),
                          AppLayout.vS,
                          AppTextField(
                            controller: _arancelesControllers[index],
                            label: 'Aranceles por unidad',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (valor) {
                              final nuevo = double.tryParse(valor) ?? 0.0;
                              setState(() {
                                _detallesEditables[index] = _detallesEditables[index].copyWith(
                                  arancelesUnitario: nuevo,
                                );
                              });
                            },
                          ),
                          AppLayout.vS,
                          AppTextField(
                            controller: _gastosControllers[index],
                            label: 'Gastos por unidad',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (valor) {
                              final nuevo = double.tryParse(valor) ?? 0.0;
                              setState(() {
                                _detallesEditables[index] = _detallesEditables[index].copyWith(
                                  gastosUnitario: nuevo,
                                );
                              });
                            },
                          ),
                          AppLayout.vS,
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Costo Adquisición: RD\$ ${det.costoAdquisicion.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              AppLayout.vM,
              AppTextField(
                controller: observacionesController,
                label: 'Observaciones',
              ),
              AppLayout.vL,
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Confirmar Recepción',
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      final recepcion = Recepcion(
                        id: DateTime.now().millisecondsSinceEpoch,
                        compraId: widget.compraId,
                        proveedorId: widget.proveedorId,
                        proveedorNombre: widget.proveedorNombre,
                        fechaRecepcion: DateTime.now(),
                        estado: _estadoRecepcion,
                        observaciones: observacionesController.text,
                        detalles: _detallesEditables,
                        usuarioResponsable: widget.usuarioResponsable,
                        fechaCreacion: DateTime.now(),
                      );
                      await ref
                          .read(recepcionNotifierProvider.notifier)
                          .registrar(recepcion, widget.usuarioResponsable);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotonEstado(String valor, String etiqueta) {
    final seleccionado = _estadoRecepcion == valor;
    return InkWell(
      onTap: () => setState(() => _estadoRecepcion = valor),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: seleccionado ? Theme.of(context).primaryColor : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: seleccionado
                  ? Center(
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 6),
            Text(
              etiqueta,
              style: AppTypography.bodyMedium.copyWith(
                color: seleccionado ? Theme.of(context).primaryColor : null,
                fontWeight: seleccionado ? FontWeight.w500 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
