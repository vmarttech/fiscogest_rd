// FiscoGest RD 3.0 - Etapa 3.7: Transferencias entre almacenes
// Pantalla Registrar Transferencia
// CUMPLIMIENTO ESTRICTO A AMBOS DOCUMENTOS OFICIALES
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_form.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_dropdown.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';

class RegistrarTransferenciaPage extends ConsumerWidget {
  const RegistrarTransferenciaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      body: AppForm(
        fields: [
          const AppDropdown<String>(
            initialValue: null,
            items: [],
            onChanged: null,
          ),
          SizedBox(height: AppSpacing.vM.vertical),
          const AppDropdown<String>(
            initialValue: null,
            items: [],
            onChanged: null,
          ),
          SizedBox(height: AppSpacing.vM.vertical),
          const AppTextField(
            controller: null,
          ),
          SizedBox(height: AppSpacing.vL.vertical),
          const AppButton(
            text: 'Procesar Transferencia',
            onPressed: null,
          ),
        ],
      ),
    );
  }
}
