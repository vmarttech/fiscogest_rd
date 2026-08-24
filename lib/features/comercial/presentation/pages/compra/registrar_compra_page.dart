import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/detalle_compra.dart';
import 'package:fiscogest_rd/features/comercial/presentation/providers/compra/compra_usecase_providers.dart';

class RegistrarCompraPage extends ConsumerWidget {
  const RegistrarCompraPage({super.key});

  static const String routeName = 'registrar-compra';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final fechaController = TextEditingController(
      text: DateTime.now().toLocal().toString().split(' ')[0],
    );
    final proveedorIdController = TextEditingController();
    final proveedorNombreController = TextEditingController();
    final comprobanteController = TextEditingController();
    final observacionesController = TextEditingController();

    return AppScaffold(
      title: 'Registrar Compra',
      body: SingleChildScrollView(
        padding: AppSpacing.allM,
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Datos de la Compra', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.m),
              AppTextField(
                controller: fechaController,
                label: 'Fecha de Emisión',
                enabled: false,
              ),
              const SizedBox(height: AppSpacing.m),
              AppTextField(
                controller: proveedorIdController,
                label: 'ID Proveedor',
              ),
              const SizedBox(height: AppSpacing.m),
              AppTextField(
                controller: proveedorNombreController,
                label: 'Nombre Proveedor',
              ),
              const SizedBox(height: AppSpacing.m),
              AppTextField(
                controller: comprobanteController,
                label: 'Número Comprobante',
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
                  text: 'Guardar Compra',
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      final ahora = DateTime.now();
                      final compra = Compra(
                        id: ahora.millisecondsSinceEpoch.toString(),
                        proveedorId: proveedorIdController.text.trim(),
                        nombreProveedor: proveedorNombreController.text.trim(),
                        fechaEmision: ahora,
                        fechaConfirmacion: null,
                        numeroComprobante: comprobanteController.text.trim(),
                        subtotalSinImpuestos: 0,
                        montoDescuentoGlobal: 0,
                        tasaImpuesto: 0,
                        montoImpuesto: 0,
                        totalCompra: 0,
                        observaciones: observacionesController.text.trim(),
                        estado: EstadoCompra.borrador,
                        creadoEn: ahora,
                        actualizadoEn: null,
                      );

                      final detalleVacio = <DetalleCompra>[];

                      try {
                        await ref.read(registrarCompraUseCaseProvider).call(
                          compra: compra,
                          detalles: detalleVacio,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Compra guardada (borrador)')),
                          );
                          Navigator.of(context).pop();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
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
