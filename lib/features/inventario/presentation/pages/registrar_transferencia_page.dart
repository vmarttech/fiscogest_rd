import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/kardex_provider.dart';
import 'package:fiscogest_rd/core/providers/core_providers.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';

class RegistrarTransferenciaPage extends ConsumerStatefulWidget {
  const RegistrarTransferenciaPage({super.key});

  @override
  ConsumerState<RegistrarTransferenciaPage> createState() =>
      _RegistrarTransferenciaPageState();
}

class _RegistrarTransferenciaPageState
    extends ConsumerState<RegistrarTransferenciaPage> {
  final _formKey = GlobalKey<FormState>();
  int? _productoId;
  final _cantidadCtrl = TextEditingController();
  final _costoCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final cantidad = double.parse(_cantidadCtrl.text);
    final costo = double.parse(_costoCtrl.text);
    final usuario = ref.read(usuarioAutenticadoProvider)!;
    final casoUso = ref.read(registrarTransferenciaProvider);
    try {
      await casoUso.ejecutar(
        productoId: _productoId!,
        cantidad: cantidad,
        saldoAnterior: 0,
        saldoNuevo: 0,
        costoUnitario: costo,
        usuarioId: usuario,
        observacion: _obsCtrl.text,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    
    return AppScaffold(
      backgroundColor: AppColors.pageBackground,
      // design system

      title: 'Transferencia de Inventario',
      body: SafeArea(
        bottom: true,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width < 768 ? 560 : 760),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                children: [
                  const Text(
                    'Seleccionar Producto',
                    style: AppTypography.labelMedium,
                  ),
                  AppLayout.vM,
                  AppTextField(
                    label: 'Cantidad',
                    controller: _cantidadCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  AppLayout.vM,
                  AppTextField(
                    label: 'Costo Unitario',
                    controller: _costoCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  AppLayout.vM,
                  AppTextField(label: 'Observación', controller: _obsCtrl),
                  AppLayout.vL,
                  AppButton(
                    text: 'Registrar Transferencia',
                    onPressed: _guardar,
                  ),
                ],
              ),
            ),
          ), // ConstrainedBox
        ), // Center
      ),
    );
  }
}
