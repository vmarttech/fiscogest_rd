import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/cobrar_page.dart';
import 'package:fiscogest_rd/features/creditos/presentation/widgets/formulario_credito_vista.dart';

enum ModoFormularioVenta { normal, cobro, credito }

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
    final isMobile = AppBreakpoints.isMobile(context);

    return Container(
      padding: AppSpacing.allM,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.allL,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Datos de la Venta',
            style: AppTypography.h4.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontSize: isMobile ? 15 : 16,
            ),
          ),
          const SizedBox(height: 16),

          // Cliente
          _SelectorRow(
            icon: Icons.person_outline,
            label: 'Cliente',
            value: (estado.clienteNombre?.isNotEmpty ?? false)
                ? estado.clienteNombre!
                : 'Seleccionar',
            onTap: widget.alSeleccionarCliente,
          ),

          const SizedBox(height: 8),

          // Forma de pago
          _SelectorRow(
            icon: Icons.payment_outlined,
            label: 'Forma de Pago',
            value: estado.tipoPago.isNotEmpty
                ? '${estado.tipoPago[0].toUpperCase()}${estado.tipoPago.substring(1)}${estado.esCredito ? ' (Crédito)' : ''}'
                : 'Seleccionar',
            onTap: widget.alSeleccionarFormaPago,
            valueColor: estado.tipoPago.isNotEmpty
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: AppButton(text: 'COBRAR', onPressed: _abrirModoCobro),
          ),
        ],
      ),
    );
  }

  Widget _buildModoCobro() {
    final estado = ref.read(registrarVentaProvider);
    final clienteId = estado.clienteId ?? 0;

    return Container(
      padding: AppSpacing.allM,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.allL,
        border: Border.all(color: AppColors.border),
      ),
      child: CobrarPage(
        clienteIdFiltro: clienteId,
        onVolver: _cerrarModo,
        onIrACredito: _abrirModoCredito,
      ),
    );
  }

  Widget _buildModoCredito() {
    if (_datosVenta == null) return const SizedBox.shrink();

    return Container(
      padding: AppSpacing.allM,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.allL,
        border: Border.all(color: AppColors.border),
      ),
      child: FormularioCreditoVista(
        estadoVenta: _datosVenta!,
        onVolver: _cerrarModo,
        onConfirmado: _onCreditoConfirmado,
      ),
    );
  }
}

class _SelectorRow extends StatelessWidget {
  const _SelectorRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.valueColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.grey50,
      borderRadius: AppRadius.allM,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.allM,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                value,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
