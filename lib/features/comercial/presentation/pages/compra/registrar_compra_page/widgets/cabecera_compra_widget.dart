import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';

class CabeceraCompraWidget extends StatefulWidget {
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
  final Widget Function({required Widget child1, required Widget child2})
      filaResponsiva;

  @override
  State<CabeceraCompraWidget> createState() => _CabeceraCompraWidgetState();
}

class _CabeceraCompraWidgetState extends State<CabeceraCompraWidget> {
  String _sucursal = 'Principal (Santo Domingo)';

  static const _sucursales = [
    'Principal (Santo Domingo)',
    'Sucursal Santiago',
  ];

  Widget _titulo(String t) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.only(bottom: 8),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFF0F4F8), width: 2),
          ),
        ),
        child: Text(
          t,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Color(0xFF2D3748),
          ),
        ),
      );

  Widget _chip(String valor, String etiqueta) {
    final sel = widget.tipoComprobante == valor;
    return InkWell(
      onTap: () => widget.onTipoComprobanteChanged(valor),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFE6F4F2) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: sel ? const Color(0xFF127369) : const Color(0xFFCBD5E0),
          ),
        ),
        child: Text(
          '$valor • $etiqueta',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: sel ? const Color(0xFF127369) : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }

  Widget _segment() {
    final ops = <(String, String)>[
      ('contado', 'Contado'),
      if (!widget.modoSimplificado) ('credito', 'Crédito'),
      if (!widget.modoSimplificado) ('transferencia', 'Transferencia'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E0)),
      ),
      child: Row(
        children: [
          for (final o in ops)
            Expanded(
              child: InkWell(
                onTap: () => widget.onFormaPagoChanged(o.$1),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: widget.formaPago == o.$1
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: widget.formaPago == o.$1
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      o.$2,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.formaPago == o.$1
                            ? const Color(0xFF127369)
                            : const Color(0xFF666666),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _dec({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFFA0AEC0)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF127369)),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // ── MÓVIL (sin cambios de flujo) ──
  Widget _mobile(BuildContext context) {
    return AppCard(
      borderColor: AppColors.border,
      padding: AppSpacing.allM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: widget.fechaController,
            label: 'Fecha de compra',
            enabled: false,
            prefixIcon: Icons.calendar_today_outlined,
          ),
          AppLayout.vM,
          widget.filaResponsiva(
            child1: AppTextField(
              controller: widget.proveedorIdController,
              label: 'ID Proveedor',
            ),
            child2: GestureDetector(
              onTap: widget.onSeleccionarProveedor,
              child: AbsorbPointer(
                child: AppTextField(
                  controller: widget.proveedorNombreController,
                  label: 'Proveedor',
                  prefixIcon: Icons.search,
                ),
              ),
            ),
          ),
          AppLayout.vM,
          if (widget.modoSimplificado)
            AppTextField(
              controller: widget.comprobanteController,
              label: 'Nº factura / recibo (opcional)',
              prefixIcon: Icons.receipt_outlined,
            )
          else
            widget.filaResponsiva(
              child1: AppTextField(
                controller: widget.comprobanteController,
                label: 'Comprobante / Nº Factura',
                prefixIcon: Icons.receipt_outlined,
              ),
              child2: AppTextField(
                controller: widget.ncfController,
                label: 'NCF (ej: B01-00000000)',
                prefixIcon: Icons.confirmation_num_outlined,
              ),
            ),
          AppLayout.vM,
          if (!widget.modoSimplificado) ...[
            const Text('Tipo de Comprobante', style: AppTypography.labelMedium),
            AppLayout.vS,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('B01', 'Gastos'),
                _chip('B02', 'Activos'),
                _chip('B14', 'Gastos Menores'),
                _chip('B15', 'Exento'),
              ],
            ),
            AppLayout.vM,
          ],
          const Text('Forma de Pago', style: AppTypography.labelMedium),
          AppLayout.vS,
          _segment(),
          if (!widget.modoSimplificado && widget.formaPago == 'credito') ...[
            AppLayout.vM,
            widget.filaResponsiva(
              child1: AppTextField(
                controller: widget.condicionPagoController,
                label: 'Condición de Pago (ej: 30 días)',
              ),
              child2: AppTextField(
                controller: widget.diasCreditoController,
                label: 'Días de Crédito',
                keyboardType: TextInputType.number,
              ),
            ),
            AppLayout.vM,
            AppTextField(
              controller: widget.fechaVencimientoController,
              label: 'Fecha de Vencimiento (YYYY-MM-DD)',
              prefixIcon: Icons.event_outlined,
            ),
          ],
          AppLayout.vM,
          AppTextField(
            controller: widget.observacionesController,
            label: 'Observaciones',
            prefixIcon: Icons.notes_outlined,
          ),
        ],
      ),
    );
  }

  // ── DESKTOP = mock HTML ──
  Widget _desktop(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // DATOS GENERALES — exactamente 3 columnas (Fecha | ID | Sucursal)
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _titulo('DATOS GENERALES'),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.fechaController,
                      enabled: false,
                      decoration: _dec(
                        label: 'Fecha de compra',
                        icon: Icons.calendar_today_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onSeleccionarProveedor,
                      child: AbsorbPointer(
                        child: TextField(
                          controller: widget.proveedorNombreController.text
                                  .trim()
                                  .isNotEmpty
                              ? widget.proveedorNombreController
                              : widget.proveedorIdController,
                          decoration: _dec(
                            label: 'ID Proveedor',
                            icon: Icons.search,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _sucursal,
                      isExpanded: true,
                      decoration: _dec(
                        label: 'Sucursal',
                        icon: Icons.apartment_outlined,
                      ),
                      items: [
                        for (final s in _sucursales)
                          DropdownMenuItem(
                            value: s,
                            child: Text(
                              s,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _sucursal = v);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // DETALLES — Comprobante|NCF ; Tipo|Pago en la MISMA fila
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _titulo('DETALLES DE COMPROBANTE Y PAGO'),
              if (widget.modoSimplificado)
                TextField(
                  controller: widget.comprobanteController,
                  decoration: _dec(
                    label: 'Nº factura / recibo (opcional)',
                    icon: Icons.receipt_outlined,
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.comprobanteController,
                        decoration: _dec(
                          label: 'Comprobante / N° Factura',
                          icon: Icons.receipt_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: widget.ncfController,
                        decoration: _dec(
                          label: 'NCF (ej: B01-00000000)',
                          icon: Icons.gavel_outlined,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              if (!widget.modoSimplificado)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tipo de Comprobante',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _chip('B01', 'Gastos'),
                              _chip('B02', 'Activos'),
                              _chip('B14', 'Gastos Menores'),
                              _chip('B15', 'Exento'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Forma de Pago',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 6),
                          _segment(),
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                const Text(
                  'Forma de Pago',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 6),
                _segment(),
              ],
              if (!widget.modoSimplificado && widget.formaPago == 'credito') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.condicionPagoController,
                        decoration: _dec(
                          label: 'Condición de Pago (ej: 30 días)',
                          icon: Icons.schedule_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: widget.diasCreditoController,
                        keyboardType: TextInputType.number,
                        decoration: _dec(
                          label: 'Días de Crédito',
                          icon: Icons.tag,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: widget.fechaVencimientoController,
                  decoration: _dec(
                    label: 'Fecha de Vencimiento (YYYY-MM-DD)',
                    icon: Icons.event_outlined,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.isDesktop(context)) return _desktop(context);
    return _mobile(context);
  }
}
