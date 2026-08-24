import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/recepcion.dart';
import 'package:fiscogest_rd/features/comercial/presentation/providers/recepcion/recepcion_provider.dart';

class RegistrarRecepcionPage extends ConsumerWidget {
  const RegistrarRecepcionPage({
    super.key,
    this.compraId = '',
    this.proveedorId = '',
    this.proveedorNombre,
    this.usuarioResponsable = 'usuario_actual',
    this.detallesCompra = const [],
  });

  static const String routeName = 'registrar-recepcion';
  final String compraId;
  final String proveedorId;
  final String? proveedorNombre;
  final String usuarioResponsable;
  final List<DetalleRecepcion> detallesCompra;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final fechaController = TextEditingController(
      text: DateTime.now().toLocal().toString().split(' ')[0],
    );
    final proveedorController = TextEditingController(
      text: proveedorNombre ?? proveedorId,
    );
    final observacionesController = TextEditingController();
    final List<DetalleRecepcion> detalles = detallesCompra;
    String estadoRecepcion = 'parcial';

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
              Row(
                children: [
                  Radio<String>(
                    value: 'parcial',
                    groupValue: estadoRecepcion,
                    onChanged: (String? v) { estadoRecepcion = v ?? 'parcial'; },
                  ),
                  const Text('Parcial'),
                  const SizedBox(width: 16),
                  Radio<String>(
                    value: 'completa',
                    groupValue: estadoRecepcion,
                    onChanged: (String? v) { estadoRecepcion = v ?? 'completa'; },
                  ),
                  const Text('Completa'),
                ],
              ),
              const SizedBox(height: AppSpacing.m),
              const Text('Detalle de Productos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.s),
              ...detalles.map((DetalleRecepcion det) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(det.productoNombre ?? 'Producto',
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text('Pedida: ${det.cantidadPedida ?? 0} — Recibida: ${det.cantidadRecibida ?? 0}'),
                        if ((det.diferencia ?? 0) != 0)
                          Text('Diferencia: ${det.diferencia}',
                              style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  )),
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
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        compraId: compraId,
                        proveedorId: proveedorId,
                        proveedorNombre: proveedorNombre,
                        fechaRecepcion: DateTime.now(),
                        estado: estadoRecepcion,
                        observaciones: observacionesController.text,
                        detalles: detalles,
                        usuarioResponsable: usuarioResponsable,
                        fechaCreacion: DateTime.now(),
                      );
                      await ref
                          .read(recepcionNotifierProvider.notifier)
                          .registrar(recepcion, usuarioResponsable);
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
