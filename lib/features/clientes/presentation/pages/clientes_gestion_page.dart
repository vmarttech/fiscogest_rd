import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/features/clientes/presentation/providers/cliente_completo_providers.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_completo.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';

const _bgCanvas = Color(0xFFF3F7F9);
const _border = Color(0xFFE2E8F0);
const _muted = Color(0xFF334155);
const _ink = Color(0xFF020617);
const _tealDark = Color(0xFF115E59);

const List<BoxShadow> _cardShadow = [
  BoxShadow(color: Color(0x1F0F172A), blurRadius: 16, offset: Offset(0, 6)),
  BoxShadow(color: Color(0x1414B8A6), blurRadius: 24, offset: Offset(0, 10)),
];
const double _cardBorderW = 1.5; // +1% visual de grosor

class ClientesGestionPage extends ConsumerStatefulWidget {
  const ClientesGestionPage({super.key});
  static const String routeName = 'clientes-gestion';

  @override
  ConsumerState<ClientesGestionPage> createState() =>
      _ClientesGestionPageState();
}

class _ClientesGestionPageState extends ConsumerState<ClientesGestionPage> {
  final TextEditingController _searchController = TextEditingController();
  String _filtroBusqueda = '';
  ClienteCompleto? _seleccionado;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _themeFor(ClienteCompleto c) {
    const themes = [
      Color(0xFF14B8A6),
      Color(0xFF3B82F6),
      Color(0xFF10B981),
      Color(0xFF8B5CF6),
      Color(0xFFF59E0B),
    ];
    return themes[c.nombre.hashCode.abs() % themes.length];
  }

  String _iniciales(String nombre) {
    final parts = nombre
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts.first;
      return s.substring(0, s.length.clamp(0, 2)).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  List<ClienteCompleto> _filtrar(List<ClienteCompleto> all) {
    final q = _filtroBusqueda.trim().toLowerCase();
    if (q.isEmpty) return all;
    final tokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    return all.where((c) {
      final blob =
          '${c.nombre} ${c.rncCedula} ${c.telefono} ${c.correo} ${c.direccion}'
              .toLowerCase();
      return tokens.every(blob.contains);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    final clientesAsync = ref.watch(clienteCompletoControllerProvider);

    return AppScaffold(
      title: 'CLIENTES',
      backgroundColor: _bgCanvas,
      // Mockup desktop: sin barra superior del módulo.
      // Móvil: sí (ruta principal → menú, no flecha atrás).
      showAppBar: mobile,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: mobile ? 560 : 1200),
          child: SafeArea(
            child: clientesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: _tealDark),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
              data: (clientes) {
                final filtrados = _filtrar(clientes);

                if (_seleccionado != null &&
                    filtrados.every((c) => c.id != _seleccionado!.id)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _seleccionado = null);
                  });
                }
                if (!mobile && filtrados.isNotEmpty && _seleccionado == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _seleccionado == null) {
                      setState(() => _seleccionado = filtrados.first);
                    }
                  });
                }

                if (mobile) {
                  return _buildMobileList(filtrados);
                }
                return _buildDesktop(filtrados);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(List<ClienteCompleto> filtrados) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(true, filtrados)),
        if (filtrados.isEmpty)
          const SliverFillRemaining(hasScrollBody: false, child: _EmptyState())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            sliver: SliverList.separated(
              itemCount: filtrados.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final c = filtrados[i];
                final theme = _themeFor(c);
                return _ClienteCardPremium(
                  cliente: c,
                  theme: theme,
                  iniciales: _iniciales(c.nombre),
                  mobile: true,
                  selected: false,
                  onOpen: () => _abrirDetalle(context, c, theme),
                  onEdit: () => _irAEditarCliente(context, c),
                  onDelete: () => _confirmarEliminar(context, c),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDesktop(List<ClienteCompleto> filtrados) {
    // Layout:
    // [ HEADER full width: CLIENTES | indicadores ]
    // [ CENTER (Cartera+lista) | PANEL 320 ]
    return ColoredBox(
      color: const Color(0xFFF3F7F9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header independiente (no dentro del flujo del listado)
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F7F9),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'CLIENTES',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF020617),
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                // Indicadores anclados al extremo derecho (zona del panel)
                SizedBox(
                  width: 320,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _buildIndicadores(filtrados),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(false, filtrados),
                        if (filtrados.isEmpty)
                          const Expanded(child: _EmptyState())
                        else
                          Expanded(
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: filtrados.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final c = filtrados[i];
                                return _ClienteCardPremium(
                                  cliente: c,
                                  theme: _themeFor(c),
                                  iniciales: _iniciales(c.nombre),
                                  mobile: false,
                                  selected: _seleccionado?.id == c.id,
                                  onOpen: () =>
                                      setState(() => _seleccionado = c),
                                  onEdit: () => _irAEditarCliente(context, c),
                                  onDelete: () =>
                                      _confirmarEliminar(context, c),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 320,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFFFF),
                    border: Border(
                      left: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                    ),
                  ),
                  child: _seleccionado == null
                      ? const _PanelVacio()
                      : _PanelDerechoDesktop(
                          cliente: _seleccionado!,
                          theme: _themeFor(_seleccionado!),
                          iniciales: _iniciales(_seleccionado!.nombre),
                          onDetalleCompleto: () => _abrirDetalle(
                            context,
                            _seleccionado!,
                            _themeFor(_seleccionado!),
                          ),
                          onEdit: () =>
                              _irAEditarCliente(context, _seleccionado!),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicadores(List<ClienteCompleto> clientes) {
    final activos = clientes.where((c) => c.activo).length;
    final pendientes = clientes.where((c) => c.saldoPendiente > 0.009).length;
    final vencidos = clientes.where((c) {
      if (c.saldoPendiente <= 0) return false;
      if (c.limiteCuotaMensual > 0) {
        return c.saldoPendiente > c.limiteCuotaMensual;
      }
      return false;
    }).length;

    Widget item(IconData icon, String label, int n, Color iconColor) {
      return Padding(
        padding: const EdgeInsets.only(left: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF334155),
              ),
            ),
            if (n > 0) ...[
              const SizedBox(width: 3),
              Text(
                '$n',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF020617),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        item(
          Icons.bar_chart_rounded,
          'Activos',
          activos,
          const Color(0xFF10B981),
        ),
        item(
          Icons.description_outlined,
          'Pendientes',
          pendientes,
          const Color(0xFFF59E0B),
        ),
        item(
          Icons.schedule_rounded,
          'Vencidos',
          vencidos,
          const Color(0xFFEF4444),
        ),
      ],
    );
  }

  Widget _buildHeader(bool mobile, [List<ClienteCompleto>? clientes]) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        mobile ? 16 : 0,
        mobile ? 8 : 0,
        mobile ? 16 : 8,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mobile) ...[
            const Text(
              'CLIENTES',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Cartera de clientes',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF020617),
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Datos personales, fiscales y contacto',
              style: TextStyle(color: Color(0xFF334155), fontSize: 13),
            ),
            const SizedBox(height: 10),
            if (clientes != null) _buildIndicadores(clientes),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: () => _irANuevoCliente(context),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF115E59),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.person_add_rounded, size: 22),
                label: const Text(
                  'Nuevo cliente',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
          ] else
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cartera de clientes',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF020617),
                          fontSize: 22,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Administración de datos personales, fiscales y contacto.',
                        style: TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 46,
                  child: FilledButton.icon(
                    onPressed: () => _irANuevoCliente(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF115E59),
                      foregroundColor: Colors.white,
                      elevation: 1,
                      shadowColor: const Color(0x66115E59),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.person_add_rounded, size: 20),
                    label: const Text(
                      'Nuevo cliente',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: (v) =>
                setState(() => _filtroBusqueda = v.trim().toLowerCase()),
            style: AppTypography.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, RNC, teléfono o correo…',
              hintStyle: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 13,
              ),
              prefixIcon: const Icon(Icons.search_rounded, size: 22),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF14B8A6),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _abrirDetalle(BuildContext context, ClienteCompleto c, Color theme) {
    // Dentro de AppShell: menú lateral + barra superior se mantienen.
    context.pushNamed('cliente-detalle', extra: c);
  }

  void _irANuevoCliente(BuildContext context) {
    context.pushNamed('nuevo-cliente');
  }

  void _irAEditarCliente(BuildContext context, ClienteCompleto cliente) {
    context.pushNamed('editar-cliente', extra: cliente);
  }

  void _confirmarEliminar(BuildContext context, ClienteCompleto cliente) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Eliminar cliente',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text('¿Eliminar a “${cliente.nombre}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: _muted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              if (cliente.id != null) {
                ref
                    .read(clienteCompletoControllerProvider.notifier)
                    .eliminar(cliente.id!);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ─── Card (borde izq. color + avatar iniciales) ───
class _ClienteCardPremium extends StatelessWidget {
  const _ClienteCardPremium({
    required this.cliente,
    required this.theme,
    required this.iniciales,
    required this.mobile,
    this.selected = false,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final ClienteCompleto cliente;
  final Color theme;
  final String iniciales;
  final bool mobile;
  final bool selected;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  bool get _esPreferencial {
    final o = cliente.observaciones.toLowerCase();
    return o.contains('preferencial') || o.contains('preferente');
  }

  @override
  Widget build(BuildContext context) {
    final bgAvatar = Color.lerp(theme, Colors.white, 0.82)!;
    final saldo = cliente.saldoPendiente;
    final tieneSaldo = saldo > 0.009;

    // geometric-client-card + border-left 4px (barra, compatible con radius)
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF8FAFC) : const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 14,
                      offset: Offset(0, 5),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: theme),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: bgAvatar,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              iniciales,
                              style: TextStyle(
                                color: theme,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        cliente.nombre,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: Color(0xFF020617),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (_esPreferencial) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0FDF4),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFBBF7D0),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.star_rounded,
                                              size: 12,
                                              color: Color(0xFF16A34A),
                                            ),
                                            SizedBox(width: 3),
                                            Text(
                                              'Preferencial',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF16A34A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (tieneSaldo && !selected) ...[
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        size: 16,
                                        color: Color(0xFFD97706),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  [
                                    if (cliente.rncCedula.trim().isNotEmpty)
                                      cliente.rncCedula,
                                    if (cliente.telefono.trim().isNotEmpty)
                                      cliente.telefono,
                                  ].join(' · '),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF334155),
                                    height: 1.4,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (cliente.direccion.trim().isNotEmpty)
                                  Text(
                                    cliente.direccion,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF334155),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          if (!mobile && selected) ...[
                            OutlinedButton(
                              onPressed: onOpen,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF334155),
                                backgroundColor: const Color(0xFFF1F5F9),
                                side: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: const Text(
                                'Historial de Pagos',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (tieneSaldo) ...[
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFFED7AA),
                                ),
                              ),
                              child: Text(
                                'Balance ${saldo.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFC2410C),
                                ),
                              ),
                            ),
                          ],
                          _HIcon(
                            Icons.info_outline_rounded,
                            const Color(0xFF334155),
                            onOpen,
                          ),
                          _HIcon(
                            Icons.edit_outlined,
                            const Color(0xFF334155),
                            onEdit,
                          ),
                          _HIcon(
                            Icons.delete_outline_rounded,
                            const Color(0xFFEF4444),
                            onDelete,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HIcon extends StatelessWidget {
  const _HIcon(this.icon, this.color, this.onTap);
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // HTML: .btn-crud-action { width: 30px; height: 30px }
    return SizedBox(
      width: 30,
      height: 30,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Center(child: Icon(icon, size: 16, color: color)),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 56,
              color: Color(0xFFCBD5E1),
            ),
            SizedBox(height: 14),
            Text(
              'Sin clientes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Crea el primero con “Nuevo cliente”.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelVacio extends StatelessWidget {
  const _PanelVacio();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search_rounded,
              size: 48,
              color: Color(0xFFCBD5E1),
            ),
            SizedBox(height: 12),
            Text(
              'Selecciona un cliente',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: _ink,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Ningún elemento seleccionado',
              style: TextStyle(fontSize: 12, color: _muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelDerechoDesktop extends StatelessWidget {
  const _PanelDerechoDesktop({
    required this.cliente,
    required this.theme,
    required this.iniciales,
    required this.onDetalleCompleto,
    required this.onEdit,
  });

  final ClienteCompleto cliente;
  final Color theme;
  final String iniciales;
  final VoidCallback onDetalleCompleto;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final bgAvatar = Color.lerp(theme, Colors.white, 0.78)!;
    final saldo = cliente.saldoPendiente;
    final limite = cliente.limiteCuotaMensual;
    final ingreso = cliente.ingresoMensual;

    // Segmentos dona (visual como mockup)
    final a = saldo > 0 ? saldo : 1.0;
    final b = limite > 0 ? limite : 1.0;
    final c = ingreso > 0 ? ingreso : 1.0;
    final total = a + b + c;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      children: [
        Column(
          children: [
            Container(
              width: 70,
              height: 70,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bgAvatar,
                shape: BoxShape.circle,
              ),
              child: Text(
                iniciales,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: theme,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              cliente.nombre,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF020617),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              [
                if (cliente.rncCedula.trim().isNotEmpty) cliente.rncCedula,
                if (cliente.telefono.trim().isNotEmpty)
                  'RNC.- ${cliente.telefono}',
                if (cliente.direccion.trim().isNotEmpty) cliente.direccion,
              ].join('\n'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF334155),
                height: 1.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 16),
        const Text(
          'Composición de Crédito',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF020617),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: SizedBox(
            width: 120,
            height: 120,
            child: CustomPaint(
              painter: _MultiDonutPainter(
                segments: [a / total, b / total, c / total],
                colors: const [
                  Color(0xFF14B8A6),
                  Color(0xFF3B82F6),
                  Color(0xFFF59E0B),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Últimas Acciones',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF020617),
          ),
        ),
        const SizedBox(height: 12),
        _ActivityDot(
          color: const Color(0xFF16A34A),
          title: cliente.historial.isEmpty
              ? 'Cliente registrado en el sistema'
              : cliente.historial,
          subtitle: 'Historial',
        ),
        if (cliente.observaciones.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          _ActivityDot(
            color: const Color(0xFF3B82F6),
            title: cliente.observaciones,
            subtitle: 'Observaciones',
          ),
        ],
        if (saldo > 0) ...[
          const SizedBox(height: 10),
          _ActivityDot(
            color: const Color(0xFFF59E0B),
            title: 'Balance pendiente RD\$${saldo.toStringAsFixed(2)}',
            subtitle: 'Crédito',
          ),
        ],
        const SizedBox(height: 22),
        SizedBox(
          height: 42,
          child: FilledButton(
            onPressed: onDetalleCompleto,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF115E59),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Ver Detalles Completos',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reporte del cliente: próximamente'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF020617),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Generar Reporte',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: _muted),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ActivityDot extends StatelessWidget {
  const _ActivityDot({
    required this.color,
    required this.title,
    required this.subtitle,
  });
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Pantalla hija detalle ───
class ClienteDetallePage extends StatelessWidget {
  const ClienteDetallePage({
    super.key,
    required this.cliente,
    required this.theme,
    required this.iniciales,
    this.onEdit,
    this.onDelete,
  });

  /// Desde GoRouter (extra = ClienteCompleto).
  factory ClienteDetallePage.fromCliente(ClienteCompleto c) {
    const themes = [
      Color(0xFF14B8A6),
      Color(0xFF3B82F6),
      Color(0xFF10B981),
      Color(0xFF8B5CF6),
      Color(0xFFF59E0B),
    ];
    final theme = themes[c.nombre.hashCode.abs() % themes.length];
    final parts = c.nombre
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    String ini = '?';
    if (parts.length == 1) {
      ini = parts.first
          .substring(0, parts.first.length.clamp(0, 2))
          .toUpperCase();
    } else if (parts.length >= 2) {
      ini = (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return ClienteDetallePage(cliente: c, theme: theme, iniciales: ini);
  }

  final ClienteCompleto cliente;
  final Color theme;
  final String iniciales;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final bgAvatar = Color.lerp(theme, Colors.white, 0.78)!;
    final saldo = cliente.saldoPendiente;
    final limite = cliente.limiteCuotaMensual;
    final ingreso = cliente.ingresoMensual;
    final usado = limite > 0 ? (saldo / limite).clamp(0.0, 1.0) : 0.0;
    final mobile = AppBreakpoints.isMobile(context);

    void goBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/clientes');
      }
    }

    void goEdit() {
      if (onEdit != null) {
        onEdit!();
      } else {
        context.pushNamed('editar-cliente', extra: cliente);
      }
    }

    final profileCard = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(colors: [_tealDark, theme]),
            ),
          ),
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bgAvatar,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.withValues(alpha: 0.35),
                width: 2,
              ),
            ),
            child: Text(
              iniciales,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: theme,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            cliente.nombre,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF020617),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (cliente.rncCedula.trim().isNotEmpty)
                'RNC ${cliente.rncCedula}',
              if (cliente.direccion.trim().isNotEmpty) cliente.direccion,
            ].join(' · '),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF334155),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: goEdit,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Editar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _tealDark,
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final contactCard = _GlassCard(
      child: Column(
        children: [
          _QuickRow(
            icon: Icons.phone_rounded,
            label: 'Teléfono',
            value: cliente.telefono.isEmpty ? '—' : cliente.telefono,
            theme: theme,
          ),
          const Divider(height: 20),
          _QuickRow(
            icon: Icons.email_outlined,
            label: 'Correo',
            value: cliente.correo.isEmpty ? '—' : cliente.correo,
            theme: theme,
          ),
          const Divider(height: 20),
          _QuickRow(
            icon: Icons.badge_outlined,
            label: 'RNC / Cédula',
            value: cliente.rncCedula.isEmpty ? '—' : cliente.rncCedula,
            theme: theme,
          ),
          const Divider(height: 20),
          _QuickRow(
            icon: Icons.location_on_outlined,
            label: 'Dirección',
            value: cliente.direccion.isEmpty ? '—' : cliente.direccion,
            theme: theme,
          ),
        ],
      ),
    );

    final creditCard = _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Composición de crédito',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF020617),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: CustomPaint(
                  painter: _DonutPainter(
                    progress: usado,
                    color: theme,
                    track: const Color(0xFFE2E8F0),
                  ),
                  child: Center(
                    child: Text(
                      limite > 0 ? '${(usado * 100).round()}%' : '—',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: theme,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _MetricRow(
                      label: 'Saldo pendiente',
                      value: 'RD\$${saldo.toStringAsFixed(2)}',
                      color: const Color(0xFFC2410C),
                    ),
                    const SizedBox(height: 8),
                    _MetricRow(
                      label: 'Límite cuota',
                      value: 'RD\$${limite.toStringAsFixed(2)}',
                      color: _tealDark,
                    ),
                    const SizedBox(height: 8),
                    _MetricRow(
                      label: 'Ingreso mens.',
                      value: 'RD\$${ingreso.toStringAsFixed(2)}',
                      color: const Color(0xFF334155),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final activityCard = _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Últimas acciones',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF020617),
            ),
          ),
          const SizedBox(height: 12),
          _ActivityDot(
            color: theme,
            title: cliente.historial.isEmpty
                ? 'Cliente registrado en el sistema'
                : cliente.historial,
            subtitle: 'Historial',
          ),
          if (cliente.observaciones.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _ActivityDot(
              color: const Color(0xFFF59E0B),
              title: cliente.observaciones,
              subtitle: 'Observaciones',
            ),
          ],
          const SizedBox(height: 10),
          _ActivityDot(
            color: cliente.activo ? const Color(0xFF16A34A) : AppColors.error,
            title: cliente.activo ? 'Cliente activo' : 'Cliente inactivo',
            subtitle: 'Estado',
          ),
        ],
      ),
    );

    return AppScaffold(
      title: 'DETALLE CLIENTE',
      backgroundColor: _bgCanvas,
      // Móvil: barra del módulo (como el resto). Desktop: false (ya hay shell).
      showAppBar: mobile,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          mobile ? 16 : 24,
          12,
          mobile ? 16 : 24,
          32,
        ),
        children: [
          // En PC se mantiene fila con atrás + título (sin AppBar del scaffold)
          if (!mobile) ...[
            Row(
              children: [
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: goBack,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFCBD5E1),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: Color(0xFF020617),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Detalle del cliente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF020617),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (mobile) ...[
            profileCard,
            const SizedBox(height: 12),
            contactCard,
            const SizedBox(height: 12),
            creditCard,
            const SizedBox(height: 12),
            activityCard,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 280, child: profileCard),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      contactCard,
                      const SizedBox(height: 12),
                      creditCard,
                      const SizedBox(height: 12),
                      activityCard,
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: goBack,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF020617),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Volver a la cartera',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: _cardBorderW),
        boxShadow: _cardShadow,
      ),
      child: child,
    );
  }
}

class _QuickRow extends StatelessWidget {
  const _QuickRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Color.lerp(theme, Colors.white, 0.85),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: theme),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: _muted)),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.progress,
    required this.color,
    required this.track,
  });
  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;
    const stroke = 22.0;
    final paintTrack = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final paintProg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r - stroke / 2, paintTrack);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - stroke / 2),
      -1.5708,
      progress * 6.2832,
      false,
      paintProg,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.progress != progress || old.color != color;
}

class _MultiDonutPainter extends CustomPainter {
  _MultiDonutPainter({required this.segments, required this.colors});
  final List<double> segments;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;
    const stroke = 26.0; // anillo grueso mockup
    var start = -1.5708;
    for (var i = 0; i < segments.length; i++) {
      final sweep = segments[i].clamp(0.0, 1.0) * 6.28318530718;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r - stroke / 2),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep;
    }
    final hole = Paint()..color = Colors.white;
    canvas.drawCircle(c, r - stroke - 2, hole);
  }

  @override
  bool shouldRepaint(covariant _MultiDonutPainter oldDelegate) => true;
}
