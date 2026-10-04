import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';
import 'package:fiscogest_rd/core/auth/permisos_roles.dart';
import 'package:fiscogest_rd/core/auth/login_prefs.dart';
import 'package:fiscogest_rd/core/auth/biometric_auth.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/fisco_aurora_background.dart';
import 'package:fiscogest_rd/features/seguridad/data/auth_service.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  static const routeName = 'login';

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _cargando = false;
  bool _ocultar = true;
  bool _rememberMe = false;
  bool _bioAvailable = false;
  bool _bioEnabled = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final db = ref.read(databaseProvider);
        await AuthService(db).ensureAdminSeed();
      } catch (e) {
        debugPrint('Seed admin: $e');
      }
      await _cargarPrefs();
    });
  }

  Future<void> _cargarPrefs() async {
    final user = await LoginPrefs.getRememberedUser();
    final remember = await LoginPrefs.getRememberMe();
    final bioEn = await LoginPrefs.isBiometricEnabled();
    final bioAv = await BiometricAuth.isAvailable();
    if (!mounted) return;
    setState(() {
      _rememberMe = remember;
      _bioEnabled = bioEn;
      _bioAvailable = bioAv;
      if (user != null && user.isNotEmpty) {
        _userCtrl.text = user;
      }
    });
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final db = ref.read(databaseProvider);
      final user = _userCtrl.text.trim();
      final pass = _passCtrl.text;
      final res = await AuthService(db).login(user, pass);
      if (res == null) {
        setState(() => _error = 'Usuario o contraseña incorrectos');
        return;
      }

      await LoginPrefs.setRememberMe(_rememberMe, user);

      if (_bioAvailable && !await LoginPrefs.isBiometricEnabled()) {
        if (!mounted) return;
        final activar = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Desbloqueo rápido'),
            content: const Text(
              '¿Activar huella, rostro o PIN del dispositivo '
              'para entrar la próxima vez sin escribir la clave?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Ahora no'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Activar'),
              ),
            ],
          ),
        );
        if (activar == true) {
          final ok = await BiometricAuth.authenticate(
            reason: 'Confirme para activar el desbloqueo rápido',
          );
          if (ok) {
            await LoginPrefs.enableBiometric(username: user, password: pass);
            if (mounted) setState(() => _bioEnabled = true);
          }
        }
      } else if (await LoginPrefs.isBiometricEnabled()) {
        await LoginPrefs.enableBiometric(username: user, password: pass);
      }

      ref.read(sesionProvider.notifier).state = UsuarioSesion(
        id: res.usuarioId,
        username: res.username,
        nombre: res.nombre,
        rol: res.rol,
        requiereSetupInicial: res.requiereSetupInicial,
      );
      if (!mounted) return;
      if (res.requiereSetupInicial) {
        context.go('/setup-cuenta');
      } else {
        final sesion = ref.read(sesionProvider);
        if (sesion != null && normalizarRol(sesion.rol) == 'Cajero') {
          context.go('/ventas/cobro');
        } else {
          context.go(sesion?.rutaInicio ?? '/');
        }
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _entrarConBiometria() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final ok = await BiometricAuth.authenticate();
      if (!ok) {
        setState(() => _error = 'No se pudo verificar la identidad');
        return;
      }
      final cred = await LoginPrefs.readBiometricCredentials();
      if (cred == null) {
        setState(
          () => _error =
              'Active el desbloqueo rápido entrando una vez con su clave',
        );
        return;
      }
      final db = ref.read(databaseProvider);
      final res = await AuthService(db).login(cred.user, cred.pass);
      if (res == null) {
        await LoginPrefs.disableBiometric();
        setState(() {
          _bioEnabled = false;
          _error = 'Clave guardada inválida. Entre con su clave de nuevo.';
        });
        return;
      }
      _userCtrl.text = cred.user;
      await LoginPrefs.setRememberMe(true, cred.user);
      ref.read(sesionProvider.notifier).state = UsuarioSesion(
        id: res.usuarioId,
        username: res.username,
        nombre: res.nombre,
        rol: res.rol,
        requiereSetupInicial: res.requiereSetupInicial,
      );
      if (!mounted) return;
      if (res.requiereSetupInicial) {
        context.go('/setup-cuenta');
      } else {
        final sesion = ref.read(sesionProvider);
        if (sesion != null && normalizarRol(sesion.rol) == 'Cajero') {
          context.go('/ventas/cobro');
        } else {
          context.go(sesion?.rutaInicio ?? '/');
        }
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B12),
      body: FiscoAuroraBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    brightness: Brightness.dark,
                    textTheme: Theme.of(context).textTheme.apply(
                          bodyColor: Colors.white,
                          displayColor: Colors.white,
                        ),
                    inputDecorationTheme: InputDecorationTheme(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      labelStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                      prefixIconColor: Colors.white.withValues(alpha: 0.65),
                      suffixIconColor: Colors.white.withValues(alpha: 0.65),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2DD4BF)),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'FiscoGest',
                          textAlign: TextAlign.center,
                          style: AppTypography.h3.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withValues(alpha: 0.96),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tu negocio, en orden',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color:
                                const Color(0xFF5EEAD4).withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Iniciar sesión',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(height: 28),
                        AppTextField(
                          controller: _userCtrl,
                          label: 'Usuario',
                          hint: 'admin',
                          prefixIcon: Icons.person_outline,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: _passCtrl,
                          label: 'Contraseña',
                          hint: '••••••••',
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: _ocultar
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          obscureText: _ocultar,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () =>
                                setState(() => _ocultar = !_ocultar),
                            child: Text(
                              _ocultar ? 'Mostrar' : 'Ocultar',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          value: _rememberMe,
                          onChanged: _cargando
                              ? null
                              : (v) =>
                                  setState(() => _rememberMe = v ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: const Color(0xFF2DD4BF),
                          title: Text(
                            'Recordar usuario',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(
                              color: const Color(0xFFF87171),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        AppButton(
                          text: _cargando ? 'Entrando…' : 'Entrar',
                          onPressed: _cargando ? null : _entrar,
                        ),
                        if (_bioEnabled && _bioAvailable) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed:
                                _cargando ? null : _entrarConBiometria,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF5EEAD4),
                              side: BorderSide(
                                color: const Color(0xFF5EEAD4)
                                    .withValues(alpha: 0.5),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.fingerprint, size: 22),
                            label: const Text('Entrar con huella / PIN'),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => context.push('/recuperar-clave'),
                          child: Text(
                            '¿Olvidaste tu clave?',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
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
        ),
      ),
    );
  }
}
