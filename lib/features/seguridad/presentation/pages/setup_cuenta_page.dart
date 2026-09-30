import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/features/seguridad/data/auth_service.dart';

/// Obligatorio tras primer login con admin/admin.
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
    if (sesion == null) {
      context.go('/login');
      return;
    }
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
      final err = await AuthService(db).completarSetupInicial(
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
      if (!mounted) return;
      final s = ref.read(sesionProvider);
      context.go(s?.rutaInicio ?? '/');
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.security_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Configure su cuenta',
                      textAlign: TextAlign.center,
                      style: AppTypography.h3.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Por seguridad debe cambiar el usuario y la contraseña '
                      'de fábrica (admin). También configure una pregunta para '
                      'recuperar la clave si la olvida.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _userCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nuevo usuario *',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passCtrl,
                      obscureText: _ocultar,
                      decoration: InputDecoration(
                        labelText: 'Nueva contraseña *',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _ocultar
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() => _ocultar = !_ocultar),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pass2Ctrl,
                      obscureText: _ocultar,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar contraseña *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Recuperación de clave',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Pregunta *',
                        border: OutlineInputBorder(),
                      ),
                      items: _preguntas
                          .map(
                            (p) => DropdownMenuItem(
                              value: p,
                              child: Text(
                                p,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) _preguntaCtrl.text = v;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _respuestaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Respuesta *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _cargando ? null : _guardar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _cargando
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'GUARDAR Y CONTINUAR',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
