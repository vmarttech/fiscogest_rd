import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/features/impuestos/presentation/providers/impuesto_providers.dart';
import 'package:fiscogest_rd/features/impuestos/domain/entities/impuesto_entity.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';

class ImpuestosPage extends ConsumerStatefulWidget {
  const ImpuestosPage({super.key});

  static const String routeName = 'impuestos';

  @override
  ConsumerState<ImpuestosPage> createState() => _ImpuestosPageState();
}

class _ImpuestosPageState extends ConsumerState<ImpuestosPage> {
  final TextEditingController _searchController = TextEditingController();
  String _filtroBusqueda = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    final impuestosAsync = ref.watch(impuestoControllerProvider);

    return AppScaffold(
      title: 'IMPUESTOS',
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header + CTA

            // Declaraciones DGII (606 / 607) — viven en Impuestos, no en métricas
            Padding(
              padding: EdgeInsets.fromLTRB(
                mobile ? 16 : 24,
                16,
                mobile ? 16 : 24,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Declaraciones DGII',
                    style: AppTypography.h4.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Base para declaración 606 (compras) y 607 (ventas).',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, c) {
                      final wide = c.maxWidth > 520;
                      final cards = [
                        _DgiiCard(
                          codigo: '606',
                          titulo: 'Compras DGII',
                          subtitulo: 'Base para declaración 606',
                          onTap: () => context.push('/reports/detalle/606'),
                        ),
                        _DgiiCard(
                          codigo: '607',
                          titulo: 'Ventas DGII',
                          subtitulo: 'Base para declaración 607',
                          onTap: () => context.push('/reports/detalle/607'),
                        ),
                      ];
                      if (wide) {
                        return Row(
                          children: [
                            Expanded(child: cards[0]),
                            const SizedBox(width: 12),
                            Expanded(child: cards[1]),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          cards[0],
                          const SizedBox(height: 10),
                          cards[1],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                mobile ? 16 : 24,
                mobile ? 12 : 16,
                mobile ? 16 : 24,
                0,
              ),
              child: mobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Configuración tributaria',
                          style: AppTypography.h4.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tasas, tipos y exenciones',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () => _mostrarSheetRegistro(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: const Text(
                              'NUEVO IMPUESTO',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Configuración tributaria e ITBIS',
                                style: AppTypography.h4.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Administración de tasas, tipos globales y exenciones.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: () => _mostrarSheetRegistro(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text(
                              'Nuevo impuesto',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            // Buscador
            Padding(
              padding: EdgeInsets.fromLTRB(
                mobile ? 16 : 24,
                14,
                mobile ? 16 : 24,
                8,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) =>
                    setState(() => _filtroBusqueda = v.trim().toLowerCase()),
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, tipo o descripción…',
                  hintStyle: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),

            // Lista
            Expanded(
              child: impuestosAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Error: $e',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
                data: (impuestos) {
                  final filtrados = impuestos.where((i) {
                    if (_filtroBusqueda.isEmpty) return true;
                    return i.nombre.toLowerCase().contains(_filtroBusqueda) ||
                        i.tipo.toLowerCase().contains(_filtroBusqueda) ||
                        i.descripcion.toLowerCase().contains(_filtroBusqueda);
                  }).toList();

                  if (filtrados.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calculate_outlined,
                              size: 48,
                              color: AppColors.grey300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Sin impuestos',
                              style: AppTypography.h4.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _filtroBusqueda.isEmpty
                                  ? 'Crea el primero con “Nuevo impuesto”.'
                                  : 'No hay coincidencias con la búsqueda.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      mobile ? 16 : 24,
                      4,
                      mobile ? 16 : 24,
                      24,
                    ),
                    itemCount: filtrados.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final impuesto = filtrados[i];
                      return _ImpuestoCard(
                        impuesto: impuesto,
                        mobile: mobile,
                        onEdit: () => _mostrarSheetRegistro(
                          context,
                          impuestoToEdit: impuesto,
                        ),
                        onDelete: () => _confirmarEliminar(impuesto),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarEliminar(ImpuestoEntity impuesto) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Eliminar impuesto',
          style: AppTypography.h4.copyWith(fontWeight: FontWeight.w800),
        ),
        content: Text(
          '¿Eliminar “${impuesto.nombre}”?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true && impuesto.id != null && mounted) {
      await ref.read(impuestoControllerProvider.notifier).eliminar(impuesto.id!);
    }
  }

  void _mostrarSheetRegistro(
    BuildContext context, {
    ImpuestoEntity? impuestoToEdit,
  }) {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(
      text: impuestoToEdit?.nombre ?? '',
    );
    final porcentajeController = TextEditingController(
      text: impuestoToEdit != null ? impuestoToEdit.porcentaje.toString() : '',
    );
    final descripcionController = TextEditingController(
      text: impuestoToEdit?.descripcion ?? '',
    );
    final codigoController = TextEditingController(
      text: impuestoToEdit?.codigo ?? '',
    );
    String tipoSeleccionado = impuestoToEdit?.tipo ?? 'ITBIS';
    bool esExento = impuestoToEdit?.esExento ?? false;
    bool esDefault = impuestoToEdit?.esDefault ?? false;
    bool activo = impuestoToEdit?.activo ?? true;
    final isEditing = impuestoToEdit != null;
    final mobile = AppBreakpoints.isMobile(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
            return Padding(
              padding: EdgeInsets.only(bottom: bottom),
              child: Container(
                margin: EdgeInsets.fromLTRB(
                  mobile ? 12 : 24,
                  0,
                  mobile ? 12 : 24,
                  mobile ? 12 : 24,
                ),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          isEditing ? 'Editar impuesto' : 'Nuevo impuesto',
                          style: AppTypography.h4.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: nombreController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _inputDeco('Nombre (ej. ITBIS 18%)'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Ingrese el nombre'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: tipoSeleccionado,
                          decoration: _inputDeco('Tipo'),
                          items: ['ITBIS', 'Exento', 'Adicional', 'Selectivo']
                              .map(
                                (t) =>
                                    DropdownMenuItem(value: t, child: Text(t)),
                              )
                              .toList(),
                          onChanged: (val) {
                            setModal(() {
                              tipoSeleccionado = val!;
                              if (tipoSeleccionado == 'Exento') {
                                esExento = true;
                                porcentajeController.text = '0';
                              } else {
                                esExento = false;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: porcentajeController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _inputDeco('Porcentaje (%)'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Ingrese el porcentaje';
                            }
                            final n = double.tryParse(v.trim());
                            if (n == null || n < 0) {
                              return 'Valor inválido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Exento de impuesto',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          value: esExento,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) {
                            setModal(() {
                              esExento = val;
                              if (esExento) porcentajeController.text = '0';
                            });
                          },
                        ),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Predeterminado para ventas'),
                          subtitle: const Text('Solo un ITBIS puede ser el de la caja'),
                          value: esDefault,
                          onChanged: tipoSeleccionado == 'ITBIS'
                              ? (v) => setModal(() => esDefault = v)
                              : null,
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Activo'),
                          value: activo,
                          onChanged: (v) => setModal(() => activo = v),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: codigoController,
                          decoration: _inputDeco('Código (ej. ITBIS-18)'),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: descripcionController,
                          maxLines: 2,
                          decoration: _inputDeco('Descripción / base legal'),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              if (!formKey.currentState!.validate()) return;
                              try {
                                final impuesto = ImpuestoEntity(
                                  id: impuestoToEdit?.id,
                                  codigo: codigoController.text.trim(),
                                  nombre: nombreController.text.trim(),
                                  esDefault: tipoSeleccionado == 'ITBIS' && esDefault,
                                  activo: activo,
                                  porcentaje: double.parse(
                                    porcentajeController.text.trim(),
                                  ),
                                  tipo: tipoSeleccionado,
                                  esExento: esExento,
                                  descripcion: descripcionController.text
                                      .trim(),
                                );
                                final notifier = ref.read(
                                  impuestoControllerProvider.notifier,
                                );
                                if (isEditing) {
                                  notifier.actualizar(impuesto);
                                } else {
                                  notifier.guardar(impuesto);
                                }
                                Navigator.pop(ctx);
                              } catch (e) {
                                FiscoGestNotifications.show(
                                  SnackBar(
                                    content: Text(
                                      e.toString().replaceAll(
                                        'Exception: ',
                                        '',
                                      ),
                                    ),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            child: Text(
                              isEditing ? 'ACTUALIZAR' : 'GUARDAR',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Cancelar',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }
}

class _ImpuestoCard extends StatelessWidget {
  const _ImpuestoCard({
    required this.impuesto,
    required this.mobile,
    required this.onEdit,
    required this.onDelete,
  });

  final ImpuestoEntity impuesto;
  final bool mobile;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final exento = impuesto.esExento;
    final pctColor = exento ? AppColors.error : AppColors.primary;
    final badgeBg = exento
        ? AppColors.error.withValues(alpha: 0.12)
        : AppColors.info.withValues(alpha: 0.12);
    final badgeFg = exento ? AppColors.error : AppColors.info;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: mobile ? 12 : 14,
            vertical: mobile ? 12 : 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: mobile ? 44 : 48,
                height: mobile ? 44 : 48,
                decoration: BoxDecoration(
                  color: pctColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${impuesto.porcentaje.toStringAsFixed(impuesto.porcentaje == impuesto.porcentaje.roundToDouble() ? 0 : 1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: mobile ? 13 : 14,
                    color: pctColor,
                  ),
                ),
              ),
              SizedBox(width: mobile ? 10 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            impuesto.nombre,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: mobile ? 14 : 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            impuesto.tipo,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: badgeFg,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      impuesto.descripcion.isEmpty
                          ? 'Sin descripción'
                          : impuesto.descripcion,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Editar',
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Eliminar',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DgiiCard extends StatelessWidget {
  const _DgiiCard({
    required this.codigo,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });
  final String codigo;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFBF1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_outlined, color: Color(0xFF0F766E)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            titulo,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCCFBF1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            codigo,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Abrir →',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
