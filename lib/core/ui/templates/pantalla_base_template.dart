import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';

///== PLANTILLA BASE — PANTALLA ESTÁNDAR FiscoGest RD ==
/// Cumplimiento automático:
/// ✅ LayoutBuilder → detección REAL de espacio disponible
/// ✅ Estructura segura → Row → Expanded → SingleChildScrollView
/// ✅ Sin conflicto "alto infinito" → Expanded NUNCA dentro de scrollable
/// ✅ AppSpacing / AppTypography → CERO valores manuales
/// ✅ Responsive → escritorio 2 columnas / móvil 1 columna
/// ✅ Migración gradual → NO toca lógica, modelos ni providers

class PantallaBaseTemplate extends StatefulWidget {
  const PantallaBaseTemplate({super.key});
  static const String routeName = '/ruta-de-tu-pantalla';
  @override
  State<PantallaBaseTemplate> createState() => _PantallaBaseTemplateState();
}

class _PantallaBaseTemplateState extends State<PantallaBaseTemplate> {
  // === TUS VARIABLES DE ESTADO AQUÍ ===
  // final TextEditingController _buscador = TextEditingController();

  @override
  void dispose() {
    // _buscador.dispose(); // Libera tus controladores aquí
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Título de tu pantalla',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === PASO 1: LayoutBuilder → detecta espacio REAL ===
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final esPantallaAncha = constraints.maxWidth >= 720;
                return _buildCuerpo(esPantallaAncha);
              },
            ),
          ),
        ],
      ),
    );
  }

  // === PASO 2: Estructura SEGURA ===
  Widget _buildCuerpo(bool esPantallaAncha) {
    if (esPantallaAncha) {
      // ESCRITORIO: Row → Expanded → SingleChildScrollView
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              padding: AppSpacing.allM,
              child: _buildColumnaIzquierda(),
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              padding: AppSpacing.allM,
              child: _buildColumnaDerecha(),
            ),
          ),
        ],
      );
    }
    // MÓVIL: Un solo scroll vertical
    return SingleChildScrollView(
      padding: AppSpacing.allM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildColumnaIzquierda(),
          const SizedBox(height: AppSpacing.m),
          _buildColumnaDerecha(),
        ],
      ),
    );
  }

  // === COLUMNA IZQUIERDA ===
  Widget _buildColumnaIzquierda() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Contenido Izquierda', style: AppTypography.labelMedium),
        const SizedBox(height: AppSpacing.s),
        // === Tus widgets aquí: formularios, listas, etc. ===
        Container(
          padding: AppSpacing.allM,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Ejemplo de contenido',
            style: AppTypography.bodyMedium,
          ),
        ),
      ],
    );
  }

  // === COLUMNA DERECHA ===
  Widget _buildColumnaDerecha() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Contenido Derecha', style: AppTypography.labelMedium),
        const SizedBox(height: AppSpacing.s),
        // === Tus widgets aquí: resúmenes, totales, acciones ===
        Container(
          padding: AppSpacing.allM,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Ejemplo de contenido',
            style: AppTypography.bodyMedium,
          ),
        ),
      ],
    );
  }
}
