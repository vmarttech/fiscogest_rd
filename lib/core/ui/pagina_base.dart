import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';

/// ✅ ENVOLTURA ESTÁNDAR PARA TODAS LAS PANTALLAS
/// Trae automáticamente: menú lateral, AppBar, ancho límite,
/// márgenes uniformes y scroll adaptable.
/// Basado en la estructura de NuevoProductoPage.
class PaginaBase extends StatelessWidget {

  const PaginaBase({
    super.key,
    required this.cuerpo,
    this.titulo,
    this.accionesAppBar,
  });
  final Widget cuerpo;
  final String? titulo;
  final List<Widget>? accionesAppBar;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: Text(titulo ?? ''),
        actions: accionesAppBar,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppLayout.pantallaPadding,
          child: cuerpo,
        ),
      ),
    );
  }
}
