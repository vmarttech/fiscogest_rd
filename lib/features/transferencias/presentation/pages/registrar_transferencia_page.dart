// FiscoGest RD 3.0 - Etapa 3.7: Transferencias entre almacenes
// Pantalla Registrar Transferencia
// CUMPLIMIENTO ESTRICTO A AMBOS DOCUMENTOS OFICIALES
import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_form.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_dropdown.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/features/transferencias/presentation/providers/transferencia_form_provider.dart';

class RegistrarTransferenciaPage extends ConsumerWidget {
  const RegistrarTransferenciaPage({super.key});
  static const String routeName = 'registrar-transferencia';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    final formState = ref.watch(transferenciaFormProvider);

    return AppScaffold(
      backgroundColor: AppColors.pageBackground,
      // design system

      title: 'Registrar Transferencia',
      body: SingleChildScrollView(
        padding: AppSpacing.allL,
        child: AppForm(
          fields: [
            AppDropdown<String>(
              label: 'Almacén Origen',
              initialValue: formState.almacenOrigen,
              items: const [],
              onChanged: (val) {
                if (val != null) {
                  ref
                      .read(transferenciaFormProvider.notifier)
                      .seleccionarAlmacenOrigen(val);
                }
              },
            ),
            AppLayout.vM,
            AppDropdown<String>(
              label: 'Almacén Destino',
              initialValue: formState.almacenDestino,
              items: const [],
              onChanged: (val) {
                if (val != null) {
                  ref
                      .read(transferenciaFormProvider.notifier)
                      .seleccionarAlmacenDestino(val);
                }
              },
            ),
            AppLayout.vM,
            const AppTextField(
              label: 'Cantidad / Artículo',
              hint: 'Ingrese cantidad',
              controller: null,
            ),
            AppLayout.vL,
            AppButton(
              text: 'Procesar Transferencia',
              onPressed: formState.esValido
                  ? () => ref.read(transferenciaFormProvider.notifier).enviar()
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
