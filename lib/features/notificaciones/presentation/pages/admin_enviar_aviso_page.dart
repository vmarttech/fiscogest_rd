// [AVISOS_FASE1] Pantalla de plataforma para enviar avisos/ofertas por segmento.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/enterprise_page_header.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/features/notificaciones/presentation/providers/avisos_provider.dart';
import 'package:fiscogest_rd/core/i18n/servicio_idioma.dart';

class AdminEnviarAvisoPage extends ConsumerStatefulWidget {
  const AdminEnviarAvisoPage({super.key});

  @override
  ConsumerState<AdminEnviarAvisoPage> createState() =>
      _AdminEnviarAvisoPageState();
}

class _AdminEnviarAvisoPageState extends ConsumerState<AdminEnviarAvisoPage> {
  final _form = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _mensaje = TextEditingController();
  final _negocioId = TextEditingController();

  String _tipo = 'informacion';
  String _prioridad = 'normal';
  String _segmento = 'todos';
  String _plan = 'gratis';
  bool _enviando = false;

  static const _tipos = [
    'informacion',
    'vencimiento',
    'oferta',
    'suspension',
    'renovacion',
    'sistema',
  ];
  static const _prioridades = ['baja', 'normal', 'alta', 'urgente'];
  static const _planes = [
    'demo',
    'gratis',
    'basico',
    'simplificado',
    'pro',
    'profesional',
    'empresa',
    'desarrollador',
  ];

  @override
  void dispose() {
    _titulo.dispose();
    _mensaje.dispose();
    _negocioId.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      final n = await ref
          .read(avisosRemoteProvider)
          .enviar(
            tipo: _tipo,
            titulo: _titulo.text.trim(),
            mensaje: _mensaje.text.trim(),
            segmento: _segmento,
            negocioId: _segmento == 'negocio' ? _negocioId.text.trim() : null,
            plan: _segmento == 'plan' ? _plan : null,
            prioridad: _prioridad,
          );
      invalidarAvisos(ref);
      if (mounted) {
        FiscoGestNotifications.show(
          SnackBar(content: Text('Aviso enviado ($n registros aplicados)')),
        );
        // El envío no debe sacar al dueño de la sección desde la que trabaja.
        _form.currentState?.reset();
        _titulo.clear();
        _mensaje.clear();
        _negocioId.clear();
        setState(() {
          _tipo = 'informacion';
          _prioridad = 'normal';
          _segmento = 'todos';
          _plan = 'gratis';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al enviar: $e')));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);
    return AppScaffold(
      title: 'Enviar aviso / oferta',
      showAppBar: !desktop,
      contentMaxWidth: 900,
      body: Form(
        key: _form,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            mobile ? 16 : 28,
            20,
            mobile ? 16 : 28,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const EnterprisePageHeader(
                title: 'Enviar aviso / oferta',
                subtitle: 'Redacta un mensaje y elige a qué negocios llegará.',
                showBack: true,
                backFallbackRoute: '/',
              ),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.groups_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          ServicioIdioma.t(context, 'Destinatarios'),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _tipo,
                      decoration: InputDecoration(
                        labelText: ServicioIdioma.t(context, 'Tipo'),
                      ),
                      items: [
                        for (final t in _tipos)
                          DropdownMenuItem(value: t, child: Text(t)),
                      ],
                      onChanged: (v) => setState(() => _tipo = v ?? _tipo),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _segmento,
                      decoration: InputDecoration(
                        labelText: ServicioIdioma.t(
                          context,
                          'Segmento destino',
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'todos',
                          child: Text('Todos los negocios'),
                        ),
                        DropdownMenuItem(
                          value: 'negocio',
                          child: Text('Un negocio (UUID)'),
                        ),
                        DropdownMenuItem(
                          value: 'plan',
                          child: Text('Todos los de un plan'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _segmento = v ?? _segmento),
                    ),
                    if (_segmento == 'negocio') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _negocioId,
                        decoration: InputDecoration(
                          labelText: ServicioIdioma.t(
                            context,
                            'ID del negocio',
                          ),
                          hintText: 'a0000000-0000-4000-8000-000000000001',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Indica el negocio'
                            : null,
                      ),
                    ],
                    if (_segmento == 'plan') ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _plan,
                        decoration: InputDecoration(
                          labelText: ServicioIdioma.t(context, 'Plan destino'),
                        ),
                        items: [
                          for (final p in _planes)
                            DropdownMenuItem(value: p, child: Text(p)),
                        ],
                        onChanged: (v) => setState(() => _plan = v ?? _plan),
                      ),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _prioridad,
                      decoration: InputDecoration(
                        labelText: ServicioIdioma.t(context, 'Prioridad'),
                      ),
                      items: [
                        for (final p in _prioridades)
                          DropdownMenuItem(value: p, child: Text(p)),
                      ],
                      onChanged: (v) =>
                          setState(() => _prioridad = v ?? _prioridad),
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Icon(
                          Icons.campaign_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          ServicioIdioma.t(context, 'Contenido del aviso'),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titulo,
                      decoration: InputDecoration(
                        labelText: ServicioIdioma.t(context, 'Título'),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Falta el título'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _mensaje,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: ServicioIdioma.t(context, 'Mensaje'),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Falta el mensaje'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: _enviando ? null : _enviar,
                  icon: _enviando
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(_enviando ? 'Enviando...' : 'Enviar aviso'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
