import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';

class FiscoSplashPage extends ConsumerStatefulWidget {
  const FiscoSplashPage({
    super.key,
    this.minDuration = const Duration(milliseconds: 1500),
  });

  final Duration minDuration;
  static const routeName = 'splash';

  @override
  ConsumerState<FiscoSplashPage> createState() => _FiscoSplashPageState();
}

class _FiscoSplashPageState extends ConsumerState<FiscoSplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _scale = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
    Future<void>.delayed(widget.minDuration, () async {
      if (!mounted) return;
      final db = ref.read(databaseProvider);
      final usuarios = await db.select(db.usuariosTable).get();
      if (!mounted) return;
      if (usuarios.isEmpty) {
        ref.read(sesionProvider.notifier).state = const UsuarioSesion(
          id: 0,
          username: 'invitado',
          nombre: 'Modo prueba',
          rol: 'Admin',
          requiereSetupInicial: false,
        );
        // ignore: avoid_print
        print('FISCO_SPLASH: invitado → /');
        context.go('/');
      } else {
        // ignore: avoid_print
        print('FISCO_SPLASH: hay usuarios → /login');
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B12),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF070B12), Color(0xFF0C1A18), Color(0xFF08141F)],
          ),
        ),
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2DD4BF,
                            ).withValues(alpha: 0.28),
                            blurRadius: 32,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/branding/app_icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF0F172A),
                          alignment: Alignment.center,
                          child: const Text(
                            'FG',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 30,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'FiscoGest',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.9,
                        color: Colors.white.withValues(alpha: 0.96),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tu negocio, en orden',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.35,
                        color: const Color(0xFF5EEAD4).withValues(alpha: 0.92),
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
