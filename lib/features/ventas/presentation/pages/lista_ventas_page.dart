import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';

class ListaVentasPage extends StatelessWidget {
  const ListaVentasPage({super.key});

  static const routeName = 'lista-ventas';

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Ventas',
      body: Center(
        child: Text('Listado de Ventas — En construcción'),
      ),
    );
  }
}
