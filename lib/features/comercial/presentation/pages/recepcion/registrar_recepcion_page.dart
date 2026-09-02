import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
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
    final List<DetalleRecepcion> detalles = widget.detallesCompra;

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
              const SizedBox(height: AppSpacing.m),
              AppTextField(
                controller: fechaController,
                label: 'Fecha de Recepción',
                enabled: false,
              ),
              const SizedBox(height: AppSpacing.m),
              AppTextField(
                controller: proveedorController,
                label: 'Proveedor',
                enabled: false,
              ),
              const SizedBox(height: AppSpacing.m),
              const Text('Estado de Recepción', style: TextStyle(fontSize: 16)),
              RadioGroup<String>(
                groupValue: _estadoRecepcion,
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() => _estadoRecepcion = value);
                  }
                },
                child: const Row(
                  children: [
                    Radio<String>(value: 'parcial'),
                    Text('Parcial'),
                    SizedBox(width: 16),
                    Radio<String>(value: 'completa'),
                    Text('Completa'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              const Text(
                'Detalle de Productos',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.s),
              ...detalles.map(
                (DetalleRecepcion det) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        det.productoNombre ?? 'Producto',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Pedida: ${det.cantidadPedida ?? 0} — Recibida: ${det.cantidadRecibida ?? 0}',
                      ),
                      if ((det.diferencia ?? 0) != 0)
                        Text(
                          'Diferencia: ${det.diferencia}',
                          style: const TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              AppTextField(
                controller: observacionesController,
                label: 'Observaciones',
              ),
              const SizedBox(height: AppSpacing.l),
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
                        detalles: detalles,
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
}
