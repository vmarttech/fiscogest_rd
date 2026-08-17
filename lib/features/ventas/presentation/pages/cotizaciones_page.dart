import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';

class CotizacionesPage extends StatelessWidget {

  const CotizacionesPage({super.key});
  static const routeName = 'cotizaciones';

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(title: 'Cotizaciones', body: SizedBox.shrink());
  }
}
