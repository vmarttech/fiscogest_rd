import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';

/// Presentación de arranque (cold start). Sin menú lateral.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  static const String path = '/splash';
  static const String routeName = 'splash';

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
    Future<void>.delayed(const Duration(milliseconds: 700), () async {
      if (!mounted) return;
      try {
        final db = ref.read(databaseProvider);
        final usuarios = await db.select(db.usuariosTable).get();
        // ignore: avoid_print
        print('SPLASH: usuarios locales = ${usuarios.length}');
        if (usuarios.isEmpty) {
          ref.read(sesionProvider.notifier).state = const UsuarioSesion(
            id: 0,
            username: 'invitado',
            nombre: 'Modo prueba',
            rol: 'Admin',
            requiereSetupInicial: false,
          );
          // ignore: avoid_print
          print('SPLASH: sesión invitado → /');
          if (!mounted) return;
          context.go('/');
        } else {
          // ignore: avoid_print
          print('SPLASH: hay usuarios → /login');
          if (!mounted) return;
          context.go('/login');
        }
      } catch (e) {
        // ignore: avoid_print
        // print('SPLASH: error $e');
        // print(st);
        if (!mounted) return;
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.18),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/branding/app_icon.png',
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'FISCOGEST RD',
                      textAlign: TextAlign.center,
                      style: AppTypography.h3.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Comprobantes · Caja · Crédito',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: 140,
                      child: LinearProgressIndicator(
                        backgroundColor: AppColors.white.withValues(
                          alpha: 0.25,
                        ),
                        color: AppColors.white,
                        minHeight: 3,
                        borderRadius: BorderRadius.circular(2),
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
