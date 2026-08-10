import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/kardex_provider.dart';
import 'package:fiscogest_rd/core/providers/core_providers.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';

class RegistrarTransferenciaPage extends ConsumerStatefulWidget {
  const RegistrarTransferenciaPage({super.key});

  @override
  ConsumerState<RegistrarTransferenciaPage> createState() => _RegistrarTransferenciaPageState();
}

class _RegistrarTransferenciaPageState extends ConsumerState<RegistrarTransferenciaPage> {
  final _formKey = GlobalKey<FormState>();
  int? _productoId;
  final _cantidadCtrl = TextEditingController();
  final _costoCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final cantidad = double.parse(_cantidadCtrl.text);
    final costo = double.parse(_costoCtrl.text);
    final usuarioId = ref.read(usuarioIdAutenticadoProvider)!;
    final casoUso = ref.read(registrarTransferenciaProvider);

    try {
      await casoUso.ejecutar(
        productoId: _productoId!,
        cantidad: cantidad,
        saldoAnterior: 0,
        saldoNuevo: 0,
        costoUnitario: costo,
        usuarioId: usuarioId,
        observacion: _obsCtrl.text,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Transferencia de Inventario',
      padding: AppSpacing.allM,
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            const Text('Seleccionar Producto', style: AppTypography.labelMedium),
            const SizedBox(height: AppSpacing.s),
            AppTextField(
              label: 'Cantidad',
              controller: _cantidadCtrl,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.m),
            AppTextField(
              label: 'Costo Unitario',
              controller: _costoCtrl,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.m),
            AppTextField(
              label: 'Observación',
              controller: _obsCtrl,
            ),
            const SizedBox(height: AppSpacing.l),
            AppButton(
              text: 'Registrar Transferencia',
              onPressed: _guardar,
            ),
          ],
        ),
      ),
    );
  }
}
