import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_dropdown.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/features/clientes/presentation/providers/cliente_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/ventas_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/widgets/item_carrito.dart';

class _TarjetaProfesional extends StatelessWidget {
  const _TarjetaProfesional({required this.child, this.colorFondo = Colors.white});
  final Widget child;
  final Color colorFondo;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.allM,
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

class _DatoTicket extends StatelessWidget {
  const _DatoTicket({required this.etiqueta, required this.valor, required this.icono});
  final String etiqueta;
  final String valor;
  final IconData icono;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [Icon(icono, size: 14, color: AppColors.textSecondary), const SizedBox(width: 4), Text(etiqueta, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary))]),
          const SizedBox(height: 4),
          Text(valor, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _FilaCarritoProfesional extends StatelessWidget {
  const _FilaCarritoProfesional({
    required this.nombre,
    required this.cantidad,
    required this.precio,
    required this.productoId,
    required this.modificar,
    required this.eliminar,
  });
  final String nombre;
  final double cantidad;
  final double precio;
  final int productoId;
  final void Function(int, double)? modificar;
  final void Function(int)? eliminar;
  @override
  Widget build(BuildContext context) {
    final subtotal = precio * cantidad;
    return Padding(
      padding: AppSpacing.vS,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(nombre, style: AppTypography.labelMedium, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: AppSpacing.s),
          Text('RD\$ ${subtotal.toStringAsFixed(2)}', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: AppSpacing.xs),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('RD\$ ${precio.toStringAsFixed(2)} c/u', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          Row(mainAxisSize: MainAxisSize.min, children: [
            AppButton(text: '-', onPressed: modificar != null ? () => modificar!(productoId, -1.0) : null),
            const SizedBox(width: AppSpacing.s),
            Text('${cantidad.toStringAsFixed(0)}', style: AppTypography.labelMedium),
            const SizedBox(width: AppSpacing.s),
            AppButton(text: '+', onPressed: modificar != null ? () => modificar!(productoId, 1.0) : null),
          ]),
          AppButton(text: '', icon: Icons.delete_outline, onPressed: eliminar != null ? () => eliminar!(productoId) : null),
        ]),
        const Divider(height: AppSpacing.m),
      ]),
    );
  }
}

class _FilaTotal extends StatelessWidget {
  const _FilaTotal({required this.etiqueta, required this.monto, this.esResaltado = false, this.esNegativo = false});
  final String etiqueta;
  final double monto;
  final bool esResaltado;
  final bool esNegativo;
  @override
  Widget build(BuildContext context) {
    final colorTexto = esResaltado ? AppColors.primary : (esNegativo ? AppColors.error : AppColors.textPrimary);
    final estiloEtiqueta = esResaltado ? AppTypography.h4.copyWith(fontWeight: FontWeight.bold) : AppTypography.bodyMedium;
    final estiloMonto = esResaltado ? AppTypography.h3.copyWith(color: colorTexto, fontWeight: FontWeight.bold) : AppTypography.labelMedium.copyWith(color: colorTexto);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(etiqueta, style: estiloEtiqueta),
        Text('${esNegativo ? '-' : ''}RD\$ ${monto.toStringAsFixed(2)}', style: estiloMonto),
      ]),
    );
  }
}

class _ResumenTotales extends StatelessWidget {
  const _ResumenTotales({required this.subtotal, required this.descuento, required this.itbis, required this.total});
  final double subtotal;
  final double descuento;
  final double itbis;
  final double total;
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _FilaTotal(etiqueta: 'Subtotal', monto: subtotal),
      if (descuento > 0) _FilaTotal(etiqueta: 'Descuento', monto: descuento, esNegativo: true),
      _FilaTotal(etiqueta: 'ITBIS (18%)', monto: itbis),
      const Divider(height: 24, thickness: 1.5),
      _FilaTotal(etiqueta: 'TOTAL A PAGAR', monto: total, esResaltado: true),
    ]);
  }
}

class PanelCarrito extends ConsumerWidget {
  const PanelCarrito({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final padre = context.findAncestorStateOfType<VentasPageState>();
    final numeroVenta = padre?.numeroVenta ?? '';
    final clienteNombre = padre?.clienteNombre ?? 'Consumidor final';
    final clienteSeleccionadoId = padre?.clienteSeleccionadoId;
    final tipoPago = padre?.tipoPago ?? 'Efectivo';
    final carrito = padre?.carrito ?? <ItemCarrito>[];
    final subtotal = padre?.subtotal ?? 0.0;
    final itbis = padre?.itbis ?? 0.0;
    final total = padre?.total ?? 0.0;
    final seleccionarCliente = padre?.seleccionarCliente;
    final cobrar = padre?.cobrarYRegistrarVenta;
    final modificar = padre?.modificarCantidad;
    final eliminar = padre?.eliminarDelCarrito;

    final listaClientes = ref.watch(clientesControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Resumen de Venta', style: AppTypography.h4),
        const SizedBox(height: AppSpacing.xs),
        Text('Información del comprobante, cliente y artículos', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.m),

        _TarjetaProfesional(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _DatoTicket(etiqueta: 'N° VENTA', valor: numeroVenta, icono: Icons.receipt_outlined),
              _DatoTicket(etiqueta: 'CLIENTE', valor: clienteNombre, icono: Icons.person_outline),
              const _DatoTicket(etiqueta: 'FECHA', valor: 'Hoy', icono: Icons.calendar_today_outlined),
            ]),
            const SizedBox(height: AppSpacing.m),
            listaClientes.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('No se pudo cargar clientes: $e', style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
              data: (clientes) {
                final items = <DropdownMenuItem<int?>>[
                  const DropdownMenuItem<int?>(value: null, child: Text('Consumidor final')),
                  ...clientes.map((c) => DropdownMenuItem<int?>(
                    value: c.id,
                    child: Text(c.nombre),
                  )),
                ];
                return AppDropdown<int?>(
                  initialValue: clienteSeleccionadoId,
                  items: items,
                  onChanged: (valor) {
                    if (seleccionarCliente != null) {
                      final String nombre;
                      if (valor != null) {
                        nombre = clientes.firstWhere((c) => c.id == valor).nombre;
                      } else {
                        nombre = 'Consumidor final';
                      }
                      seleccionarCliente(valor, nombre);
                    }
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.m),
            AppDropdown<String>(
              initialValue: tipoPago,
              items: const [
                DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
                DropdownMenuItem(value: 'Tarjeta', child: Text('Tarjeta')),
                DropdownMenuItem(value: 'Transferencia', child: Text('Transferencia')),
                DropdownMenuItem(value: 'Crédito', child: Text('Crédito')),
              ],
              onChanged: (valor) {
                if (valor != null && padre != null) {
                  padre.tipoPago = valor;
                }
              },
            ),
          ]),
        ),
        const SizedBox(height: AppSpacing.m),

        _TarjetaProfesional(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Artículos en Carrito', style: AppTypography.labelMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xs),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16)),
                child: Text('${carrito.length} artículo${carrito.length != 1 ? 's' : ''}', style: AppTypography.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: AppSpacing.s),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: AppSpacing.m),
            if (carrito.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(children: [
                  Icon(Icons.shopping_cart_outlined, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                  const SizedBox(height: AppSpacing.s),
                  Text('No hay artículos agregados', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Selecciona productos desde el catálogo', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                ]),
              )
            else
              ...carrito.map((ItemCarrito item) => _FilaCarritoProfesional(
                    nombre: item.producto.nombre,
                    cantidad: item.cantidad,
                    precio: item.precio,
                    productoId: item.producto.id!,
                    modificar: modificar,
                    eliminar: eliminar,
                  )),
          ]),
        ),
        const SizedBox(height: AppSpacing.m),

        _TarjetaProfesional(
          colorFondo: const Color(0xFFF8F9FA),
          child: _ResumenTotales(subtotal: subtotal, descuento: 0.0, itbis: itbis, total: total),
        ),
        const SizedBox(height: AppSpacing.m),

        const Wrap(alignment: WrapAlignment.center, spacing: AppSpacing.s, runSpacing: AppSpacing.s, children: [
          AppButton(text: '% Descuento', icon: Icons.percent, onPressed: null),
          AppButton(text: 'Cotización', icon: Icons.description_outlined, onPressed: null),
          AppButton(text: 'Apartado', icon: Icons.bookmark_border, onPressed: null),
          AppButton(text: 'Nota Crédito', icon: Icons.receipt_long, onPressed: null),
        ]),
        const SizedBox(height: AppSpacing.l),

        Container(
          padding: AppSpacing.allM,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(children: [
            Text('TOTAL A PAGAR', style: AppTypography.labelSmall.copyWith(color: Colors.white70, letterSpacing: 1.2)),
            const SizedBox(height: AppSpacing.xs),
            Text('RD\$ ${total.toStringAsFixed(2)}', style: AppTypography.h1.copyWith(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: AppSpacing.m),
            SizedBox(width: double.infinity, child: AppButton(text: 'COBRAR Y CONFIRMAR', icon: Icons.payment, onPressed: cobrar)),
          ]),
        ),
      ],
    );
  }
}
