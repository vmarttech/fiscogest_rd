import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';

class ListaDevolucionesPage extends StatelessWidget {
  const ListaDevolucionesPage({super.key});

  static const routeName = 'lista-devoluciones';

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Devoluciones',
      body: Center(
        child: Text('Listado de Devoluciones — En construcción'),
      ),
    );
  }
}
