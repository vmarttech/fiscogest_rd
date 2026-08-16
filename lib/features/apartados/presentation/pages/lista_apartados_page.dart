import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';

class ListaApartadosPage extends StatelessWidget {
  const ListaApartadosPage({super.key});

  static const routeName = 'lista-apartados';

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Apartados',
      body: Center(
        child: Text('Listado de Apartados — En construcción'),
      ),
    );
  }
}
