import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/conteo_fisico.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/estado_conteo.dart';
import 'package:fiscogest_rd/features/inventario_fisico/presentation/providers/inventario_fisico_provider.dart';
import 'package:fiscogest_rd/core/providers/core_providers.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';

class RegistrarConteoPage extends ConsumerStatefulWidget {
  const RegistrarConteoPage({super.key});
  static const routeName = 'registrar-conteo-fisico';

  @override
  ConsumerState<RegistrarConteoPage> createState() =>
      _RegistrarConteoPageState();
}

class _RegistrarConteoPageState extends ConsumerState<RegistrarConteoPage> {
  final _nombreCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      if (mounted) {
        FiscoGestNotifications.show(
          const SnackBar(content: Text('⚠️ Escribe un nombre para el conteo')),
        );
      }
      return;
    }

    // ✅ Validación segura SIN operador !
    final idUsuario = ref.read(usuarioAutenticadoProvider);
    if (idUsuario == null) {
      if (mounted) {
        FiscoGestNotifications.show(
          const SnackBar(content: Text('⚠️ No hay sesión activa')),
        );
      }
      return;
    }

    setState(() => _cargando = true);
    try {
      final conteo = ConteoFisico(
        nombreConteo: nombre,
        fechaConteo: DateTime.now(),
        observaciones: _obsCtrl.text.trim(),
        usuarioId: idUsuario,
        fechaCreacion: DateTime.now(),
        estado: EstadoConteo.pendiente,
      );
      final id = await ref.read(registrarConteoProvider).call(conteo);
      if (!mounted) return;
      FiscoGestNotifications.show(
        const SnackBar(content: Text('✅ Conteo creado exitosamente')),
      );
      ref.invalidate(listaConteosProvider);
      context.go('/inventario-fisico/capturar/$id');
    } catch (e) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);

    return AppScaffold(
      title: 'Nuevo Conteo Físico',
      subtitle: isMobile ? null : 'Apertura de sesión de inventario físico',
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 24,
              isMobile ? 20 : 40,
              isMobile ? 16 : 24,
              24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.grey900.withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Datos del conteo',
                      style: AppTypography.h4.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Defina un nombre claro para identificar el recuento.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppTextField(
                      controller: _nombreCtrl,
                      label: 'Nombre del Conteo',
                      hint: 'Ej: Muebles, Oficina, Almacén...',
                    ),
                    const SizedBox(height: AppSpacing.m),
                    AppTextField(
                      controller: _obsCtrl,
                      label: 'Observaciones',
                      hint: 'Notas adicionales (opcional)',
                    ),
                    const SizedBox(height: 28),
                    Align(
                      alignment: isMobile
                          ? Alignment.center
                          : Alignment.centerRight,
                      child: SizedBox(
                        width: isMobile ? double.infinity : 200,
                        child: AppButton(
                          text: 'Crear Conteo',
                          onPressed: _cargando ? null : _guardar,
                          isLoading: _cargando,
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
