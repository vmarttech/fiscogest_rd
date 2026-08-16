import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';

class ListaCotizacionesPage extends StatelessWidget {
  const ListaCotizacionesPage({super.key});

  static const routeName = 'lista-cotizaciones';

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Cotizaciones',
      body: Center(
        child: Text('Listado de Cotizaciones — En construcción'),
      ),
    );
  }
}
