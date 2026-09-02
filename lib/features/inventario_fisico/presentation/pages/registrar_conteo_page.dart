import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/conteo_fisico.dart';
import 'package:fiscogest_rd/features/inventario_fisico/presentation/providers/inventario_fisico_provider.dart';
import 'package:fiscogest_rd/core/providers/core_providers.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Escribe un nombre para el conteo')),
        );
      }
      return;
    }

    // ✅ Validación segura SIN operador !
    final idUsuario = ref.read(usuarioAutenticadoProvider);
    if (idUsuario == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
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
      await ref.read(registrarConteoProvider).call(conteo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Conteo creado exitosamente')),
      );
      context.goNamed('inventario_fisico');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Nuevo Conteo Físico', // ✅ Recibe String?
      padding: AppSpacing.allL,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
            // ✅ SIN maxLines: no existe en este componente
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            text: 'Crear Conteo', // ✅ Parámetro obligatorio String
            onPressed: _cargando ? null : _guardar,
            isLoading: _cargando, // ✅ Parámetro real para estado de carga
          ),
        ],
      ),
    );
  }
}
