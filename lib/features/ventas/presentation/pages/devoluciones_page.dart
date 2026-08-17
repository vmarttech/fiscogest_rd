import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';

class DevolucionesPage extends StatelessWidget {

  const DevolucionesPage({super.key});
  static const routeName = 'devoluciones';

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(title: 'Devoluciones', body: SizedBox.shrink());
  }
}
