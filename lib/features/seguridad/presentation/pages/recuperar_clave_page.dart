import 'package:fiscogest_rd/core/ui/fisco_aurora_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/features/seguridad/data/auth_service.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';

class RecuperarClavePage extends ConsumerStatefulWidget {
  const RecuperarClavePage({super.key});

  static const routeName = 'recuperar-clave';
  static const path = '/recuperar-clave';

  @override
  ConsumerState<RecuperarClavePage> createState() => _RecuperarClavePageState();
}

class _RecuperarClavePageState extends ConsumerState<RecuperarClavePage> {
  final _userCtrl = TextEditingController();
  final _respCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  String? _pregunta;
  bool _paso2 = false;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _userCtrl.dispose();
    _respCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final db = ref.read(databaseProvider);
      final row = await AuthService(db).buscarPorUsername(_userCtrl.text);
      if (row == null) {
        setState(() => _error = 'Usuario no encontrado');
        return;
      }
      if ((row.preguntaRecuperacion ?? '').isEmpty) {
        setState(
          () => _error = 'No hay pregunta de recuperación en esta cuenta',
        );
        return;
      }
      setState(() {
        _pregunta = row.preguntaRecuperacion;
        _paso2 = true;
      });
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _recuperar() async {
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
      final err = await AuthService(db).recuperarClave(
        username: _userCtrl.text,
        respuesta: _respCtrl.text,
        nuevaPassword: _passCtrl.text,
      );
      if (err != null) {
        setState(() => _error = err);
        return;
      }
      if (!mounted) return;
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('Contraseña actualizada. Inicie sesión.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/login');
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Recuperar contraseña'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: FiscoAuroraBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
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
                      if (!_paso2) ...[
                        Text(
                          'Ingrese su usuario',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyLarge.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _userCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: _dec('Usuario'),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _cargando ? null : _buscar,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF14B8A6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(_cargando ? '…' : 'Continuar'),
                        ),
                      ] else ...[
                        Text(
                          _pregunta ?? '',
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _respCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: _dec('Respuesta'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passCtrl,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: _dec('Nueva contraseña'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _pass2Ctrl,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: _dec('Confirmar contraseña'),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _cargando ? null : _recuperar,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF14B8A6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(_cargando ? '…' : 'Restablecer clave'),
                        ),
                      ],
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
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
