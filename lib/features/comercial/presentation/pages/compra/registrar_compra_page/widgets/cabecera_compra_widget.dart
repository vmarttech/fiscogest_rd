import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';

class CabeceraCompraWidget extends StatelessWidget {

  const CabeceraCompraWidget({
    super.key,
    required this.fechaController,
    required this.proveedorIdController,
    required this.proveedorNombreController,
    required this.onSeleccionarProveedor,
    required this.comprobanteController,
    required this.ncfController,
    required this.tipoComprobante,
    required this.onTipoComprobanteChanged,
    required this.formaPago,
    required this.onFormaPagoChanged,
    required this.condicionPagoController,
    required this.diasCreditoController,
    required this.fechaVencimientoController,
    required this.observacionesController,
    required this.esPequena,
    required this.filaResponsiva,
    this.modoSimplificado = false,
  });
  final TextEditingController fechaController;
  final TextEditingController proveedorIdController;
  final TextEditingController proveedorNombreController;
  final VoidCallback onSeleccionarProveedor;
  final TextEditingController comprobanteController;
  final TextEditingController ncfController;
  final String tipoComprobante;
  final ValueChanged<String> onTipoComprobanteChanged;
  final String formaPago;
  final ValueChanged<String> onFormaPagoChanged;
  final TextEditingController condicionPagoController;
  final TextEditingController diasCreditoController;
  final TextEditingController fechaVencimientoController;
  final TextEditingController observacionesController;
  final bool esPequena;
  final bool modoSimplificado;
  final Widget Function({required Widget child1, required Widget child2}) filaResponsiva;

  Widget _buildChipTipoComprobante(String valor, String etiqueta, BuildContext context) {
    final seleccionado = tipoComprobante == valor;
    return InkWell(
      onTap: () => onTipoComprobanteChanged(valor),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: seleccionado
              ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionado
                ? Theme.of(context).primaryColor
                : Colors.transparent,
          ),
        ),
        child: Text(
          '$valor • $etiqueta',
          style: AppTypography.bodySmall.copyWith(
            color: seleccionado ? Theme.of(context).primaryColor : null,
            fontWeight: seleccionado ? FontWeight.w500 : null,
          ),
        ),
      ),
    );
  }

  Widget _buildBotonFormaPago(String valor, String etiqueta, BuildContext context) {
    final seleccionado = formaPago == valor;
    return InkWell(
      onTap: () => onFormaPagoChanged(valor),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: seleccionado
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: seleccionado
                  ? Center(
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 6),
            Text(
              etiqueta,
              style: AppTypography.bodyMedium.copyWith(
                color: seleccionado ? Theme.of(context).primaryColor : null,
                fontWeight: seleccionado ? FontWeight.w500 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Datos de la Compra', style: AppTypography.h4),
        AppLayout.vS,
        AppTextField(
          controller: fechaController,
          label: 'Fecha Emisión',
          enabled: false,
          prefixIcon: Icons.calendar_today_outlined,
        ),
        AppLayout.vM,
        filaResponsiva(
          child1: AppTextField(
            controller: proveedorIdController,
            label: 'ID Proveedor',
          ),
          child2: GestureDetector(
            onTap: onSeleccionarProveedor,
            child: AbsorbPointer(
              child: AppTextField(
                controller: proveedorNombreController,
                label: 'Proveedor',
                prefixIcon: Icons.search,
              ),
            ),
          ),
        ),
        AppLayout.vM,
        if (modoSimplificado)
          AppTextField(
            controller: comprobanteController,
            label: 'Nº factura / recibo (opcional)',
            prefixIcon: Icons.receipt_outlined,
          )
        else
          filaResponsiva(
            child1: AppTextField(
              controller: comprobanteController,
              label: 'Comprobante / Nº Factura',
              prefixIcon: Icons.receipt_outlined,
            ),
            child2: AppTextField(
              controller: ncfController,
              label: 'NCF (ej: B01-00000000)',
              prefixIcon: Icons.confirmation_num_outlined,
            ),
          ),
        AppLayout.vM,
        if (!modoSimplificado) ...[
          const Text(
            'Tipo de Comprobante',
            style: AppTypography.labelMedium,
          ),
          AppLayout.vS,
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              _buildChipTipoComprobante('B01', 'Gastos', context),
              _buildChipTipoComprobante('B02', 'Activos', context),
              _buildChipTipoComprobante('B14', 'Gastos Menores', context),
              _buildChipTipoComprobante('B15', 'Exento', context),
            ],
          ),
          AppLayout.vM,
        ],
        const Text(
          'Forma de Pago',
          style: AppTypography.labelMedium,
        ),
        AppLayout.vS,
        Row(
          children: [
            _buildBotonFormaPago('contado', 'Contado', context),
            if (!modoSimplificado) ...[
              AppLayout.hM,
              _buildBotonFormaPago('credito', 'Crédito', context),
            ],
          ],
        ),
        AppLayout.vM,
        if (!modoSimplificado && formaPago == 'credito') ...[
          filaResponsiva(
            child1: AppTextField(
              controller: condicionPagoController,
              label: 'Condición de Pago (ej: 30 días)',
            ),
            child2: AppTextField(
              controller: diasCreditoController,
              label: 'Días de Crédito',
              keyboardType: TextInputType.number,
            ),
          ),
          AppLayout.vM,
          AppTextField(
            controller: fechaVencimientoController,
            label: 'Fecha de Vencimiento (YYYY-MM-DD)',
            prefixIcon: Icons.event_outlined,
          ),
          AppLayout.vM,
        ],
        AppTextField(
          controller: observacionesController,
          label: 'Observaciones',
          prefixIcon: Icons.notes_outlined,
        ),
      ],
    );
  }
}
