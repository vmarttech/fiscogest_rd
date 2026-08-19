import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/ventas_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/widgets/panel_productos.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/widgets/panel_carrito.dart';

class VistaEscritorio extends ConsumerWidget {
  const VistaEscritorio({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: SingleChildScrollView(padding: AppSpacing.allM, child: PanelProductos())),
        SizedBox(width: AppSpacing.m),
        Expanded(flex: 5, child: SingleChildScrollView(padding: AppSpacing.allM, child: PanelCarrito())),
      ],
    );
  }
}

class VistaMovil extends ConsumerStatefulWidget {
  const VistaMovil({super.key});
  @override
  ConsumerState<VistaMovil> createState() => VistaMovilState();
}

class VistaMovilState extends ConsumerState<VistaMovil> {
  VentasPageState? get padre => context.findAncestorStateOfType<VentasPageState>();

  @override
  Widget build(BuildContext context) {
    final cantidad = padre?.carrito.length ?? 0;
    final total = padre?.total ?? 0.0;

    return Stack(
      children: [
        const SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.m, AppSpacing.m, 80),
          child: PanelProductos(esMovil: true),
        ),
        Positioned(
          left: AppSpacing.m,
          right: AppSpacing.m,
          bottom: AppSpacing.m,
          child: AppButton(
            text: 'Ver carrito ($cantidad) • RD\$ ${total.toStringAsFixed(2)}',
            icon: Icons.shopping_cart_outlined,
            onPressed: _abrirCarrito,
          ),
        ),
      ],
    );
  }

  void _abrirCarrito() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          padding: AppSpacing.allM,
          child: SingleChildScrollView(controller: controller, child: const PanelCarrito()),
        ),
      ),
    );
  }
}
