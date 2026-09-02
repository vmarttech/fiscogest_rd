import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

class OfertasPage extends ConsumerStatefulWidget {
  const OfertasPage({super.key});
  static const routeName = 'ofertas';
  @override
  ConsumerState<OfertasPage> createState() => _OfertasPageState();
}

class _OfertasPageState extends ConsumerState<OfertasPage> {
  @override
  Widget build(BuildContext context) {
    ref.watch(registrarVentaProvider);
    return const AppScaffold(
      title: 'Ofertas y Promociones',
      body: SafeArea(
        bottom: true,
        child: Padding(
          padding: AppLayout.pantallaPadding,
          child: Center(
            child: Text('Gestión de Ofertas y Promociones Comerciales'),
          ),
        ),
      ),
    );
  }
}
