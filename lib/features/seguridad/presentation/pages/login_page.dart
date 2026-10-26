import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/sync/supabase/emitir_token.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';
import 'package:fiscogest_rd/core/auth/permisos_roles.dart';
import 'package:fiscogest_rd/core/auth/login_prefs.dart';
import 'package:fiscogest_rd/core/auth/biometric_auth.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/fisco_aurora_background.dart';
import 'package:fiscogest_rd/features/seguridad/data/auth_service.dart';
import 'package:fiscogest_rd/core/sync/supabase/sync_pull.dart';
import 'package:fiscogest_rd/core/sync/supabase/producto_sync.dart';
import 'package:fiscogest_rd/core/sync/supabase/sync_engine.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_rest_client.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';
import 'package:fiscogest_rd/features/licencias/domain/licencia_service.dart';
import 'package:fiscogest_rd/features/licencias/presentation/providers/licencia_providers.dart';
import 'package:fiscogest_rd/core/auth/dueno_plataforma.dart';
import 'package:fiscogest_rd/core/sync/supabase/negocio_local.dart';

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


  Widget _pieLegal(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          TextButton(
            onPressed: () => context.push('/legal/privacidad'),
            child: const Text('Privacidad'),
          ),
          const Text('·', style: AppTypography.bodySmall),
          TextButton(
            onPressed: () => context.push('/legal/terminos'),
            child: const Text('Términos'),
          ),
        ],
      ),
    );
  }

  
  /// Dueño plataforma: licencia vitalicia local + aviso de pedidos pendientes en nube.
  Future<void> _postLoginPlataforma(AppDatabase db, String username) async {
    if (esDuenoPlataforma(username)) {
      try {
        await LicenciaService(db).activarDesarrolladorVitalicio();
        debugPrint('Login: licencia desarrollador vitalicia OK ($username)');
      } catch (e, st) {
        debugPrint('Login: vitalicio dev $e');
        debugPrint('$st');
      }
    }
    if (!esDuenoPlataforma(username) || !SupabaseConfig.isConfigured) return;
    if (!await SupabaseConfig.hayRed()) return;
    try {
      final rows = await SupabaseRestClient().select(
        table: 'pedidos_licencia',
        filters: {
          'estado': 'in.(pendiente_pago,pago_reportado)',
          'select': 'id,referencia,estado,plan,monto',
          'order': 'created_at.desc',
        },
      );
      // PostgREST in. filter may need different syntax - fallback two queries if empty issues
      debugPrint('Login: pedidos pendientes (filtro): ${rows.length}');
      if (rows.isNotEmpty && mounted) {
        final n = rows.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              n == 1
                  ? 'Hay 1 pedido de licencia pendiente de revisar'
                  : 'Hay $n pedidos de licencia pendientes de revisar',
            ),
            action: SnackBarAction(
              label: 'Ver',
              onPressed: () {
                if (mounted) context.push('/licencia/admin');
              },
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('Login: aviso pedidos $e');
      debugPrint('$st');
    }
  }


  /// Nube en segundo plano: nunca retrasa la entrada a la caja.
  Future<void> _nubeTrasEntrar(
    AppDatabase db, {
    required String username,
    required String password,
    required bool requiereSetup,
    required String usernameSesion,
  }) async {
    if (!await SupabaseConfig.hayRed()) {
      debugPrint('Login: sin red → skip nube');
      return;
    }
    await EmitirToken.trasLogin(username: username, password: password);
    // 1) Bajar licencia + datos ANTES de subir (evitar pisar nube con demo local)
    if (!requiereSetup) {
      try {
        await SyncPull(db).pullTodoElNegocio();
        if (esDuenoPlataforma(usernameSesion)) {
          try {
            await LicenciaService(db).activarDesarrolladorVitalicio();
          } catch (e) {
            debugPrint('Login: vitalicio post-nube $e');
          }
        }
        if (mounted) ref.invalidate(licenciaActualProvider);
      } catch (e, st) {
        debugPrint('Pull post-login: $e');
        debugPrint('$st');
      }
    }
    try {
      await SyncEngine(db).pushAll();
    } catch (e, st) {
      debugPrint('Push post-login: $e');
      debugPrint('$st');
    }
    if (!requiereSetup) {
      try {
        await ProductoSync(db).pushTodos();
      } catch (e, st) {
        debugPrint('Push productos post-login: $e');
        debugPrint('$st');
      }
    }
    if (!mounted) return;
    if (!mounted) return;
    await _postLoginPlataforma(db, usernameSesion);
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
      var res = await AuthService(db).login(user, pass);
      // Equipo nuevo / BD vacía: recuperar cuenta desde la nube (cualquier usuario)
      if (res == null) {
        if (await SupabaseConfig.hayRed()) {
          try {
            debugPrint('Login: local falló → recuperar desde nube');
            await EmitirToken.trasLogin(username: user, password: pass);
            final nid = await NegocioLocal.getId();
            if (nid != null && nid.isNotEmpty) {
              // Primero bajar usuarios y datos; no push con BD vacía
              await SyncPull(db).pullTodoElNegocio();
              if (esDuenoPlataforma(user)) {
                try {
                  await LicenciaService(db).activarDesarrolladorVitalicio();
                } catch (e) {
                  debugPrint('Login: vitalicio post-pull $e');
                }
              }
              ref.invalidate(licenciaActualProvider);
              res = await AuthService(db).login(user, pass);
              if (res == null) {
                debugPrint(
                  'Login: pull OK pero login local falló (hash/usuario)',
                );
              }
            } else {
              debugPrint('Login: nube no devolvió negocio_id (credenciales o sin fila)');
            }
          } catch (e, st) {
            debugPrint('Login: recuperar nube: $e');
            debugPrint('$st');
          }
        } else {
          debugPrint('Login: sin red y sin usuario local');
          if (mounted) {
            setState(() {
              _error =
                  'Sin datos en este equipo y sin internet. '
                  'Conéctate para recuperar tu cuenta.';
              _cargando = false;
            });
            return;
          }
        }
      }
      if (res == null) {
        setState(
          () => _error =
              'Usuario o contraseña incorrectos, '
              'o la cuenta aún no está respaldada en la nube.',
        );
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

      // Dueño plataforma: licencia YA, no esperar el unawaited de nube
      if (esDuenoPlataforma(res.username)) {
        try {
          await LicenciaService(db).activarDesarrolladorVitalicio();
          debugPrint('Login: desarrollador vitalicio listo (${res.username})');
        } catch (e, st) {
          debugPrint('Login: vitalicio $e\n$st');
        }
      }
      ref.read(sesionProvider.notifier).state = UsuarioSesion(
        id: res.usuarioId,
        username: res.username,
        nombre: res.nombre,
        rol: res.rol,
        requiereSetupInicial: res.requiereSetupInicial,
      );
      if (!mounted) return;
      unawaited(_nubeTrasEntrar(
        db,
        username: user,
        password: pass,
        requiereSetup: res.requiereSetupInicial,
        usernameSesion: res.username,
      ));
      if (!mounted) return;
      if (res.requiereSetupInicial) {
        context.go('/setup-cuenta');
      } else {
        final sesion = ref.read(sesionProvider);
        if (sesion != null && normalizarRol(sesion.rol) == 'Cajero') {
          context.go(
            AppBreakpoints.isMobile(context)
                ? '/ventas/cotizaciones/nueva'
                : '/ventas/cobro',
          );
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
      unawaited(_nubeTrasEntrar(
        db,
        username: cred.user,
        password: cred.pass,
        requiereSetup: res.requiereSetupInicial,
        usernameSesion: res.username,
      ));
      if (!mounted) return;
      if (res.requiereSetupInicial) {
        context.go('/setup-cuenta');
      } else {
        final sesion = ref.read(sesionProvider);
        if (sesion != null && normalizarRol(sesion.rol) == 'Cajero') {
          context.go(
            AppBreakpoints.isMobile(context)
                ? '/ventas/cotizaciones/nueva'
                : '/ventas/cobro',
          );
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
                            color: const Color(
                              0xFF5EEAD4,
                            ).withValues(alpha: 0.9),
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
                          hint: 'Ingrese su usuario',
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
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
                              : (v) => setState(() => _rememberMe = v ?? false),
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
                            onPressed: _cargando ? null : _entrarConBiometria,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF5EEAD4),
                              side: BorderSide(
                                color: const Color(
                                  0xFF5EEAD4,
                                ).withValues(alpha: 0.5),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
                        _pieLegal(context),
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
