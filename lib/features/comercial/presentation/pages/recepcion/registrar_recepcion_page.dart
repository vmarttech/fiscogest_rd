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
  });
  static const String routeName = 'registrar-recepcion';

  final String compraId;
  final String proveedorId;
  final String? proveedorNombre;
  final String usuarioResponsable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final fechaController = TextEditingController(
      text: DateTime.now().toLocal().toString().split(' ')[0],
    );
    final proveedorController = TextEditingController(
      text: proveedorNombre ?? proveedorId,
    );

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
                        estado: 'pendiente',
                        detalles: const [],
                        usuarioResponsable: usuarioResponsable,
                        fechaCreacion: DateTime.now(),
                      );
                      await ref.read(recepcionServiceProvider).registrar(recepcion, usuarioResponsable);
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
