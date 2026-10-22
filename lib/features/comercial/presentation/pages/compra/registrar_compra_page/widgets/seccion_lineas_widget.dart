import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/scanner/barcode_scanner_page.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/registrar_compra_page/widgets/tipos_linea.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/registrar_compra_page/widgets/linea_producto_widget.dart';

class SeccionLineasWidget extends StatelessWidget {
  const SeccionLineasWidget({
    super.key,
    required this.lineas,
    required this.controladores,
    required this.onAgregarLinea,
    required this.onEliminarLinea,
    required this.onSeleccionarProducto,
    required this.onValorCambiado,
    required this.esPequena,
    required this.filaResponsiva,
    this.modoSimplificado = false,
    this.onBuscarProducto,
  });

  final List<DetalleLinea> lineas;
  final List<ControladoresLinea> controladores;
  final VoidCallback onAgregarLinea;
  final void Function(int) onEliminarLinea;
  final void Function(int) onSeleccionarProducto;
  final void Function(int, String) onValorCambiado;
  final bool esPequena;
  final Widget Function({required Widget child1, required Widget child2})
      filaResponsiva;
  final bool modoSimplificado;
  final ValueChanged<String>? onBuscarProducto;

  @override
  Widget build(BuildContext context) {
    if (!AppBreakpoints.isDesktop(context)) {
      return _buildMobile(context);
    }
    return _buildDesktop(context);
  }

  Widget _buildMobile(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    return AppCard(
      borderColor: AppColors.border,
      padding: AppSpacing.allM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: mobile
                ? SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: 'Agregar producto',
                      icon: Icons.add,
                      onPressed: onAgregarLinea,
                    ),
                  )
                : AppButton(
                    text: 'Agregar',
                    icon: Icons.add,
                    onPressed: onAgregarLinea,
                    width: 140,
                  ),
          ),
          AppLayout.vS,
          if (lineas.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: mobile ? 20 : 28),
              child: Center(
                child: Text(
                  'No hay productos. Presione "Agregar" para iniciar.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ..._lineasWidgets(),
        ],
      ),
    );
  }

  List<Widget> _lineasWidgets() {
    return lineas.asMap().entries.map((entry) {
      final index = entry.key;
      return LineaProductoWidget(
        index: index,
        linea: lineas[index],
        ctrl: controladores[index],
        onEliminar: () => onEliminarLinea(index),
        onSeleccionarProducto: () => onSeleccionarProducto(index),
        onCantidadChanged: (_) => onValorCambiado(index, 'cantidad'),
        onCostoChanged: (_) => onValorCambiado(index, 'costo'),
        onFleteChanged: (_) => onValorCambiado(index, 'flete'),
        onSeguroChanged: (_) => onValorCambiado(index, 'seguro'),
        onArancelesChanged: (_) => onValorCambiado(index, 'aranceles'),
        onGastosChanged: (_) => onValorCambiado(index, 'gastos'),
        onDescuentoChanged: (_) => onValorCambiado(index, 'descuento'),
        esPequena: esPequena,
        filaResponsiva: filaResponsiva,
        modoSimplificado: modoSimplificado,
      );
    }).toList();
  }

  Widget _buildDesktop(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // card-title
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.only(bottom: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFF0F4F8), width: 2),
              ),
            ),
            child: const Text(
              'PRODUCTOS AGREGADOS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
          // product-search-header
          Row(
            children: [
              Expanded(
                child: _BuscadorProductoCompra(
                  onBuscarProducto: onBuscarProducto,
                  onAgregarLinea: onAgregarLinea,
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onAgregarLinea,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar Producto'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF127369),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (lineas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  'No hay productos. Presione "Agregar Producto" para iniciar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF666666),
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else ...[
            // thead
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFEDF2F7), width: 2),
                ),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Producto',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Cantidad',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Precio Unit.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'ITBIS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            ..._lineasWidgets(),
          ],
        ],
      ),
    );
  }
}

class _BuscadorProductoCompra extends StatefulWidget {
  const _BuscadorProductoCompra({
    required this.onBuscarProducto,
    required this.onAgregarLinea,
  });
  final void Function(String)? onBuscarProducto;
  final VoidCallback onAgregarLinea;
  @override
  State<_BuscadorProductoCompra> createState() =>
      _BuscadorProductoCompraState();
}

class _BuscadorProductoCompraState extends State<_BuscadorProductoCompra> {
  final _ctrl = TextEditingController();
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _escanear() async {
    final codigo = await BarcodeScannerPage.abrir(
      context,
      titulo: 'Escanear producto',
      subtitulo: 'Centre el código de barras del producto',
    );
    if (!mounted || codigo == null || codigo.trim().isEmpty) return;
    _ctrl.text = codigo.trim();
    widget.onBuscarProducto?.call(codigo.trim());
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Nombre, SKU o código de barras…',
        hintStyle: const TextStyle(fontWeight: FontWeight.w600),
        prefixIcon: const Icon(Icons.search, color: Color(0xFFA0AEC0)),
        suffixIcon: IconButton(
          tooltip: 'Escanear código de barras',
          icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF2563EB)),
          onPressed: _escanear,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
      ),
      // Solo Enter o escáner abren el selector (evita crash por diálogos apilados).
      onSubmitted: (q) {
        final query = q.trim();
        if (query.isEmpty) {
          widget.onAgregarLinea();
          return;
        }
        widget.onBuscarProducto?.call(query);
      },
    );
  }
}
