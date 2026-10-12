import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:go_router/go_router.dart';

class DevolucionesPage extends ConsumerStatefulWidget {
  const DevolucionesPage({super.key});
  static const String routeName = 'devoluciones';
  @override
  ConsumerState<DevolucionesPage> createState() => _DevolucionesPageState();
}

class _DevolucionesPageState extends ConsumerState<DevolucionesPage> {
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.pageBackground,
      title: 'Devoluciones',
      body: SafeArea(
        bottom: true,
        child: Padding(
          padding: AppLayout.pantallaPadding,
          child: ListView(children: const [_AvisoDevolucion()]),
        ),
      ),
    );
  }
}

class _AvisoDevolucion extends StatelessWidget {
  const _AvisoDevolucion();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Una devolucion de factura se emite como nota de credito. '
          'No borra la factura.',
        ),
        const SizedBox(height: 12),
        const Text(
          'Si esa factura ya es un e-CF aceptado, la nota es tipo 34. '
          'Lleva el e-NCF original, devuelve la mercancia al inventario '
          'y anula el credito si la venta fue a credito.',
        ),
        const SizedBox(height: 12),
        const Text(
          'Un e-CF aceptado por la DGII no se anula desde aqui. '
          'La via correcta es la nota de credito.',
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => context.push('/sales/emitir-nc'),
          child: const Text('Emitir nota de credito'),
        ),
      ],
    );
  }
}
