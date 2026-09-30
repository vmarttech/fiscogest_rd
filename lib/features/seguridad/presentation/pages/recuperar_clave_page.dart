import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
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
      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_paso2) ...[
                  TextField(
                    controller: _userCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Usuario',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _cargando ? null : _buscar,
                    child: const Text('Continuar'),
                  ),
                ] else ...[
                  Text(
                    _pregunta ?? '',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _respCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Respuesta',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nueva contraseña',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pass2Ctrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar contraseña',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _cargando ? null : _recuperar,
                    child: const Text('Guardar nueva contraseña'),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
