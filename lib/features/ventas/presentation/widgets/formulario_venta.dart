import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/cobrar_page.dart';
import 'package:fiscogest_rd/features/creditos/presentation/widgets/formulario_credito_vista.dart';

enum ModoFormularioVenta {
  normal,
  cobro,
  credito,
}

class FormularioVenta extends ConsumerStatefulWidget {
  const FormularioVenta({
    super.key,
    required this.alSeleccionarCliente,
    required this.alSeleccionarFormaPago,
  });

  final VoidCallback alSeleccionarCliente;
  final VoidCallback alSeleccionarFormaPago;

  @override
  ConsumerState<FormularioVenta> createState() => _FormularioVentaState();
}

class _FormularioVentaState extends ConsumerState<FormularioVenta> {
  ModoFormularioVenta _modo = ModoFormularioVenta.normal;
  RegistrarVentaState? _datosVenta;

  void _cerrarDialogoYCambiarModo(void Function() accion) {
    final contexto = context;
    if (Navigator.canPop(contexto)) {
      Navigator.pop(contexto);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(accion);
      }
    });
  }

  void _abrirModoCobro() {
    _cerrarDialogoYCambiarModo(() {
      _datosVenta = ref.read(registrarVentaProvider);
      _modo = ModoFormularioVenta.cobro;
    });
  }

  void _abrirModoCredito() {
    _cerrarDialogoYCambiarModo(() {
      _datosVenta = ref.read(registrarVentaProvider);
      _modo = ModoFormularioVenta.credito;
    });
  }

  void _cerrarModo() {
    setState(() {
      _modo = ModoFormularioVenta.normal;
      _datosVenta = null;
    });
  }

  void _onCreditoConfirmado(_) {
    _cerrarModo();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: Padding(
        padding: AppLayout.pantallaPadding,
        child: switch (_modo) {
          ModoFormularioVenta.normal => _buildModoNormal(),
          ModoFormularioVenta.cobro => _buildModoCobro(),
          ModoFormularioVenta.credito => _buildModoCredito(),
        },
      ),
    );
  }

  Widget _buildModoNormal() {
    final estado = ref.watch(registrarVentaProvider);
    return AppCard(
      child: Padding(
        padding: AppSpacing.allM,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Datos de la Venta',
              style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.m),
            InkWell(
              onTap: widget.alSeleccionarCliente,
              borderRadius: AppRadius.allM,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s, horizontal: AppSpacing.xs),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.m),
                    const Expanded(child: Text('Cliente', style: AppTypography.labelMedium)),
                    Row(
                      children: [
                        Text(
                          (estado.clienteNombre?.isNotEmpty ?? false)
                              ? estado.clienteNombre ?? 'Seleccionar'
                              : 'Seleccionar',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            InkWell(
              onTap: widget.alSeleccionarFormaPago,
              borderRadius: AppRadius.allM,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s, horizontal: AppSpacing.xs),
                child: Row(
                  children: [
                    const Icon(Icons.payment, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.m),
                    const Expanded(child: Text('Forma de Pago', style: AppTypography.labelMedium)),
                    Row(
                      children: [
                        Text(
                          estado.tipoPago.isNotEmpty
                              ? '${estado.tipoPago[0].toUpperCase()}${estado.tipoPago.substring(1)}${estado.esCredito ? ' (Crédito)' : ''}'
                              : 'Seleccionar',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w500,
                            color: estado.tipoPago.isNotEmpty
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'COBRAR',
                onPressed: _abrirModoCobro,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModoCobro() {
    return AppCard(
      child: Padding(
        padding: AppSpacing.allM,
        child: CobrarPage(
          onVolver: _cerrarModo,
          onIrACredito: _abrirModoCredito,
        ),
      ),
    );
  }

  Widget _buildModoCredito() {
    if (_datosVenta == null) return const SizedBox.shrink();
    return AppCard(
      child: Padding(
        padding: AppSpacing.allM,
        child: FormularioCreditoVista(
          estadoVenta: _datosVenta!,
          onVolver: _cerrarModo,
          onConfirmado: _onCreditoConfirmado,
        ),
      ),
    );
  }
}
