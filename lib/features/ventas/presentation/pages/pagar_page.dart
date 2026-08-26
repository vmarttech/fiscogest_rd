import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

class PagarPage extends ConsumerStatefulWidget {
  const PagarPage({super.key});
  static const routeName = 'pagar';

  @override
  ConsumerState<PagarPage> createState() => _PagarPageState();
}

class _PagarPageState extends ConsumerState<PagarPage> {
  @override
  Widget build(BuildContext context) {
    ref.watch(registrarVentaProvider);
    return const AppScaffold(
      title: 'Cuentas por Pagar',
      body: Center(child: Text('Gestión de Pagos y Compromisos')),
    );
  }
}
