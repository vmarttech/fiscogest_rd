import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/navigation/safe_back.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/widgets/historial_ventas.dart';

/// Historial solo de ventas. Ruta: /ventas/historial
class VentasHistorialPage extends ConsumerWidget {
  const VentasHistorialPage({super.key});

  static const String routeName = 'historial-ventas';
  static const String path = '/ventas/historial';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desktop = AppBreakpoints.isDesktop(context);
    return AppScaffold(
      title: 'HISTORIAL DE VENTAS',
      showAppBar: !desktop,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => safeBack(context, fallback: '/ventas'),
      ),
      body: const HistorialVentas(standalone: true),
    );
  }
}
