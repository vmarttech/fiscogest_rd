import 'package:fiscogest_rd/core/ui/fisco_aurora_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/features/seguridad/data/auth_service.dart';
import 'package:fiscogest_rd/core/sync/supabase/negocio_local.dart';
import 'package:fiscogest_rd/core/sync/supabase/negocio_remote.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';

/// Configuración de la cuenta al iniciar por primera vez.
class SetupCuentaPage extends ConsumerStatefulWidget {
  const SetupCuentaPage({super.key});

  static const routeName = 'setup-cuenta';
  static const path = '/setup-cuenta';

  @override
  ConsumerState<SetupCuentaPage> createState() => _SetupCuentaPageState();
}

class _SetupCuentaPageState extends ConsumerState<SetupCuentaPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  final _preguntaCtrl = TextEditingController();
  final _respuestaCtrl = TextEditingController();
  bool _cargando = false;
  bool _ocultar = true;
  String? _error;

  static const _preguntas = [
    '¿Nombre de su primer negocio?',
    '¿Ciudad donde nació?',
    '¿Nombre de su madre?',
    '¿Mascota favorita?',
  ];

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    _preguntaCtrl.dispose();
    _respuestaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final sesion = ref.read(sesionProvider);
    if (_passCtrl.text != _pass2Ctrl.text) {
      setState(() => _error = 'Las contraseñas no coinciden');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final db = ref.read(databaseProvider);
      final auth = AuthService(db);
      final esInvitado = sesion == null ||
          sesion.id == 0 ||
          sesion.username.toLowerCase() == 'invitado';
      if (esInvitado) {
        // 1) Negocio propio en Supabase (no compartir idPrueba)
        if (SupabaseConfig.isConfigured) {
          final nombreNegocio = _userCtrl.text.trim().isEmpty
              ? 'Mi negocio'
              : 'Negocio ${_userCtrl.text.trim()}';
          final negocioId = await NegocioRemote().crear(nombre: nombreNegocio);
          await NegocioLocal.setId(negocioId);
        }
        final cuenta = await auth.crearCuentaInicial(
          username: _userCtrl.text,
          password: _passCtrl.text,
          pregunta: _preguntaCtrl.text,
          respuesta: _respuestaCtrl.text,
        );
        ref.read(sesionProvider.notifier).state = UsuarioSesion(
          id: cuenta.usuarioId,
          username: cuenta.username,
          nombre: cuenta.nombre,
          rol: cuenta.rol,
          requiereSetupInicial: false,
        );
      } else {
        final err = await auth.completarSetupInicial(
          usuarioId: sesion.id,
          nuevoUsername: _userCtrl.text,
          nuevaPassword: _passCtrl.text,
          pregunta: _preguntaCtrl.text,
          respuesta: _respuestaCtrl.text,
        );
        if (err != null) {
          setState(() => _error = err);
          return;
        }
        ref.read(sesionProvider.notifier).state = UsuarioSesion(
          id: sesion.id,
          username: _userCtrl.text.trim(),
          nombre: sesion.nombre,
          rol: sesion.rol,
          requiereSetupInicial: false,
        );
      }
      if (!mounted) return;
      final s = ref.read(sesionProvider);
      context.go(s?.rutaInicio ?? '/');
    } catch (e) {
      setState(
        () => _error = e is FormatException
            ? e.message
            : 'No se pudo guardar la cuenta',
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF070B12),
        body: FiscoAuroraBackground(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _glass(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.security_rounded,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.96),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Configure su cuenta',
                          textAlign: TextAlign.center,
                          style: AppTypography.h3.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withValues(alpha: 0.96),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cree el usuario y la contraseña de su cuenta. Configure '
                          'una pregunta de seguridad para recuperar el acceso si '
                          'alguna vez olvida la clave.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.55),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _userCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: _dec('Usuario *'),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passCtrl,
                          obscureText: _ocultar,
                          style: const TextStyle(color: Colors.white),
                          decoration: _dec(
                            'Contraseña *',
                            suffix: IconButton(
                              icon: Icon(
                                _ocultar
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.white54,
                              ),
                              onPressed: () =>
                                  setState(() => _ocultar = !_ocultar),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _pass2Ctrl,
                          obscureText: _ocultar,
                          style: const TextStyle(color: Colors.white),
                          decoration: _dec('Confirmar contraseña *'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          selectedItemBuilder: (context) => [
                            for (final q in _preguntas)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  q,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                          ],
                          initialValue:
                              _preguntaCtrl.text.isNotEmpty &&
                                  _preguntas.contains(_preguntaCtrl.text)
                              ? _preguntaCtrl.text
                              : null,
                          dropdownColor: const Color(0xFF0F172A),
                          style: const TextStyle(color: Colors.white),
                          decoration: _dec('Pregunta de seguridad *'),
                          items: [
                            for (final q in _preguntas)
                              DropdownMenuItem(
                                value: q,
                                child: Text(q, overflow: TextOverflow.ellipsis),
                              ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              _preguntaCtrl.text = v;
                              setState(() {});
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _respuestaCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: _dec('Respuesta *'),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(
                              color: const Color(0xFFF87171),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        FilledButton(
                          onPressed: _cargando ? null : _guardar,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF14B8A6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            _cargando ? 'Guardando…' : 'Guardar y continuar',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _glass({required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _dec(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
      suffixIcon: suffix,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2DD4BF)),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
