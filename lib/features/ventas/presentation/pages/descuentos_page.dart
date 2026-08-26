import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

class DescuentosPage extends ConsumerStatefulWidget {
  const DescuentosPage({super.key});
  static const String routeName = 'descuentos';

  @override
  ConsumerState<DescuentosPage> createState() => _DescuentosPageState();
}

class _DescuentosPageState extends ConsumerState<DescuentosPage> {
  @override
  Widget build(BuildContext context) {
    ref.watch(registrarVentaProvider);
    return const AppScaffold(
      title: 'Descuentos',
      body: Center(child: Text('Configuración y Listado de Descuentos')),
    );
  }
}
