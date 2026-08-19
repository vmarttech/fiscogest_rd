import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';

/// PLANTILLA BASE — PANTALLA ESTÁNDAR FiscoGest RD
/// Estructura segura: LayoutBuilder → Expanded → SingleChildScrollView
/// Responsive automático: escritorio 2 columnas / móvil 1 columna
class PantallaBaseTemplate extends StatefulWidget {
  const PantallaBaseTemplate({super.key});
  static const String routeName = '/ruta-de-pantalla';

  @override
  State<PantallaBaseTemplate> createState() => _PantallaBaseTemplateState();
}

class _PantallaBaseTemplateState extends State<PantallaBaseTemplate> {
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Título de pantalla',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final pantallaAncha = constraints.maxWidth >= 720;
                return pantallaAncha ? _vistaEscritorio() : _vistaMovil();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _vistaEscritorio() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: AppSpacing.allM,
            child: _columnaIzquierda(),
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: AppSpacing.allM,
            child: _columnaDerecha(),
          ),
        ),
      ],
    );
  }

  Widget _vistaMovil() {
    return SingleChildScrollView(
      padding: AppSpacing.allM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _columnaIzquierda(),
          const SizedBox(height: AppSpacing.m),
          _columnaDerecha(),
        ],
      ),
    );
  }

  Widget _columnaIzquierda() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Contenido principal — reemplazar'),
      ],
    );
  }

  Widget _columnaDerecha() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Panel lateral — reemplazar'),
      ],
    );
  }
}
