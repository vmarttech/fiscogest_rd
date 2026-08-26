import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

class CobrarPage extends ConsumerStatefulWidget {
  const CobrarPage({super.key});
  static const String routeName = 'cobrar';

  @override
  ConsumerState<CobrarPage> createState() => _CobrarPageState();
}

class _CobrarPageState extends ConsumerState<CobrarPage> {
  @override
  Widget build(BuildContext context) {
    ref.watch(registrarVentaProvider);
    return const AppScaffold(
      title: 'Cuentas por Cobrar',
      body: Center(child: Text('Gestión de Créditos y Cobros')),
    );
  }
}
