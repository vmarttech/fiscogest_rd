import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/entrada_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
class RegistrarEntradaPage extends ConsumerStatefulWidget {
  const RegistrarEntradaPage({
    super.key,
    this.productoId = 0,
    this.nombreProducto = '',
  });
  static const String routeName = 'registrar-entrada';
  final int productoId;
  final String nombreProducto;
  @override
  ConsumerState<RegistrarEntradaPage> createState() => _RegistrarEntradaPageState();
}
class _RegistrarEntradaPageState extends ConsumerState<RegistrarEntradaPage> {
  final _cantidadController = TextEditingController();
  final _motivoController = TextEditingController();
  DateTime _fechaSeleccionada = DateTime.now();
  @override
  void dispose() {
    _cantidadController.dispose();
    _motivoController.dispose();
    super.dispose();
  }
  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (fecha != null) setState(() => _fechaSeleccionada = fecha);
  }
  Future<void> _guardarEntrada() async {
    final cantidad = double.tryParse(_cantidadController.text);
    if (cantidad == null || cantidad <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingrese una cantidad válida mayor a cero')),
        );
      }
      return;
    }
    await ref.read(entradaControllerProvider.notifier).registrarEntrada(
      productoId: widget.productoId,
      cantidad: cantidad,
      motivo: _motivoController.text.trim().isEmpty ? 'Entrada por compra' : _motivoController.text.trim(),
      usuario: 'UsuarioActual',
    );
    ref.invalidate(productoControllerProvider);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrada registrada y existencias actualizadas')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Registrar Entrada de Inventario',
      padding: AppSpacing.allL,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: AppCard(
              padding: AppSpacing.allXl,
              elevation: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: AppSpacing.allM,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_shopping_cart, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ingreso de mercancía',
                              style: AppTypography.h4,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              widget.nombreProducto,
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: AppSpacing.vL,
                    child: Divider(height: 1),
                  ),
                  AppTextField(
                    controller: _cantidadController,
                    keyboardType: TextInputType.number,
                    label: 'Cantidad a ingresar',
                    hint: 'Ej. 10',
                  ),
                  const SizedBox(height: AppSpacing.l),
                  AppTextField(
                    controller: _motivoController,
                    label: 'Motivo (opcional)',
                    hint: 'Ej. Compra a proveedor / Devolución',
                  ),
                  const SizedBox(height: AppSpacing.l),
                  InkWell(
                    onTap: _seleccionarFecha,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: AppSpacing.hM,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 20),
                          const SizedBox(width: AppSpacing.s),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Fecha de entrada', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  '${_fechaSeleccionada.day.toString().padLeft(2, '0')}/${_fechaSeleccionada.month.toString().padLeft(2, '0')}/${_fechaSeleccionada.year}',
                                  style: AppTypography.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textDisabled),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: 'Guardar Entrada',
                      onPressed: _guardarEntrada,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
