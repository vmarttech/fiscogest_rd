import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/providers/core_providers.dart';
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/conteo_fisico.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/estado_conteo.dart';
import 'package:fiscogest_rd/features/inventario_fisico/presentation/providers/inventario_fisico_provider.dart';

/// Nuevo Conteo Físico — 3 columnas desktop / stack móvil.
/// Tarjetas interactivas (no decoración). Texto en negrita.
class RegistrarConteoPage extends ConsumerStatefulWidget {
  const RegistrarConteoPage({super.key});

  static const routeName = 'registrar-conteo-fisico';

  @override
  ConsumerState<RegistrarConteoPage> createState() =>
      _RegistrarConteoPageState();
}

class _RegistrarConteoPageState extends ConsumerState<RegistrarConteoPage> {
  final _nombreCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  bool _cargando = false;
  bool _porLotes = false;

  static const _bg = Color(0xFFF1F5F9);
  static const _border = Color(0xFFE2E8F0);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF475569);
  static const _teal = Color(0xFF0D9488);
  static const _tealDark = Color(0xFF0F766E);

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  String _fmtFechaLarga(DateTime d) {
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    return '${d.day} de ${meses[d.month - 1]} ${d.year}';
  }

  String _fmtFechaCorta(DateTime d) {
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    return '${d.day} ${meses[d.month - 1]} ${d.year}';
  }

  String _nombreUsuario() {
    final s = ref.read(sesionProvider);
    if (s == null) return 'Usuario';
    final raw = s.nombre.trim().isNotEmpty ? s.nombre.trim() : s.username;
    final words = <String>[];
    for (final w in raw.split(RegExp(r'\s+'))) {
      if (w.isEmpty) continue;
      if (words.isEmpty || words.last.toLowerCase() != w.toLowerCase()) {
        words.add(w);
      }
    }
    return words.isEmpty ? 'Usuario' : words.join(' ');
  }

  Future<void> _guardar() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      if (mounted) {
        FiscoGestNotifications.show(
          const SnackBar(
            content: Text(
              'Escribe un nombre para el conteo',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      }
      return;
    }
    final idUsuario = ref.read(usuarioAutenticadoProvider);
    if (idUsuario == null) {
      if (mounted) {
        FiscoGestNotifications.show(
          const SnackBar(
            content: Text(
              'No hay sesión activa',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      }
      return;
    }
    setState(() => _cargando = true);
    try {
      final ahora = DateTime.now();
      final conteo = ConteoFisico(
        nombreConteo: _porLotes ? '[Lotes] $nombre' : nombre,
        fechaConteo: ahora,
        observaciones: _obsCtrl.text.trim().isEmpty
            ? null
            : _obsCtrl.text.trim(),
        usuarioId: idUsuario,
        fechaCreacion: ahora,
        estado: EstadoConteo.pendiente,
      );
      final id = await ref.read(registrarConteoProvider).call(conteo);
      if (!mounted) return;
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text(
            'Conteo creado exitosamente',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
      ref.invalidate(listaConteosProvider);
      await context.push('/inventario-fisico/capturar/$id');
    } catch (e) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text(
            'Error: $e',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final wide = MediaQuery.sizeOf(context).width >= 1024;
    final ahora = DateTime.now();
    final usuario = _nombreUsuario();
    final conteosAsync = ref.watch(listaConteosProvider);

    ConteoFisico? ultimo;
    int totalConteos = 0;
    int abiertos = 0;
    conteosAsync.whenData((lista) {
      totalConteos = lista.length;
      abiertos = lista
          .where((c) =>
              c.estado == EstadoConteo.pendiente ||
              c.estado == EstadoConteo.abierto ||
              c.estado == EstadoConteo.enProceso)
          .length;
      if (lista.isNotEmpty) {
        final sorted = [...lista]
          ..sort((a, b) => b.fechaConteo.compareTo(a.fechaConteo));
        ultimo = sorted.first;
      }
    });

    // Diferencias del último conteo (si tiene id)
    final difsAsync = ultimo?.id != null
        ? ref.watch(diferenciasConteoProvider(ultimo!.id!))
        : null;
    int lineasUltimo = 0;
    int conError = 0;
    difsAsync?.whenData((difs) {
      lineasUltimo = difs.length;
      conError = difs.where((d) => d.diferencia != 0).length;
    });

    return AppScaffold(
      title: isMobile ? 'Nuevo Conteo' : null,
      showAppBar: isMobile,
      backgroundColor: _bg,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 24,
          isMobile ? 12 : 20,
          isMobile ? 16 : 24,
          isMobile ? 28 : 36,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isMobile) ...[
                  _headerDesktop(),
                  const SizedBox(height: 22),
                ],
                if (isMobile) ...[
                  _tabsTipo(fullWidth: true),
                  const SizedBox(height: 14),
                ],
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 280,
                        child: _columnaSesion(
                          fechaApertura: ahora,
                          usuario: usuario,
                          ultimo: ultimo,
                          isMobile: false,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(child: _columnaFormulario(isMobile: false)),
                      const SizedBox(width: 18),
                      SizedBox(
                        width: 280,
                        child: _columnaDerecha(
                          ultimo: ultimo,
                          lineasUltimo: lineasUltimo,
                          conError: conError,
                          totalConteos: totalConteos,
                          abiertos: abiertos,
                          isMobile: false,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // CTA primero en móvil
                      _columnaFormulario(isMobile: true),
                      const SizedBox(height: 14),
                      _columnaSesion(
                        fechaApertura: ahora,
                        usuario: usuario,
                        ultimo: ultimo,
                        isMobile: true,
                      ),
                      const SizedBox(height: 14),
                      _columnaDerecha(
                        ultimo: ultimo,
                        lineasUltimo: lineasUltimo,
                        conError: conError,
                        totalConteos: totalConteos,
                        abiertos: abiertos,
                        isMobile: true,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerDesktop() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _teal.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.assignment_outlined,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nuevo Conteo Físico',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _textPrimary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Apertura de sesión de inventario físico',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textMuted,
                ),
              ),
            ],
          ),
        ),
        _tabsTipo(fullWidth: false),
      ],
    );
  }

  Widget _tabsTipo({required bool fullWidth}) {
    final tabs = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabBtn('Conteo Simple', !_porLotes, () {
              setState(() => _porLotes = false);
            }),
          ),
          Expanded(
            child: _tabBtn('Conteo por Lotes', _porLotes, () {
              setState(() => _porLotes = true);
            }),
          ),
        ],
      ),
    );
    if (fullWidth) return tabs;
    return SizedBox(width: 280, child: tabs);
  }

  Widget _tabBtn(String label, bool active, VoidCallback onTap) {
    return Material(
      color: active ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      elevation: active ? 1.5 : 0,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: active ? _tealDark : _textMuted,
            ),
          ),
        ),
      ),
    );
  }

  // ── Sesión (tarjetas táctiles) ──
  Widget _columnaSesion({
    required DateTime fechaApertura,
    required String usuario,
    required ConteoFisico? ultimo,
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Datos de Sesión',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        _infoCard(
          icon: Icons.calendar_today_rounded,
          iconBg: const Color(0xFFCCFBF1),
          iconFg: _teal,
          label: 'Fecha de Apertura',
          value: _fmtFechaLarga(fechaApertura),
          onTap: null, // informativa
        ),
        const SizedBox(height: 10),
        _infoCard(
          icon: Icons.person_rounded,
          iconBg: const Color(0xFFDBEAFE),
          iconFg: const Color(0xFF2563EB),
          label: 'Usuario Registrador',
          value: usuario,
          onTap: null,
        ),
        const SizedBox(height: 10),
        _infoCard(
          icon: Icons.history_rounded,
          iconBg: const Color(0xFFFEF3C7),
          iconFg: const Color(0xFFD97706),
          label: 'Último Conteo Guardado',
          value: ultimo == null
              ? 'Sin conteos previos'
              : _fmtFechaCorta(ultimo.fechaConteo),
          subtitle: ultimo == null
              ? null
              : '${ultimo.nombreConteo} · ${ultimo.estado.etiqueta}',
          trailing: ultimo?.id != null
              ? const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8))
              : null,
          onTap: ultimo?.id == null
              ? () => context.push('/inventario-fisico/listar')
              : () => context.push(
                    '/inventario-fisico/capturar/${ultimo!.id}',
                  ),
        ),
      ],
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color iconBg,
    required Color iconFg,
    required String label,
    required String value,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final child = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconFg, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _textMuted,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: _textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: child,
      ),
    );
  }

  // ── Formulario ──
  Widget _columnaFormulario({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFBF1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.edit_note_rounded,
                    color: _teal, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Datos del conteo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _textPrimary,
                      ),
                    ),
                    Text(
                      'Nombre claro para identificar el recuento',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _field(
            controller: _nombreCtrl,
            label: 'Nombre del Conteo',
            icon: Icons.badge_outlined,
            hint: _porLotes
                ? 'Ej. Lotes — zona A'
                : 'Ej. Conteo almacén principal',
          ),
          const SizedBox(height: 14),
          _field(
            controller: _obsCtrl,
            label: 'Observaciones',
            icon: Icons.chat_bubble_outline_rounded,
            hint: 'Notas opcionales',
            maxLines: isMobile ? 2 : 3,
          ),
          if (_porLotes) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Modo por lotes: el nombre se prefijará con [Lotes].',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _cargando ? null : _guardar,
              icon: _cargando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_rounded, size: 22),
              label: Text(
                _cargando ? 'Creando…' : 'Crear Conteo',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _teal.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
            prefixIcon: Icon(icon, size: 20, color: _textMuted),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _teal, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }

  // ── Derecha: guías + stats activos ──
  Widget _columnaDerecha({
    required ConteoFisico? ultimo,
    required int lineasUltimo,
    required int conError,
    required int totalConteos,
    required int abiertos,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Guías Operativas',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _guideItem(
            Icons.lock_outline_rounded,
            '1. Congelar movimientos antes de contar',
            onTap: () {
              FiscoGestNotifications.show(
                const SnackBar(
                  content: Text(
                    'Evite ventas/compras durante el conteo para no alterar el stock.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _guideItem(
            Icons.groups_outlined,
            '2. Asignar contadores por zona',
            onTap: () {
              FiscoGestNotifications.show(
                const SnackBar(
                  content: Text(
                    'Divida el almacén por zonas y asigne un responsable a cada una.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _guideItem(
            Icons.qr_code_scanner_rounded,
            '3. Usar escáner de códigos de barras',
            onTap: () {
              FiscoGestNotifications.show(
                const SnackBar(
                  content: Text(
                    'En la captura puede buscar por código o nombre de producto.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Estadísticas Rápidas',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _statCard(
            icon: Icons.check_circle_outline_rounded,
            label: 'Conteo anterior',
            value: ultimo == null
                ? 'Ninguno'
                : ultimo.estado.etiqueta,
            color: ultimo == null
                ? _textMuted
                : const Color(0xFF16A34A),
            onTap: ultimo?.id == null
                ? () => context.push('/inventario-fisico/listar')
                : () => context.push(
                      '/inventario-fisico/capturar/${ultimo!.id}',
                    ),
          ),
          const SizedBox(height: 8),
          _statCard(
            icon: Icons.inventory_2_outlined,
            label: 'Líneas del último',
            value: lineasUltimo > 0 ? '$lineasUltimo' : '—',
            color: const Color(0xFF2563EB),
            onTap: ultimo?.id == null
                ? null
                : () => context.push(
                      '/diferencias-conteo-fisico/${ultimo!.id}',
                    ),
          ),
          const SizedBox(height: 8),
          _statCard(
            icon: Icons.warning_amber_rounded,
            label: 'Con diferencia',
            value: conError > 0 ? '$conError' : '0',
            color: conError > 0
                ? const Color(0xFFDC2626)
                : const Color(0xFF16A34A),
            onTap: ultimo?.id == null
                ? null
                : () => context.push(
                      '/diferencias-conteo-fisico/${ultimo!.id}',
                    ),
          ),
          const SizedBox(height: 8),
          _statCard(
            icon: Icons.list_alt_rounded,
            label: 'Conteos abiertos',
            value: '$abiertos / $totalConteos',
            color: abiertos > 0 ? const Color(0xFFD97706) : _textMuted,
            onTap: () => context.push('/inventario-fisico/listar'),
          ),
        ],
      ),
    );
  }

  Widget _guideItem(IconData icon, String text, {VoidCallback? onTap}) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: _teal),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right,
                    size: 16, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 16, color: color),
          ],
        ],
      ),
    );
    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: body,
      ),
    );
  }
}
