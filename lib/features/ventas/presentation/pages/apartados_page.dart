import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';

class ApartadosPage extends StatelessWidget {

  const ApartadosPage({super.key});
  static const routeName = 'apartados';

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(title: 'Apartados', body: SizedBox.shrink());
  }
}
