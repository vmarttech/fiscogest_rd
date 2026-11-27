import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/core/i18n/servicio_idioma.dart';
import 'package:fiscogest_rd/features/nomina/domain/entities/empleado.dart';
import 'package:fiscogest_rd/features/nomina/presentation/providers/nomina_providers.dart';

class NominaPage extends ConsumerStatefulWidget {
  const NominaPage({super.key});

  static const String routeName = 'nomina';
  static const String path = '/nomina';

  @override
  ConsumerState<NominaPage> createState() => _NominaPageState();
}

class _NominaPageState extends ConsumerState<NominaPage> {
  String _q = '';

  /// null=todos, true=activos, false=inactivos
  bool? _filtroActivo;

  Future<void> _exportarCsv(List<Empleado> empleados) async {
    final buf = StringBuffer();
    buf.writeln(
      'id,nombre,apellido,cedula,telefono,email,cargo,salario_base,activo,fecha_ingreso,banco,tipo_cuenta,numero_cuenta,forma_pago',
    );
    for (final e in empleados) {
      final fi = e.fechaIngreso?.toIso8601String() ?? '';
      buf.writeln(
        '${e.id},${_csv(e.nombre)},${_csv(e.apellido)},${_csv(e.cedula)},'
        '${_csv(e.telefono)},${_csv(e.email)},${_csv(e.cargo)},'
        '${e.salarioBase},${e.activo},$fi,'
        '${_csv(e.banco)},${_csv(e.tipoCuenta)},${_csv(e.numeroCuenta)},${_csv(e.formaPago)}',
      );
    }
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/empleados_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsString(buf.toString());
    await Share.shareXFiles([
      XFile(file.path, mimeType: 'text/csv', name: 'empleados.csv'),
    ]);
  }

  String _csv(String? v) {
    final s = (v ?? '').replaceAll('"', '""');
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"$s"';
    }
    return s;
  }

  void _toast(String msg, {bool error = false}) {
    FiscoGestNotifications.show(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  Widget _accesoModulo({
    required String titulo,
    required String descripcion,
    required IconData icono,
    required Color acento,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: acento.withValues(alpha: 0.18)),
            gradient: LinearGradient(
              colors: [AppColors.white, acento.withValues(alpha: 0.045)],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: acento.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icono, color: acento),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      titulo,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      descripcion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: acento, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirForm([Empleado? existing]) async {
    final Widget form = _EmpleadoFormSheet(empleado: existing);
    final desktop = AppBreakpoints.isDesktop(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final size = MediaQuery.sizeOf(ctx);
        final dialogWidth = desktop
            ? 560.0
            : (size.width - 40).clamp(280.0, 560.0).toDouble();
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: desktop ? 24 : 20,
            vertical: desktop ? 28 : 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: SizedBox(
            width: dialogWidth,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: size.height * (desktop ? 0.68 : 0.70),
              ),
              child: form,
            ),
          ),
        );
      },
    );
    if (ok == true && mounted) {
      ref.invalidate(empleadosListaProvider);
    }
  }

  Future<void> _confirmarEliminar(Empleado e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_remove_outlined,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Eliminar empleado',
                  style: AppTypography.h4.copyWith(fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '¿Eliminar a ${e.nombreCompleto}?',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Eliminar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok == true) {
      await ref.read(empleadoRepositoryProvider).eliminar(e.id!);
      ref.invalidate(empleadosListaProvider);
      if (mounted) {
        _toast('Empleado eliminado');
      }
    }
  }

  Widget _botonNuevo({bool desktop = false}) => FilledButton.icon(
    onPressed: () => _abrirForm(),
    icon: const Icon(Icons.person_add_alt_1_rounded, size: 19),
    label: const Text('Nuevo empleado'),
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF3267D6),
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: desktop ? 18 : 12,
        vertical: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      elevation: 2,
    ),
  );

  Future<void> _exportarActual() async {
    final lista = await ref.read(empleadosListaProvider.future);
    await _exportarCsv(lista);
  }

  Widget _botonExportar() => IconButton.filled(
    tooltip: 'Exportar CSV',
    onPressed: _exportarActual,
    icon: const Icon(Icons.upload_file_outlined),
    style: IconButton.styleFrom(
      backgroundColor: const Color(0xFFD7193F),
      foregroundColor: Colors.white,
      hoverColor: const Color(0xFFB51232),
      disabledBackgroundColor: const Color(0xFFD7193F).withValues(alpha: 0.45),
      disabledForegroundColor: Colors.white70,
    ),
  );

  Widget _tarjetaTotal(double total, int activos) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF17243A).withValues(alpha: 0.055),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Total nómina mensual',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatRd(total),
            style: AppTypography.h2.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
        ),
        const SizedBox(height: 7),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              '$activos ${activos == 1 ? 'colaborador activo' : 'colaboradores activos'}',
              style: AppTypography.labelSmallSemiBold.copyWith(
                color: AppColors.grey700,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _tarjetasAcceso(double total, int activos) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1000
          ? 3
          : constraints.maxWidth >= 640
          ? 2
          : 1;
      final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 10,
        children: [
          SizedBox(
            width: width,
            child: _accesoModulo(
              titulo: 'Planillas',
              descripcion: 'Generar, cerrar y pagar la nómina del periodo',
              icono: Icons.calendar_month_outlined,
              acento: const Color(0xFF496DD5),
              onTap: () => context.push('/nomina/planillas'),
            ),
          ),
          SizedBox(
            width: width,
            child: _accesoModulo(
              titulo: 'Prestaciones laborales',
              descripcion: 'Preaviso, cesantía, vacaciones y regalía',
              icono: Icons.description_outlined,
              acento: const Color(0xFFB04E79),
              onTap: () => context.push('/nomina/prestaciones'),
            ),
          ),
          SizedBox(width: width, child: _tarjetaTotal(total, activos)),
        ],
      );
    },
  );

  Widget _encabezado(bool desktop) {
    if (!desktop) {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Gestión de colaboradores, pagos y prestaciones',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: _botonNuevo()),
              ],
            );
          }
          return Row(
            children: [
              const Expanded(
                child: Text(
                  'Gestión de colaboradores, pagos y prestaciones',
                  style: AppTypography.bodySmall,
                ),
              ),
              const SizedBox(width: 8),
              _botonNuevo(),
            ],
          );
        },
      );
    }
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nómina',
                style: AppTypography.h2.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Gestión de colaboradores, pagos y prestaciones',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _botonExportar(),
        const SizedBox(width: 8),
        _botonNuevo(desktop: true),
      ],
    );
  }

  Widget _filtros(int total, int activos, int inactivos) {
    Widget chip(String label, int count, bool? value) {
      final selected = _filtroActivo == value;
      return ChoiceChip(
        label: Text('$label ($count)'),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => setState(() => _filtroActivo = value),
        backgroundColor: AppColors.grey50,
        selectedColor: const Color(0xFFE8F0FF),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: selected ? const Color(0xFF245CC5) : AppColors.grey700,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
        side: BorderSide(
          color: selected ? const Color(0xFFCBDCFF) : AppColors.border,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('Todos', total, null),
        chip('Activos', activos, true),
        chip('Inactivos', inactivos, false),
      ],
    );
  }

  Widget _accionesEmpleado(Empleado empleado) => PopupMenuButton<String>(
    tooltip: 'Acciones',
    icon: const Icon(Icons.more_horiz_rounded),
    onSelected: (accion) {
      switch (accion) {
        case 'editar':
          _abrirForm(empleado);
          break;
        case 'prestaciones':
          if (empleado.id != null) {
            context.push('/nomina/prestaciones?empleadoId=${empleado.id}');
          }
          break;
        case 'eliminar':
          _confirmarEliminar(empleado);
          break;
      }
    },
    itemBuilder: (_) => const [
      PopupMenuItem(value: 'editar', child: Text('Editar empleado')),
      PopupMenuItem(
        value: 'prestaciones',
        child: Text('Calcular prestaciones'),
      ),
      PopupMenuItem(value: 'eliminar', child: Text('Eliminar empleado')),
    ],
  );

  Widget _estadoEmpleado(Empleado empleado) {
    final color = empleado.activo ? const Color(0xFF21845A) : AppColors.grey600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: empleado.activo ? const Color(0xFFE3F5EC) : AppColors.grey100,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        empleado.activo ? 'Activo' : 'Inactivo',
        style: AppTypography.labelSmallSemiBold.copyWith(color: color),
      ),
    );
  }

  Widget _directorio(
    List<Empleado> empleados, {
    bool shrinkWrap = false,
  }) => LayoutBuilder(
    builder: (context, constraints) {
      if (empleados.isEmpty) {
        return Align(
          alignment: shrinkWrap ? Alignment.topCenter : Alignment.center,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.groups_2_outlined,
                  size: 46,
                  color: AppColors.grey400,
                ),
                const SizedBox(height: 10),
                Text(
                  _q.isEmpty
                      ? 'No hay colaboradores para mostrar'
                      : 'No se encontraron colaboradores con ese criterio',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (_q.isEmpty) ...[const SizedBox(height: 14), _botonNuevo()],
              ],
            ),
          ),
        );
      }

      if (constraints.maxWidth >= 880) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
          child: DataTable(
            horizontalMargin: 16,
            columnSpacing: 26,
            headingRowHeight: 46,
            dataRowMinHeight: 66,
            dataRowMaxHeight: 76,
            headingRowColor: const WidgetStatePropertyAll(Color(0xFFF7F9FC)),
            headingTextStyle: AppTypography.labelSmallSemiBold.copyWith(
              color: AppColors.grey500,
              letterSpacing: 0.55,
            ),
            columns: const [
              DataColumn(label: Text('COLABORADOR')),
              DataColumn(label: Text('CARGO')),
              DataColumn(label: Text('CÉDULA')),
              DataColumn(numeric: true, label: Text('SALARIO BASE')),
              DataColumn(label: Text('ESTADO')),
              DataColumn(label: Text('ACCIONES')),
            ],
            rows: [
              for (final empleado in empleados)
                DataRow(
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2F5EC),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFC8E9D8),
                              ),
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              size: 21,
                              color: Color(0xFF25845B),
                            ),
                          ),
                          const SizedBox(width: 11),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 230),
                            child: Text(
                              empleado.nombreCompleto,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.grey900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        empleado.cargo?.trim().isNotEmpty == true
                            ? empleado.cargo!
                            : '—',
                      ),
                    ),
                    DataCell(
                      Text(
                        empleado.cedula?.trim().isNotEmpty == true
                            ? empleado.cedula!
                            : '—',
                      ),
                    ),
                    DataCell(
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          formatRd(empleado.salarioBase),
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    DataCell(_estadoEmpleado(empleado)),
                    DataCell(_accionesEmpleado(empleado)),
                  ],
                ),
            ],
          ),
        );
      }

      return ListView.separated(
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
        itemCount: empleados.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final empleado = empleados[index];
          return Material(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              onTap: () => _abrirForm(empleado),
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE2F5EC),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            color: Color(0xFF25845B),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                empleado.nombreCompleto,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                empleado.cargo?.trim().isNotEmpty == true
                                    ? empleado.cargo!
                                    : '—',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        _accionesEmpleado(empleado),
                      ],
                    ),
                    const Divider(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            empleado.cedula?.trim().isNotEmpty == true
                                ? empleado.cedula!
                                : 'Cédula no registrada',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.grey600,
                            ),
                          ),
                        ),
                        Text(
                          formatRd(empleado.salarioBase),
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 9),
                        _estadoEmpleado(empleado),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  Widget _panelEmpleados({
    required List<Empleado> empleados,
    required int total,
    required int activos,
    required int inactivos,
    bool shrinkWrap = false,
  }) => Container(
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF17243A).withValues(alpha: 0.055),
          blurRadius: 18,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 700;
              final tabs = _filtros(total, activos, inactivos);
              final search = SizedBox(
                width: compact ? double.infinity : 370,
                height: 42,
                child: TextField(
                  onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, cédula o cargo…',
                    prefixIcon: const Icon(Icons.search_rounded, size: 19),
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.grey300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.grey300),
                    ),
                  ),
                ),
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [tabs, const SizedBox(height: 10), search],
                );
              }
              return Row(
                children: [
                  Expanded(child: tabs),
                  const SizedBox(width: 14),
                  search,
                ],
              );
            },
          ),
        ),
        const Divider(height: 1, color: AppColors.grey200),
        if (shrinkWrap)
          _directorio(empleados, shrinkWrap: true)
        else
          Expanded(child: _directorio(empleados)),
      ],
    ),
  );

  Widget _contenido(List<Empleado> lista, bool desktop) {
    final activos = lista.where((e) => e.activo).length;
    final inactivos = lista.length - activos;
    final totalMensual = lista
        .where((e) => e.activo)
        .fold<double>(0, (total, e) => total + e.salarioBase);
    final empleados = lista.where((e) {
      if (_filtroActivo != null && e.activo != _filtroActivo) return false;
      if (_q.isEmpty) return true;
      final blob =
          '${e.nombre} ${e.apellido} ${e.cedula ?? ''} ${e.cargo ?? ''}'
              .toLowerCase();
      return blob.contains(_q);
    }).toList();

    final padding = EdgeInsets.fromLTRB(
      desktop ? 24 : 12,
      desktop ? 22 : 10,
      desktop ? 24 : 12,
      16,
    );
    final encabezadoYResumen = <Widget>[
      _encabezado(desktop),
      SizedBox(height: desktop ? 22 : 14),
      _tarjetasAcceso(totalMensual, activos),
      SizedBox(height: desktop ? 22 : 14),
    ];

    if (!desktop) {
      // En móviles, la cabecera, los accesos y el listado comparten un solo
      // desplazamiento. Así el alto reducido (incluido paisaje) no fuerza un
      // Expanded a competir con tarjetas que ya ocupan más que la pantalla.
      return Padding(
        padding: padding,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...encabezadoYResumen,
              _panelEmpleados(
                empleados: empleados,
                total: lista.length,
                activos: activos,
                inactivos: inactivos,
                shrinkWrap: true,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...encabezadoYResumen,
          Expanded(
            child: _panelEmpleados(
              empleados: empleados,
              total: lista.length,
              activos: activos,
              inactivos: inactivos,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(empleadosListaProvider);
    final desktop = AppBreakpoints.isDesktop(context);
    return AppScaffold(
      title: ServicioIdioma.t(context, 'Nómina'),
      showAppBar: !desktop,
      actions: [_botonExportar()],
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (lista) => _contenido(lista, desktop),
      ),
    );
  }
}

class _EmpleadoFormSheet extends ConsumerStatefulWidget {
  const _EmpleadoFormSheet({this.empleado});
  final Empleado? empleado;

  @override
  ConsumerState<_EmpleadoFormSheet> createState() => _EmpleadoFormSheetState();
}

/// Selector compacto para la fecha de ingreso: conserva el calendario mensual,
/// con una huella fija y pequeña en escritorio y móvil.
class _CalendarioIngresoCompacto extends StatefulWidget {
  const _CalendarioIngresoCompacto({
    required this.fechaInicial,
    required this.fechaMinima,
    required this.fechaMaxima,
  });

  final DateTime fechaInicial;
  final DateTime fechaMinima;
  final DateTime fechaMaxima;

  @override
  State<_CalendarioIngresoCompacto> createState() =>
      _CalendarioIngresoCompactoState();
}

class _CalendarioIngresoCompactoState
    extends State<_CalendarioIngresoCompacto> {
  late DateTime _seleccionada;
  late DateTime _mes;

  @override
  void initState() {
    super.initState();
    _seleccionada = DateUtils.dateOnly(widget.fechaInicial);
    _mes = DateTime(_seleccionada.year, _seleccionada.month);
  }

  void _cambiarMes(int delta) {
    final siguiente = DateTime(_mes.year, _mes.month + delta);
    final primerMes = DateTime(
      widget.fechaMinima.year,
      widget.fechaMinima.month,
    );
    final ultimoMes = DateTime(
      widget.fechaMaxima.year,
      widget.fechaMaxima.month,
    );
    if (siguiente.isBefore(primerMes) || siguiente.isAfter(ultimoMes)) return;
    setState(() => _mes = siguiente);
  }

  @override
  Widget build(BuildContext context) {
    final localizaciones = MaterialLocalizations.of(context);
    final tema = Theme.of(context);
    final offset = DateUtils.firstDayOffset(
      _mes.year,
      _mes.month,
      localizaciones,
    );
    final diasEnMes = DateUtils.getDaysInMonth(_mes.year, _mes.month);
    final ancho = (MediaQuery.sizeOf(context).width - 24).clamp(272.0, 320.0);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: SizedBox(
        width: ancho,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Fecha de ingreso',
                  style: tema.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(
                height: 38,
                child: Row(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Mes anterior',
                      onPressed:
                          DateTime(_mes.year, _mes.month).isAfter(
                            DateTime(
                              widget.fechaMinima.year,
                              widget.fechaMinima.month,
                            ),
                          )
                          ? () => _cambiarMes(-1)
                          : null,
                      icon: const Icon(Icons.chevron_left_rounded, size: 21),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          localizaciones.formatMonthYear(_mes),
                          style: tema.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Mes siguiente',
                      onPressed:
                          DateTime(_mes.year, _mes.month).isBefore(
                            DateTime(
                              widget.fechaMaxima.year,
                              widget.fechaMaxima.month,
                            ),
                          )
                          ? () => _cambiarMes(1)
                          : null,
                      icon: const Icon(Icons.chevron_right_rounded, size: 21),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(DateTime.daysPerWeek, (i) {
                  final indice =
                      (localizaciones.firstDayOfWeekIndex + i) %
                      DateTime.daysPerWeek;
                  return Expanded(
                    child: SizedBox(
                      height: 22,
                      child: Center(
                        child: Text(
                          localizaciones.narrowWeekdays[indice],
                          style: tema.textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              for (var semana = 0; semana < 6; semana++)
                SizedBox(
                  height: 32,
                  child: Row(
                    children: List.generate(DateTime.daysPerWeek, (columna) {
                      final dia =
                          semana * DateTime.daysPerWeek + columna - offset + 1;
                      if (dia < 1 || dia > diasEnMes) {
                        return const Expanded(child: SizedBox.shrink());
                      }
                      final fecha = DateTime(_mes.year, _mes.month, dia);
                      final habilitada =
                          !fecha.isBefore(widget.fechaMinima) &&
                          !fecha.isAfter(widget.fechaMaxima);
                      final elegida = DateUtils.isSameDay(fecha, _seleccionada);
                      return Expanded(
                        child: Center(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: Material(
                              color: elegida
                                  ? tema.colorScheme.primary
                                  : Colors.transparent,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: habilitada
                                    ? () =>
                                          setState(() => _seleccionada = fecha)
                                    : null,
                                child: Center(
                                  child: Text(
                                    '$dia',
                                    style: tema.textTheme.labelMedium?.copyWith(
                                      color: elegida
                                          ? tema.colorScheme.onPrimary
                                          : habilitada
                                          ? tema.colorScheme.onSurface
                                          : AppColors.textSecondary.withValues(
                                              alpha: 0.35,
                                            ),
                                      fontWeight: elegida
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 4),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, _seleccionada),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(76, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmpleadoFormSheetState extends ConsumerState<_EmpleadoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _apellido;
  late final TextEditingController _cedula;
  late final TextEditingController _telefono;
  late final TextEditingController _email;
  late final TextEditingController _cargo;
  late final TextEditingController _salario;
  late final TextEditingController _banco;
  late final TextEditingController _numeroCuenta;
  late String _tipoCuenta;
  late String _formaPago;
  late final TextEditingController _notas;
  late bool _activo;
  DateTime? _fechaIngreso;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.empleado;
    _nombre = TextEditingController(text: e?.nombre ?? '');
    _apellido = TextEditingController(text: e?.apellido ?? '');
    _cedula = TextEditingController(text: e?.cedula ?? '');
    _telefono = TextEditingController(text: e?.telefono ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _cargo = TextEditingController(text: e?.cargo ?? '');
    _banco = TextEditingController(text: e?.banco ?? '');
    _numeroCuenta = TextEditingController(text: e?.numeroCuenta ?? '');
    _tipoCuenta = e?.tipoCuenta ?? 'ahorro';
    _formaPago = e?.formaPago ?? 'transferencia';
    _salario = TextEditingController(
      text: e == null ? '' : e.salarioBase.toStringAsFixed(2),
    );
    _notas = TextEditingController(text: e?.notas ?? '');
    _activo = e?.activo ?? true;
    _fechaIngreso = e?.fechaIngreso ?? DateTime.now();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _cedula.dispose();
    _telefono.dispose();
    _email.dispose();
    _cargo.dispose();
    _salario.dispose();
    _banco.dispose();
    _numeroCuenta.dispose();
    _notas.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final salario =
          double.tryParse(
            _salario.text
                .replaceAll(',', '.')
                .replaceAll(RegExp(r'[^\d.]'), ''),
          ) ??
          0;
      final e = Empleado(
        id: widget.empleado?.id,
        nombre: _nombre.text.trim(),
        apellido: _apellido.text.trim(),
        cedula: _cedula.text.trim().isEmpty ? null : _cedula.text.trim(),
        telefono: _telefono.text.trim().isEmpty ? null : _telefono.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        cargo: _cargo.text.trim().isEmpty ? null : _cargo.text.trim(),
        salarioBase: salario,
        activo: _activo,
        fechaIngreso: _fechaIngreso ?? DateTime.now(),
        banco: _banco.text.trim().isEmpty ? null : _banco.text.trim(),
        tipoCuenta: _tipoCuenta,
        numeroCuenta: _numeroCuenta.text.trim().isEmpty
            ? null
            : _numeroCuenta.text.trim(),
        formaPago: _formaPago,
        notas: _notas.text.trim().isEmpty ? null : _notas.text.trim(),
        creadoEn: widget.empleado?.creadoEn ?? DateTime.now(),
      );
      await ref.read(empleadoRepositoryProvider).guardar(e);
      if (mounted) {
        FiscoGestNotifications.show(
          SnackBar(
            content: Text(
              widget.empleado == null
                  ? 'Empleado creado'
                  : 'Empleado actualizado',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (err) {
      if (mounted) {
        FiscoGestNotifications.show(
          SnackBar(
            content: Text('No se pudo guardar: $err'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.badge_outlined,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.empleado == null
                          ? 'Nuevo empleado'
                          : 'Editar empleado',
                      style: AppTypography.h4.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoColumns = constraints.maxWidth >= 480;
                  final fieldWidth = twoColumns
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                        width: fieldWidth,
                        child: _field(_nombre, 'Nombre *', required: true),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: _field(_apellido, 'Apellido *', required: true),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: _field(_cedula, 'Cédula'),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: _field(_telefono, 'Teléfono'),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: _field(_email, 'Email'),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: _field(_cargo, 'Cargo'),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: _field(
                          _salario,
                          'Salario base (RD\$)',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: _field(_banco, 'Banco'),
                      ),
                      SizedBox(
                        width: constraints.maxWidth,
                        child: Text(
                          'Datos de pago',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: DropdownButtonFormField<String>(
                          initialValue: _tipoCuenta,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de cuenta',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'ahorro',
                              child: Text('Ahorro'),
                            ),
                            DropdownMenuItem(
                              value: 'corriente',
                              child: Text('Corriente'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _tipoCuenta = v);
                          },
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: _field(_numeroCuenta, 'Número de cuenta'),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: DropdownButtonFormField<String>(
                          initialValue: _formaPago,
                          decoration: const InputDecoration(
                            labelText: 'Forma de pago',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'transferencia',
                              child: Text('Transferencia'),
                            ),
                            DropdownMenuItem(
                              value: 'efectivo',
                              child: Text('Efectivo'),
                            ),
                            DropdownMenuItem(
                              value: 'cheque',
                              child: Text('Cheque'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _formaPago = v);
                          },
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth,
                        child: _field(_notas, 'Notas', maxLines: 2),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha de ingreso'),
                subtitle: Text(
                  _fechaIngreso == null
                      ? 'Sin fecha'
                      : '${_fechaIngreso!.day.toString().padLeft(2, '0')}/'
                            '${_fechaIngreso!.month.toString().padLeft(2, '0')}/'
                            '${_fechaIngreso!.year}',
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () async {
                  final now = DateUtils.dateOnly(DateTime.now());
                  final maxDate = now.add(const Duration(days: 365));
                  final solicitada = DateUtils.dateOnly(_fechaIngreso ?? now);
                  final inicial = solicitada.isBefore(DateTime(1990))
                      ? DateTime(1990)
                      : solicitada.isAfter(maxDate)
                      ? maxDate
                      : solicitada;
                  final d = await showDialog<DateTime>(
                    context: context,
                    builder: (context) {
                      return _CalendarioIngresoCompacto(
                        fechaInicial: inicial,
                        fechaMinima: DateTime(1990),
                        fechaMaxima: maxDate,
                      );
                    },
                  );
                  if (d != null) setState(() => _fechaIngreso = d);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Activo'),
                value: _activo,
                onChanged: (v) => setState(() => _activo = v),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _saving ? null : _guardar,
                child: Text(_saving ? 'Guardando…' : 'Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
