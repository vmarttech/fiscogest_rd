import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

class DevolucionesPage extends ConsumerStatefulWidget {
  const DevolucionesPage({super.key});
  static const String routeName = 'devoluciones';
  @override
  ConsumerState<DevolucionesPage> createState() => _DevolucionesPageState();
}

class _DevolucionesPageState extends ConsumerState<DevolucionesPage> {
  @override
  Widget build(BuildContext context) {
    
    ref.watch(registrarVentaProvider);
    return const AppScaffold(
      backgroundColor: AppColors.pageBackground,
      // design system

      title: 'Devoluciones',
      body: SafeArea(
        bottom: true,
        child: Padding(
          padding: AppLayout.pantallaPadding,
          child: SizedBox.shrink(),
        ),
      ),
    );
  }
}
