// [CAMPANAS_FASE1] Formulario de creación de campaña (dueño de plataforma).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/core/ui/enterprise_page_header.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/features/campanas/presentation/providers/campanas_providers.dart';
import 'package:fiscogest_rd/features/campanas/data/campana_oferta_notifier.dart';

class AdminCampanaFormPage extends ConsumerStatefulWidget {
  const AdminCampanaFormPage({super.key});
  static const routeName = 'admin-campana-form';

  @override
  ConsumerState<AdminCampanaFormPage> createState() => _FormState();
}

class _FormState extends ConsumerState<AdminCampanaFormPage> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();
  final _valor = TextEditingController();
  final _limite = TextEditingController();

  String _tipo = 'descuento';
  String _segmento = 'todos';
  String _plan = 'gratis';
  DateTime _inicio = DateTime.now();
  DateTime _fin = DateTime.now().add(const Duration(days: 30));
  bool _mostrarRegistro = true;
  bool _mostrarPanel = true;
  bool _guardando = false;

  static const _tipos = [
    ('descuento', 'Descuento'),
    ('meses_gratis', 'Meses gratis'),
    ('cuentas_gratis', 'Cuentas gratis'),
    ('personalizado', 'Personalizado'),
  ];
  static const _segmentos = [
    ('todos', 'Todos los negocios'),
    ('negocios_activos', 'Negocios activos'),
    ('plan_especifico', 'Un plan específico'),
    ('nuevas_cuentas', 'Nuevas cuentas (al registrarse)'),
  ];
  static const _planes = [
    'demo',
    'gratis',
    'basico',
    'simplificado',
    'pro',
    'profesional',
    'empresa',
  ];

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    _valor.dispose();
    _limite.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha({required bool esInicio}) async {
    final f = await showDatePicker(
      context: context,
      initialDate: esInicio ? _inicio : _fin,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
    );
    if (f == null) return;
    setState(() {
      if (esInicio) {
        _inicio = f;
        if (_fin.isBefore(_inicio)) _fin = _inicio.add(const Duration(days: 1));
      } else {
        _fin = f;
      }
    });
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    if (!_fin.isAfter(_inicio)) {
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('La fecha de fin debe ser posterior al inicio'),
        ),
      );
      return;
    }
    setState(() => _guardando = true);
    try {
      await ref
          .read(campanasRemoteProvider)
          .crear(
            nombre: _nombre.text.trim(),
            descripcion: _descripcion.text.trim(),
            tipo: _tipo,
            valor: _valor.text.trim(),
            segmento: _segmento,
            planAplicar: _segmento == 'plan_especifico' ? _plan : null,
            inicio: _inicio,
            fin: _fin,
            limiteUsos: _limite.text.trim().isEmpty
                ? null
                : int.tryParse(_limite.text.trim()),
            mostrarRegistro: _mostrarRegistro,
            mostrarPanel: _mostrarPanel,
          );
      ref.read(campanasTickProvider.notifier).state++;
      try {
        await CampanaOfertaNotifier.anunciarCreacion(
          nombre: _nombre.text.trim(),
          descripcion: _descripcion.text.trim(),
          tipo: _tipo,
          valor: _valor.text.trim(),
          segmento: _segmento,
          planAplicar: _segmento == 'plan_especifico' ? _plan : null,
        );
      } catch (_) {}
      if (mounted) {
        FiscoGestNotifications.show(
          const SnackBar(content: Text('Campaña creada')),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/admin/campanas');
        }
      }
    } catch (e) {
      if (mounted) {
        FiscoGestNotifications.show(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);
    return AppScaffold(
      title: 'Nueva campaña / oferta',
      showAppBar: !desktop,
      contentMaxWidth: 900,
      body: Form(
        key: _form,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            mobile ? 16 : 28,
            20,
            mobile ? 16 : 28,
            40,
          ),
          children: [
            const EnterprisePageHeader(
              title: 'Nueva campaña / oferta',
              subtitle: 'Configura el beneficio, el público y su vigencia.',
              showBack: true,
              backFallbackRoute: '/admin/campanas',
            ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _tituloSeccion(Icons.card_giftcard_outlined, 'Beneficio'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nombre,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la oferta',
                      hintText: 'Ej. Black Friday 50%',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Falta el nombre'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descripcion,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (visible para el negocio)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _tipo,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de beneficio',
                    ),
                    items: [
                      for (final t in _tipos)
                        DropdownMenuItem(value: t.$1, child: Text(t.$2)),
                    ],
                    onChanged: (v) => setState(() => _tipo = v ?? _tipo),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _valor,
                    decoration: const InputDecoration(
                      labelText: 'Valor del beneficio',
                      hintText: 'Ej. 50%, 3 meses, 2 cuentas',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Falta el valor'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _tituloSeccion(Icons.groups_outlined, 'Público y vigencia'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _segmento,
                    decoration: const InputDecoration(
                      labelText: '¿A quién va dirigida?',
                    ),
                    items: [
                      for (final s in _segmentos)
                        DropdownMenuItem(value: s.$1, child: Text(s.$2)),
                    ],
                    onChanged: (v) =>
                        setState(() => _segmento = v ?? _segmento),
                  ),
                  if (_segmento == 'plan_especifico') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _plan,
                      decoration: const InputDecoration(
                        labelText: 'Plan destino',
                      ),
                      items: [
                        for (final p in _planes)
                          DropdownMenuItem(value: p, child: Text(p)),
                      ],
                      onChanged: (v) => setState(() => _plan = v ?? _plan),
                    ),
                  ],
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: Text('Inicio: ${_fechaTxt(_inicio)}'),
                    onTap: () => _elegirFecha(esInicio: true),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_busy_outlined),
                    title: Text('Fin: ${_fechaTxt(_fin)}'),
                    onTap: () => _elegirFecha(esInicio: false),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _limite,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Límite de usos (vacío = sin límite)',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _tituloSeccion(Icons.visibility_outlined, 'Visibilidad'),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Mostrar en el registro de nuevas cuentas',
                    ),
                    value: _mostrarRegistro,
                    onChanged: (v) => setState(() => _mostrarRegistro = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Mostrar en el panel de ofertas del negocio',
                    ),
                    value: _mostrarPanel,
                    onChanged: (v) => setState(() => _mostrarPanel = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : const Icon(Icons.send_outlined),
              label: Text(_guardando ? 'Guardando...' : 'Publicar campaña'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tituloSeccion(IconData icon, String titulo) => Row(
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 10),
      Text(
        titulo,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
    ],
  );
}

String _fechaTxt(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
