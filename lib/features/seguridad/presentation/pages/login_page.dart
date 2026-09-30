import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';
import 'package:fiscogest_rd/core/auth/permisos_roles.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
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
      final res = await AuthService(db).login(_userCtrl.text, _passCtrl.text);
      if (res == null) {
        setState(() => _error = 'Usuario o contraseña incorrectos');
        return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.12),
              AppColors.grey50,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.grey900.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'FiscoGest RD',
                      textAlign: TextAlign.center,
                      style: AppTypography.h3.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Iniciar sesión',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
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
                      hint: 'admin',
                      obscureText: _ocultar,
                      prefixIcon: Icons.lock_outline,
                    ),
                    TextButton(
                      onPressed: () => setState(() => _ocultar = !_ocultar),
                      child: Text(_ocultar ? 'Mostrar contraseña' : 'Ocultar'),
                    ),

                    TextButton(
                      onPressed: () => context.push('/recuperar-clave'),
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    AppButton(
                      text: 'Entrar',
                      onPressed: _cargando ? null : _entrar,
                      isLoading: _cargando,
                    ),
                    const SizedBox(height: 12),
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
